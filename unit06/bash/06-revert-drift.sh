#!/usr/bin/env bash
# Decision 1, revert: the hand change was not wanted. Run terraform-apply by hand on main; the code wins. Check again.
source "$(dirname "$0")/lab-env.sh"; need_lab
step "Run terraform-apply by hand (workflow_dispatch) on main"
wf_apply_start workflow_dispatch
wf_apply_approve "Network Lead"
step "Drift check after the revert"
wf_drift
