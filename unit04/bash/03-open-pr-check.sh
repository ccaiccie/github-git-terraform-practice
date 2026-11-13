#!/usr/bin/env bash
# A pull request with a mistake: the simulated workflow run fails, so the check is red.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Branch add-vlan-40 with a mistake: the guest VLAN reuses ID 10"
git switch -c add-vlan-40 2>&1
printf 'vlan 10\n name GUEST\n!\n' >> configs/edge-router.cfg
git commit -q -am "Add guest VLAN"
git push -q -u origin add-vlan-40 2>&1
git log --oneline -1
step "Pull request opened: the workflow runs (event pull_request)"
ci_run pull_request add-vlan-40
