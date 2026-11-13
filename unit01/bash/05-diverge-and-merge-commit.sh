#!/usr/bin/env bash
# Both branches move on, so the merge needs a merge commit with two parents.
source "$(dirname "$0")/lab-env.sh"; need_lab
step "git switch -c update-ntp, change the config"
git switch -c update-ntp
awk '{ if ($0=="ntp server 198.51.100.123") print "ntp server 203.0.113.123"; else print }' configs/edge-router.cfg > cfg.tmp && mv cfg.tmp configs/edge-router.cfg
git commit -am "Replace second NTP server"
step "Meanwhile on main, someone documents the repository"
git switch main
printf 'Owner: network team. Change one device per branch.\n' >> README.md
git commit -am "Document repository ownership"
step "git log --oneline --graph --all (history has diverged)"
git log --oneline --graph --all --decorate
step "git merge update-ntp (three-way merge creates a merge commit)"
git merge --no-edit update-ntp
git branch -d update-ntp
git log --oneline --graph --all --decorate
