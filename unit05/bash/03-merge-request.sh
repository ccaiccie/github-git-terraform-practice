#!/usr/bin/env bash
# A push alone creates no pipeline (workflow rules); the merge request does. Then GitLab merge checks: Free versus a Premium approval rule.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Branch push without a merge request (source push)"
pipeline_run push move-to-gitlab-ci
step "Merge request !1 opened: merge request pipeline (source merge_request_event)"
pipeline_run merge_request_event move-to-gitlab-ci
step "Merge checks on GitLab Free"
mr_merge_check move-to-gitlab-ci Free 0
step "Merge checks with a Premium approval rule (1 approval required)"
if mr_merge_check move-to-gitlab-ci Premium 1; then echo "UNEXPECTED: merge allowed without approval" >&2; exit 1; fi
step "A reviewer approves, then the checks run again"
mr_approve move-to-gitlab-ci "Network Lead"
mr_merge_check move-to-gitlab-ci Premium 1
step "Merge !1 into main"
git switch -q main
git pull -q 2>&1
git merge -q --no-ff move-to-gitlab-ci -m "Merge branch 'move-to-gitlab-ci' into 'main'"
git push 2>&1
