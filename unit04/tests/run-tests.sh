#!/usr/bin/env bash
# Offline test of the Unit 4 practice in an isolated temporary HOME. The only "remote" is a local bare repository.
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
  for s in 00-check-prereqs 01-setup 02-validate-workflow 03-open-pr-check 04-blocked-merge 05-fix-and-rerun 06-post-merge 07-verify; do
    if "${runner[@]}" "$HERE/$shell/$s.$ext" > "$T/$s.log" 2>&1; then ok "$shell $s"; else ko "$shell $s"; sed 's/^/    /' "$T/$s.log"; fi
  done
  grep -q 'RESULT: PASS' "$T/07-verify.log" && ok "$shell verify RESULT: PASS" || ko "$shell verify result"
  grep -q 'FAIL: tab character on line 16' "$T/02-validate-workflow.log" && grep -c 'RESULT: PASS' "$T/02-validate-workflow.log" | grep -q 2 && ok "$shell 02 lint passes good file, fails broken copy" || ko "$shell 02 lint"
  grep -q 'FAIL configs/edge-router.cfg:11: duplicate VLAN 10 (first defined on line 7)' "$T/03-open-pr-check.log" && grep -q 'validate: failure' "$T/03-open-pr-check.log" && ok "$shell 03 PR check fails (red)" || ko "$shell 03 red check"
  grep -q 'Merging is blocked' "$T/04-blocked-merge.log" && ok "$shell 04 merge blocked by required check" || ko "$shell 04 gate"
  grep -q 'validate: success' "$T/05-fix-and-rerun.log" && grep -q 'Merge allowed' "$T/05-fix-and-rerun.log" && ok "$shell 05 new commit reruns check, merge allowed" || ko "$shell 05 rerun"
  grep -q 'event: push' "$T/06-post-merge.log" && grep -q '^Config report' "$T/06-post-merge.log" && ok "$shell 06 post-merge run on main with report" || ko "$shell 06 post-merge"
  [[ ! -f "$HOME/.gitconfig" ]] && ok "$shell global ~/.gitconfig untouched" || ko "$shell wrote global config"
  git -C "$GIT_COURSE_LAB/unit04/server/network-configs.git" ls-tree -r main > "/tmp/u4-tree-$shell.txt"
  if "${runner[@]}" "$HERE/$shell/01-setup.$ext" >/dev/null 2>&1; then ko "$shell 01 overwrote existing lab"; else ok "$shell 01 refuses existing lab"; fi
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99.log" 2>&1 && [[ ! -e "$GIT_COURSE_LAB/unit04" ]] && ok "$shell 99 cleanup removed lab" || ko "$shell cleanup"
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99b.log" 2>&1 && grep -q 'Nothing to clean' "$T/99b.log" && ok "$shell 99 second run is a no-op" || ko "$shell cleanup rerun"
  mkdir -p "$GIT_COURSE_LAB/unit04/precious" && echo keep > "$GIT_COURSE_LAB/unit04/precious/file"
  if "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" >/dev/null 2>&1; then ko "$shell deleted unmarked folder"; else [[ -f "$GIT_COURSE_LAB/unit04/precious/file" ]] && ok "$shell 99 refuses unmarked folder" || ko "$shell unmarked folder damaged"; fi
  rm -rf "$GIT_COURSE_LAB"
  if "${runner[@]}" "$HERE/$shell/03-open-pr-check.$ext" >/dev/null 2>&1; then ko "$shell 03 ran without lab"; else ok "$shell 03 refuses without lab"; fi
  rm -rf "$T"
}
run_set bash
run_set pwsh
if diff <(awk '{print $3, $4}' /tmp/u4-tree-bash.txt) <(awk '{print $3, $4}' /tmp/u4-tree-pwsh.txt) >/dev/null; then ok "bash and pwsh remotes end with identical file content (same blob hashes)"; else ko "bash/pwsh tree mismatch"; diff /tmp/u4-tree-bash.txt /tmp/u4-tree-pwsh.txt; fi

# the bash and PowerShell check scripts must agree on a deliberately broken config set
X="$(mktemp -d)"; cp "$HERE/files/repo/configs/edge-router.cfg" "$X/a.cfg"; printf 'vlan 30\n name CAMERAS\n!\nvlan 30\n!\nvlan 5000\n name BAD\n!\n' > "$X/b.cfg"
if diff <(bash "$HERE/files/repo/scripts/check-configs.sh" "$X"; echo "exit $?") <("$PWSH" -NoProfile -File "$HERE/files/repo/scripts/check-configs.ps1" "$X"; echo "exit $?") >/dev/null; then ok "check-configs.sh and .ps1 give identical results and exit codes"; else ko "checker mismatch"; fi
rm -rf "$X"
echo; echo "TOTAL: $pass passed, $fail failed"; (( fail == 0 ))
