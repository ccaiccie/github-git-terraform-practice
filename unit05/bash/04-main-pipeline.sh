#!/usr/bin/env bash
# The merge updates main, so a branch pipeline runs on main: stage test, then stage report. Then clean up the branch.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Push to main: pipeline on the default branch (source push)"
pipeline_run push main
step "Delete the merged branch"
git push -q origin --delete move-to-gitlab-ci 2>&1
git branch -d move-to-gitlab-ci 2>&1
step "History on main"
git log --oneline --graph -3
