[CmdletBinding()]
param(
    [string]$Repository = "",
    [string]$Remote = "origin",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$env:GIT_TERMINAL_PROMPT = "0"
if (-not $Repository) {
    $Repository = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
$syncDir = Join-Path $Repository ".sync"
$logFile = Join-Path $syncDir "sync.log"
$mutex = [Threading.Mutex]::new($false, "Global\WORKSPACE-Git-Sync")
$hasLock = $false

function Write-SyncLog([string]$Message) {
    New-Item -ItemType Directory -Force -Path $syncDir | Out-Null
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
    Add-Content -Encoding UTF8 -Path $logFile -Value "$stamp | $env:COMPUTERNAME | $Message"
}

function Invoke-Git {
    $gitArguments = @($args)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & git -C $Repository @gitArguments 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($exitCode -ne 0) {
        throw "git $($gitArguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return $output
}

try {
    $hasLock = $mutex.WaitOne(0)
    if (-not $hasLock) { exit 0 }

    $unmerged = & git -C $Repository diff --name-only --diff-filter=U
    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect repository conflicts." }
    if ($unmerged) {
        Write-SyncLog "BLOCKED: unresolved merge conflict: $($unmerged -join ', ')"
        exit 2
    }

    Invoke-Git add -A | Out-Null
    & git -C $Repository diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm zzz"
        Invoke-Git commit -m "autosync: $env:COMPUTERNAME $stamp" | Out-Null
        Write-SyncLog "Committed local changes."
    } elseif ($LASTEXITCODE -ne 0) {
        throw "Cannot inspect staged changes."
    }

    Invoke-Git fetch --prune $Remote $Branch | Out-Null
    $local = (Invoke-Git rev-parse HEAD | Select-Object -Last 1).Trim()
    $remoteRef = "$Remote/$Branch"
    $remoteHead = (Invoke-Git rev-parse $remoteRef | Select-Object -Last 1).Trim()

    if ($local -ne $remoteHead) {
        $base = (Invoke-Git merge-base HEAD $remoteRef | Select-Object -Last 1).Trim()
        if ($base -eq $local) {
            Invoke-Git merge --ff-only $remoteRef | Out-Null
            Write-SyncLog "Fast-forwarded from $remoteRef."
        } elseif ($base -ne $remoteHead) {
            $mergeOutput = & git -C $Repository merge --no-edit $remoteRef 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-SyncLog "BLOCKED: merge conflict preserved for manual resolution. $($mergeOutput -join ' ')"
                exit 2
            }
            Write-SyncLog "Merged concurrent non-conflicting changes."
        }
    }

    Invoke-Git push $Remote "HEAD:$Branch" | Out-Null
    Write-SyncLog "OK: synchronized with $Remote/$Branch."
} catch {
    Write-SyncLog "ERROR: $($_.Exception.Message)"
    exit 1
} finally {
    if ($hasLock) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
