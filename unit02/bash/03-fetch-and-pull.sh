#!/usr/bin/env bash
# The colleague pushes a change. You fetch (download only), inspect, then pull (fetch + merge).
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$COLLEAGUE"
printf 'vlan 20\n name VOICE\n!\n' >> configs/edge-router.cfg
git commit -q -am "Add VLAN 20 for voice"
step "colleague: git push"
git push 2>&1
cd "$LAPTOP"
step "git fetch"
git fetch 2>&1
step "git status"
git status
step "git log --oneline --graph --decorate --all"
git log --oneline --graph --decorate --all
step "git pull"
git pull 2>&1
step "git status"
git status
