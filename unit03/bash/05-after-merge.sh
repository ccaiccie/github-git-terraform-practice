#!/usr/bin/env bash
# After merging: delete the branches (server and local), switch to main, pull, prune stale remote-tracking branches.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "git push origin --delete add-vlan-30 change-ntp  (GitHub's Delete branch button)"
git push origin --delete add-vlan-30 change-ntp 2>&1
step "git switch main && git pull"
git switch main 2>&1
git pull 2>&1
step "git branch -d add-vlan-30 change-ntp"
git branch -d add-vlan-30 change-ntp 2>&1
step "In the colleague's clone: git fetch --prune"
cd "$COLLEAGUE"
git pull -q 2>&1
git fetch --prune 2>&1
git branch -a
