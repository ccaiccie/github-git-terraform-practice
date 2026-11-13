#!/usr/bin/env bash
# Creates a branch, commits on it, and merges it back with a fast-forward.
source "$(dirname "$0")/lab-env.sh"; need_lab
step "git switch -c add-vlan-20"
git switch -c add-vlan-20
printf '!\nvlan 20\n name VOICE\n' >> configs/edge-router.cfg
git add configs/edge-router.cfg
git commit -m "Add VLAN 20 for voice"
step "git log --oneline --graph --all (main has not moved)"
git log --oneline --graph --all --decorate
step "git switch main, then git merge add-vlan-20"
git switch main
git merge add-vlan-20
step "git branch -d add-vlan-20 (the label goes; the commits stay)"
git branch -d add-vlan-20
git log --oneline --graph --all --decorate
