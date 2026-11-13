#!/usr/bin/env bash
# Verifies the finished lab.
source "$(dirname "$0")/lab-env.sh"; need_lab
git -C "$LAPTOP" fetch -q --prune; git -C "$COLLEAGUE" fetch -q --prune
fail=0; check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
CFG() { git -C "$REMOTE" show main:configs/edge-router.cfg; }
check "server main has VLAN 30 named CAMERAS"      'CFG | grep -q "^ name CAMERAS$"'
check "conflict resolved to ntp 192.0.2.200"        'CFG | grep -q "^ntp server 192.0.2.200$" && ! CFG | grep -q "192.0.2.250"'
check "no conflict markers on the server"           '! git -C "$REMOTE" grep -q -E "^(<<<<<<<|=======|>>>>>>>)" main --'
check "two PR merge commits on main"                '[[ "$(git -C "$REMOTE" log --merges --oneline --grep="^Merge pull request" main | wc -l | tr -d " ")" == 2 ]]'
check "only main is left on the server"             '[[ "$(git -C "$REMOTE" for-each-ref --format="%(refname:short)" refs/heads)" == main ]]'
check "laptop main equals the server main"          '[[ "$(git -C "$LAPTOP" rev-parse main)" == "$(git -C "$REMOTE" rev-parse main)" ]]'
check "laptop has only the main branch"             '[[ "$(git -C "$LAPTOP" branch --format="%(refname:short)")" == main ]]'
check "colleague has no stale remote branches"      '[[ "$(git -C "$COLLEAGUE" for-each-ref --format="%(refname)" refs/remotes/origin | grep -v "^refs/remotes/origin/HEAD$" | grep -cv "^refs/remotes/origin/main$" || true)" == 0 ]]'
check "laptop working tree clean"                   '[[ -z "$(git -C "$LAPTOP" status --porcelain)" ]]'
check "origin URLs are local paths only"            '! git -C "$LAPTOP" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@" && ! git -C "$COLLEAGUE" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@"'
echo; git -C "$LAPTOP" log --oneline --graph --decorate -8
if (( fail )); then echo "RESULT: FAIL"; exit 1; else echo "RESULT: PASS"; fi
