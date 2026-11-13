#!/usr/bin/env bash
# The work behind a pull request: a feature branch with two commits, pushed, then read the way a PR shows it.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "git switch -c add-vlan-30"
git switch -c add-vlan-30 2>&1
printf 'vlan 30\n name CAMERA\n!\n' >> configs/edge-router.cfg
git commit -q -am "Add VLAN 30 for cameras"
replace_line configs/edge-router.cfg " name CAMERA" " name CAMERAS"
git commit -q -am "Fix VLAN 30 name"
step "git push -u origin add-vlan-30"
git push -u origin add-vlan-30 2>&1
step "git log --oneline main..add-vlan-30  (the PR's commits)"
git log --oneline main..add-vlan-30
step "git diff main...add-vlan-30  (the PR's Files changed tab)"
git --no-pager diff main...add-vlan-30
