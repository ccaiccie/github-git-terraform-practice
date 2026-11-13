#!/usr/bin/env bash
# Verifies the finished lab.
source "$(dirname "$0")/lab-env.sh"; need_lab
git -C "$LAPTOP" fetch -q --prune
fail=0; check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
CFG() { git -C "$REMOTE" show main:configs/edge-router.cfg; }
first="$(git -C "$REMOTE" log --format=%H --grep='^Add guest VLAN$' main)"
fix="$(git -C "$REMOTE" log --format=%H --grep='^Use VLAN 40 for guests$' main)"
mainh="$(git -C "$REMOTE" rev-parse main)"
check "main has the workflow file"                 'git -C "$REMOTE" cat-file -e main:.github/workflows/config-check.yml'
check "main has VLAN 40 named GUEST"               'CFG | grep -q "^vlan 40$" && CFG | grep -q "^ name GUEST$"'
check "main has exactly one VLAN 10"              '[[ "$(CFG | grep -c "^vlan 10$")" == 1 ]]'
check "first PR commit has a failed check"         '[[ "$(cat "$CHECKS/$first" 2>/dev/null)" == failure ]]'
check "fix commit has a successful check"          '[[ "$(cat "$CHECKS/$fix" 2>/dev/null)" == success ]]'
check "post-merge run on main succeeded"           '[[ "$(cat "$CHECKS/$mainh" 2>/dev/null)" == success ]]'
check "three workflow runs happened"               '[[ "$(find "$RUNNER" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d " ")" == 3 ]]'
check "one PR merge commit on main"                '[[ "$(git -C "$REMOTE" log --merges --oneline --grep="^Merge pull request" main | wc -l | tr -d " ")" == 1 ]]'
check "only main is left on the server"            '[[ "$(git -C "$REMOTE" for-each-ref --format="%(refname:short)" refs/heads)" == main ]]'
check "laptop working tree clean"                  '[[ -z "$(git -C "$LAPTOP" status --porcelain)" ]]'
check "origin URL is a local path"                 '! git -C "$LAPTOP" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@"'
if (( fail )); then echo "RESULT: FAIL"; exit 1; else echo "RESULT: PASS"; fi
