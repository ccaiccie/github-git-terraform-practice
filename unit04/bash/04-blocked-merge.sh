#!/usr/bin/env bash
# Branch protection requires the check to pass, so the merge is refused. The same check, run locally, shows why.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Try to merge pull request #1 (expected to be blocked)"
if merge_gate add-vlan-40; then echo "UNEXPECTED: merge allowed" >&2; exit 1; fi
step "Run the same check locally to see the problem"
if bash scripts/check-configs.sh configs; then echo "UNEXPECTED: check passed" >&2; exit 1; fi
