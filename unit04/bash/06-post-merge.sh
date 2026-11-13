#!/usr/bin/env bash
# The merge is a push to main, so the same workflow runs once more on main, including the report step. Then clean up.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Push to main: the workflow runs on main (event push)"
ci_run push main
step "Delete the merged branch"
git push -q origin --delete add-vlan-40 2>&1
git branch -d add-vlan-40 2>&1
step "History on main"
git log --oneline --graph -4
