#!/usr/bin/env bash
# Changes a tracked file, inspects the difference, commits, and adds a .gitignore.
source "$(dirname "$0")/lab-env.sh"; need_lab
# portable edit (works with GNU and BSD tools): add a line after the first NTP server
awk '{print} $0=="ntp server 192.0.2.123"{print "ntp server 198.51.100.123"}' configs/edge-router.cfg > cfg.tmp && mv cfg.tmp configs/edge-router.cfg
step "git diff (what changed but is not staged yet)"
git --no-pager diff
git add configs/edge-router.cfg
git commit -m "Add second NTP server"
step ".gitignore keeps secrets and clutter out"
cp "$FILES/gitignore-example" .gitignore
mkdir -p secrets && printf 'enable-secret-placeholder\n' > secrets/enable.key
git status --short
git add .gitignore
git commit -m "Ignore secrets, backups and editor files"
step "git log --oneline"
git log --oneline --decorate
