#!/usr/bin/env bash
# Verifies the finished lab: expected commits, a fast-forward, one merge commit, ignored secret, clean tree.
source "$(dirname "$0")/lab-env.sh"; need_lab
fail=0; check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
check "on branch main"                     '[[ "$(git branch --show-current)" == main ]]'
check "7 commits reachable from main"      '[[ "$(git rev-list --count main)" == 7 ]]'
check "exactly 1 merge commit"             '[[ "$(git rev-list --merges --count main)" == 1 ]]'
check "merge commit has 2 parents"         '[[ "$(git log -1 --merges --format=%p main | wc -w | tr -d " ")" == 2 ]]'
check "VLAN 20 present in config"          'grep -q "^vlan 20$" configs/edge-router.cfg'
check "NTP 203.0.113.123 present"          'grep -q "^ntp server 203.0.113.123$" configs/edge-router.cfg'
check "secrets/enable.key is ignored"      'git check-ignore -q secrets/enable.key'
check "secret never committed"             '[[ -z "$(git log --all --format= --name-only | grep -F secrets/ || true)" ]]'
check "working tree clean"                 '[[ -z "$(git status --porcelain)" ]]'
check "only branch left is main"           '[[ "$(git branch --format="%(refname:short)")" == main ]]'
check "no remote configured (local only)"  '[[ -z "$(git remote)" ]]'
echo; git log --oneline --graph --all --decorate
if (( fail )); then echo "RESULT: FAIL"; exit 1; else echo "RESULT: PASS"; fi
