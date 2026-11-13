#!/usr/bin/env bash
# A pull request that adds VLAN 30: the plan workflow validates, plans and posts the plan. Nothing changes on the switch.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Branch add-vlan-30: add a lab_vlan resource"
git switch -c add-vlan-30 2>&1
printf '\nresource "lab_vlan" "cameras" {\n  vlan_id = 30\n  name    = "CAMERAS"\n}\n' >> infra/main.tf
git commit -q -am "Add VLAN 30 for cameras"
git push -q -u origin add-vlan-30 2>&1
git log --oneline -1
step "Pull request #1 opened: terraform-plan runs"
wf_plan add-vlan-30
step "A plan changes nothing: the switch still has no VLAN 30"
if grep -q '^vlan 30$' "$SWITCH"; then echo "UNEXPECTED: VLAN 30 exists" >&2; exit 1; fi
grep '^vlan' "$SWITCH"
