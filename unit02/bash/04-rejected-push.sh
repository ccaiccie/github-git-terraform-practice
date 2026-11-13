#!/usr/bin/env bash
# Both sides commit. The colleague pushes first, so your push is rejected. Pull (merge), then push again.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
printf 'Owner: network team (netops@example.com)\n' >> README.md
git commit -q -am "Document repository ownership"
step "git status  (after your local commit)"
git status
cd "$COLLEAGUE"
git pull -q 2>&1
printf 'ntp server 198.51.100.123\n' >> configs/edge-router.cfg
git commit -q -am "Add second NTP server"
step "colleague: git push"
git push 2>&1
cd "$LAPTOP"
step "git push  (expected to be rejected)"
if git push 2>&1; then echo "UNEXPECTED: push was accepted" >&2; exit 1; fi
step "git pull --no-edit"
git pull --no-edit 2>&1
step "git push"
git push 2>&1
step "git log --oneline --graph --decorate --all"
git log --oneline --graph --decorate --all
