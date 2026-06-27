[CmdletBinding()]
param(
    [string]$TaskName = "WORKSPACE Git Sync",
    [int]$IntervalMinutes = 5
)

$ErrorActionPreference = "Stop"
$syncScript = (Resolve-Path (Join-Path $PSScriptRoot "sync-workspace.ps1")).Path
$powerShell = (Get-Command powershell.exe).Source
$action = New-ScheduledTaskAction -Execute $powerShell -Argument "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScript`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 4)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Safely commits, pulls and pushes WORKSPACE through GitHub." -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName
Write-Output "Installed '$TaskName': every $IntervalMinutes minutes."
