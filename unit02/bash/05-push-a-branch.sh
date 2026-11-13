#!/usr/bin/env bash
# Pushes a new feature branch: the step right before opening a pull request (Unit 3).
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "git switch -c add-vlan-30"
git switch -c add-vlan-30 2>&1
printf 'vlan 30\n name CAMERAS\n!\n' >> configs/edge-router.cfg
git commit -q -am "Add VLAN 30 for cameras"
step "git push -u origin add-vlan-30"
git push -u origin add-vlan-30 2>&1
step "git branch -vv"
git branch -vv
step "git branch -r"
git branch -r
step "git switch main"
git switch main 2>&1
