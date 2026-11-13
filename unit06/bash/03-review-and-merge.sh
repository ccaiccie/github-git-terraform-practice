#!/usr/bin/env bash
# The reviewer reads the plan comment, the required check has passed, so the pull request is merged.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "The plan comment on pull request #1 (what the reviewer reads)"
cat "$GH/pr-comment-$(run_head add-vlan-30).md"
step "Merge checks"
merge_gate add-vlan-30
step "Merge pull request #1 into main"
git switch -q main
git pull -q 2>&1
git merge -q --no-ff add-vlan-30 -m "Merge pull request #1 from add-vlan-30"
git push 2>&1
git push -q origin --delete add-vlan-30 2>&1; git branch -q -d add-vlan-30
