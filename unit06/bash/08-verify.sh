#!/usr/bin/env bash
# Verifies the finished lab.
source "$(dirname "$0")/lab-env.sh"; need_lab
git -C "$LAPTOP" fetch -q --prune
fail=0; check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
pr1="$(git -C "$REMOTE" log --format=%h --abbrev=7 --grep='^Add VLAN 30 for cameras$' main)"
check "main defines VLAN 30 as CCTV"                'git -C "$REMOTE" show main:infra/main.tf | grep -q "name    = \"CCTV\""'
check "switch matches main (10 USERS, 20 VOICE, 30 CCTV)" '[[ "$(sw_vlans | tr "\n" " ")" == "10 USERS 20 VOICE 30 CCTV " ]]'
check "state matches main"                          '[[ "$(grep -c "^lab_vlan\." "$STATE")" == 3 ]] && grep -q "^lab_vlan.cameras 30 CCTV$" "$STATE"'
check "first pull request's plan check passed"      '[[ "$(cat "$GH/checks/$pr1" 2>/dev/null)" == success ]]'
check "plan comment was posted for it"              'grep -q "1 to add" "$GH/pr-comment-$pr1.md"'
check "two drift issues were opened"                '[[ "$(find "$GH/issues" -name "*.md" | wc -l | tr -d " ")" == 2 ]]'
check "last drift check exit code was 0"            '[[ "$(cat "$GH/last-drift-exit")" == 0 ]]'
check "no apply is left waiting"                    '[[ ! -f "$GH/pending-apply" ]]'
check "no state lock is left"                       '[[ ! -f "$LOCK" ]]'
check "only main is left on the server"             '[[ "$(git -C "$REMOTE" for-each-ref --format="%(refname:short)" refs/heads)" == main ]]'
check "laptop working tree clean"                   '[[ -z "$(git -C "$LAPTOP" status --porcelain)" ]]'
check "origin URL is a local path"                  '! git -C "$LAPTOP" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@"'
if (( fail )); then echo "RESULT: FAIL"; exit 1; else echo "RESULT: PASS"; fi
