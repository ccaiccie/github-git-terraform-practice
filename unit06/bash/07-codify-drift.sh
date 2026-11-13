#!/usr/bin/env bash
# Decision 2, codify: the team agrees VLAN 30 is now called CCTV, as set by hand. Change the code to match; the plan is empty.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "VLAN 30 renamed to CCTV by hand, then the drift check"
printf '10 USERS\n20 VOICE\n30 CCTV\n' | sw_write
wf_drift
step "Codify: a pull request that renames VLAN 30 in the code"
git switch -c rename-vlan-30 2>&1
replace_line infra/main.tf '  name    = "CAMERAS"' '  name    = "CCTV"'
git commit -q -am "Rename VLAN 30 to CCTV (codify drift)"
git push -q -u origin rename-vlan-30 2>&1
wf_plan rename-vlan-30
step "Merge, apply on main, and check again"
merge_gate rename-vlan-30
git switch -q main; git pull -q 2>&1
git merge -q --no-ff rename-vlan-30 -m "Merge pull request #2 from rename-vlan-30"
git push -q 2>&1; git push -q origin --delete rename-vlan-30 2>&1; git branch -q -d rename-vlan-30
wf_apply_start push
wf_apply_approve "Network Lead"
wf_drift
