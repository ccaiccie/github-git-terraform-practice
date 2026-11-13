#!/usr/bin/env bash
# Offline test of the Unit 3 practice in an isolated temporary HOME. The only "remote" is a local bare repository.
# Network is blocked for Git by a bogus proxy and protocol allow-list, so any accidental real push would fail.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PWSH="${PWSH:-pwsh}"
pass=0; fail=0
ok(){ echo "PASS: $*"; pass=$((pass+1)); }
ko(){ echo "FAIL: $*"; fail=$((fail+1)); }
run_set(){ # $1 = bash|pwsh
  local shell=$1 T; T="$(mktemp -d)"; export HOME="$T/home" GIT_COURSE_LAB="$T/lab" GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file https_proxy=http://127.0.0.1:9 http_proxy=http://127.0.0.1:9; mkdir -p "$HOME"
  local ext=sh runner=(bash); [[ $shell == pwsh ]] && ext=ps1 runner=("$PWSH" -NoProfile -File)
  for s in 00-check-prereqs 01-setup 02-open-pr-branch 03-merge-buttons 04-conflict 05-after-merge 06-verify; do
    if "${runner[@]}" "$HERE/$shell/$s.$ext" > "$T/$s.log" 2>&1; then ok "$shell $s"; else ko "$shell $s"; sed 's/^/    /' "$T/$s.log"; fi
  done
  grep -q 'RESULT: PASS' "$T/06-verify.log" && ok "$shell verify RESULT: PASS" || ko "$shell verify result"
  grep -q "branch 'add-vlan-30' set up to track 'origin/add-vlan-30'" "$T/02-open-pr-branch.log" && ok "$shell 02 pushes PR branch with upstream" || ko "$shell 02 upstream"
  grep -q '^+ name CAMERAS$' "$T/02-open-pr-branch.log" && ok "$shell 02 three-dot diff shows the PR change" || ko "$shell 02 diff"
  grep -q 'Merge pull request #1 from add-vlan-30' "$T/03-merge-buttons.log" && ok "$shell 03 merge-commit button" || ko "$shell 03 merge"
  grep -q 'Squash commit -- not updating HEAD' "$T/03-merge-buttons.log" && ok "$shell 03 squash button" || ko "$shell 03 squash"
  [[ "$(sed -n '/new IDs ==/,/^$/p' "$T/03-merge-buttons.log" | grep -v '^[$=]' | awk 'NF>1{print $1}' | sort -u | wc -l)" -ge 4 ]] && ok "$shell 03 rebase gives new commit IDs" || ko "$shell 03 rebase IDs"
  grep -q 'CONFLICT (content): Merge conflict in configs/edge-router.cfg' "$T/04-conflict.log" && ok "$shell 04 real merge conflict" || ko "$shell 04 conflict"
  grep -q '^UU configs/edge-router.cfg' "$T/04-conflict.log" && ok "$shell 04 status shows UU" || ko "$shell 04 UU"
  grep -q '^11-ntp server 192.0.2.200' "$T/04-conflict.log" && grep -q '>>>>>>> origin/main' "$T/04-conflict.log" && ok "$shell 04 shows conflict markers" || ko "$shell 04 markers"
  grep -q '\[deleted\] *add-vlan-30' "$T/05-after-merge.log" && ok "$shell 05 deletes server branches" || ko "$shell 05 delete"
  grep -q 'Deleted branch change-ntp' "$T/05-after-merge.log" && ok "$shell 05 deletes local branches" || ko "$shell 05 local delete"
  grep -q '\[deleted\].*origin/change-ntp' "$T/05-after-merge.log" && ok "$shell 05 prune removes stale tracking branch" || ko "$shell 05 prune"
  [[ ! -f "$HOME/.gitconfig" ]] && ok "$shell global ~/.gitconfig untouched" || ko "$shell wrote global config"
  git -C "$GIT_COURSE_LAB/unit03/server/network-configs.git" ls-tree -r main > "/tmp/u3-tree-$shell.txt"
  if "${runner[@]}" "$HERE/$shell/01-setup.$ext" >/dev/null 2>&1; then ko "$shell 01 overwrote existing lab"; else ok "$shell 01 refuses existing lab"; fi
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99.log" 2>&1 && [[ ! -e "$GIT_COURSE_LAB/unit03" ]] && ok "$shell 99 cleanup removed lab" || ko "$shell cleanup"
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99b.log" 2>&1 && grep -q 'Nothing to clean' "$T/99b.log" && ok "$shell 99 second run is a no-op" || ko "$shell cleanup rerun"
  mkdir -p "$GIT_COURSE_LAB/unit03/precious" && echo keep > "$GIT_COURSE_LAB/unit03/precious/file"
  if "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" >/dev/null 2>&1; then ko "$shell deleted unmarked folder"; else [[ -f "$GIT_COURSE_LAB/unit03/precious/file" ]] && ok "$shell 99 refuses unmarked folder" || ko "$shell unmarked folder damaged"; fi
  rm -rf "$GIT_COURSE_LAB"
  if "${runner[@]}" "$HERE/$shell/02-open-pr-branch.$ext" >/dev/null 2>&1; then ko "$shell 02 ran without lab"; else ok "$shell 02 refuses without lab"; fi
  rm -rf "$T"
}
run_set bash
run_set pwsh
if diff <(awk '{print $3, $4}' /tmp/u3-tree-bash.txt) <(awk '{print $3, $4}' /tmp/u3-tree-pwsh.txt) >/dev/null; then ok "bash and pwsh remotes end with identical file content (same blob hashes)"; else ko "bash/pwsh tree mismatch"; diff /tmp/u3-tree-bash.txt /tmp/u3-tree-pwsh.txt; fi
echo; echo "TOTAL: $pass passed, $fail failed"; (( fail == 0 ))
