#!/usr/bin/env bash
# A colleague clones the shared repository: full history, origin preset, main tracking origin/main.
source "$(dirname "$0")/lab-env.sh"; need_lab
if [[ -e "$COLLEAGUE" ]]; then echo "ERROR: $COLLEAGUE already exists." >&2; exit 1; fi
step "git clone <url>"
git clone "$REMOTE" "$COLLEAGUE" 2>&1
cd "$COLLEAGUE"
lab_identity "Lab Colleague" "colleague@example.com"
step "git remote -v"
git remote -v
step "git branch -vv"
git branch -vv
step "git log --oneline --decorate --all"
git log --oneline --decorate --all
