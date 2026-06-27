#!/usr/bin/env bash
set -euo pipefail

repo="${WORKSPACE_REPO:-/srv/workspace}"
remote="${WORKSPACE_REMOTE:-origin}"
branch="${WORKSPACE_BRANCH:-main}"
lock_file="${repo}/.git/workspace-sync.lock"

cd "$repo"
exec 9>"$lock_file"
flock -n 9 || exit 0

if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
  echo "BLOCKED: unresolved merge conflict" >&2
  exit 2
fi

git add -A
if ! git diff --cached --quiet; then
  git commit -m "autosync: $(hostname) $(date '+%Y-%m-%d %H:%M %z')"
fi

git fetch --prune "$remote" "$branch"
local_head="$(git rev-parse HEAD)"
remote_ref="$remote/$branch"
remote_head="$(git rev-parse "$remote_ref")"

if [[ "$local_head" != "$remote_head" ]]; then
  base="$(git merge-base HEAD "$remote_ref")"
  if [[ "$base" == "$local_head" ]]; then
    git merge --ff-only "$remote_ref"
  elif [[ "$base" != "$remote_head" ]]; then
    git merge --no-edit "$remote_ref" || {
      echo "BLOCKED: merge conflict preserved for manual resolution" >&2
      exit 2
    }
  fi
fi

git push "$remote" "HEAD:$branch"
