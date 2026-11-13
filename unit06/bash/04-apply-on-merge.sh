#!/usr/bin/env bash
# The push to main starts terraform-apply. It waits for the production review; a laptop apply holds the lock; then it applies.
source "$(dirname "$0")/lab-env.sh"; need_lab
step "Push to main: terraform-apply starts"
wf_apply_start push
step "Meanwhile a colleague runs terraform apply on a laptop (holds the state lock)"
echo "colleague@laptop" > "$LOCK"; echo "state locked by colleague@laptop"
step "Network Lead approves the production deployment"
wf_apply_approve "Network Lead"
step "The laptop run finishes and releases the lock; re-run the failed job"
rm -f "$LOCK"; echo "state lock released"
wf_apply_job
step "The live switch now"
cat "$SWITCH"
