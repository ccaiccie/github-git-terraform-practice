#!/usr/bin/env bash
# Push a fix to the same branch: the workflow runs again on the new commit, the check turns green, the merge is allowed.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Fix: use VLAN 40 for guests, commit, push to the same branch"
git show main:configs/edge-router.cfg > configs/edge-router.cfg
printf 'vlan 40\n name GUEST\n!\n' >> configs/edge-router.cfg
git commit -q -am "Use VLAN 40 for guests"
git push 2>&1
step "New commit on the pull request: the workflow runs again (pull_request, synchronize)"
ci_run pull_request add-vlan-40
step "Try to merge pull request #1 again"
merge_gate add-vlan-40
step "Merge pull request #1 into main"
git switch -q main
git pull -q 2>&1
git merge -q --no-ff add-vlan-40 -m "Merge pull request #1 from add-vlan-40"
git push 2>&1
