#!/usr/bin/env bash
# Verifies the finished lab: clones match the remote, upstreams set, one merge commit, pushed branch, local-only URLs.
source "$(dirname "$0")/lab-env.sh"; need_lab
git -C "$COLLEAGUE" fetch -q; git -C "$LAPTOP" fetch -q
fail=0; check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
R() { git -C "$REMOTE" rev-parse "$1"; }
check "remote is a bare repository"            '[[ "$(git -C "$REMOTE" rev-parse --is-bare-repository)" == true ]]'
check "laptop main equals the remote main"     '[[ "$(git -C "$LAPTOP" rev-parse main)" == "$(R main)" ]]'
check "laptop origin/main equals remote main"  '[[ "$(git -C "$LAPTOP" rev-parse origin/main)" == "$(R main)" ]]'
check "colleague origin/main equals remote"    '[[ "$(git -C "$COLLEAGUE" rev-parse origin/main)" == "$(R main)" ]]'
check "upstream of laptop main is origin/main" '[[ "$(git -C "$LAPTOP" rev-parse --abbrev-ref main@{upstream})" == origin/main ]]'
check "5 commits on the remote main"           '[[ "$(git -C "$REMOTE" rev-list --count main)" == 5 ]]'
check "exactly 1 merge commit on the remote"   '[[ "$(git -C "$REMOTE" rev-list --merges --count main)" == 1 ]]'
check "VLAN 20 and second NTP server present"  'git -C "$REMOTE" show main:configs/edge-router.cfg | grep -q "^vlan 20$" && git -C "$REMOTE" show main:configs/edge-router.cfg | grep -q "^ntp server 198.51.100.123$"'
check "ownership note present"                 'git -C "$REMOTE" show main:README.md | grep -q "^Owner:"'
check "branch add-vlan-30 is on the server"   'git -C "$REMOTE" rev-parse -q --verify refs/heads/add-vlan-30 >/dev/null'
check "add-vlan-30 tracks origin/add-vlan-30"   '[[ "$(git -C "$LAPTOP" rev-parse --abbrev-ref add-vlan-30@{upstream})" == origin/add-vlan-30 ]]'
check "laptop working tree clean"              '[[ -z "$(git -C "$LAPTOP" status --porcelain)" ]]'
check "origin URLs are local paths only"       '! git -C "$LAPTOP" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@" && ! git -C "$COLLEAGUE" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@"'
echo; git -C "$LAPTOP" log --oneline --graph --decorate --all
if (( fail )); then echo "RESULT: FAIL"; exit 1; else echo "RESULT: PASS"; fi
