#!/usr/bin/env bash
# Offline test of the Unit 2 practice in an isolated temporary HOME. The only "remote" is a local bare repository.
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
  for s in 00-check-prereqs 01-create-remote-and-push 02-clone 03-fetch-and-pull 04-rejected-push 05-push-a-branch 06-verify; do
    if "${runner[@]}" "$HERE/$shell/$s.$ext" > "$T/$s.log" 2>&1; then ok "$shell $s"; else ko "$shell $s"; sed 's/^/    /' "$T/$s.log"; fi
  done
  grep -q 'RESULT: PASS' "$T/06-verify.log" && ok "$shell verify RESULT: PASS" || ko "$shell verify result"
  grep -q "set up to track 'origin/main'" "$T/01-create-remote-and-push.log" && ok "$shell 01 sets upstream" || ko "$shell 01 upstream"
  grep -q "behind 'origin/main' by 1 commit" "$T/03-fetch-and-pull.log" && ok "$shell 03 fetch leaves main behind" || ko "$shell 03 behind"
  grep -q 'Fast-forward' "$T/03-fetch-and-pull.log" && ok "$shell 03 pull fast-forwards" || ko "$shell 03 pull"
  grep -q '\[rejected\].*fetch first' "$T/04-rejected-push.log" && ok "$shell 04 push rejected (fetch first)" || ko "$shell 04 rejection"
  grep -q "Merge made by the 'ort' strategy" "$T/04-rejected-push.log" && ok "$shell 04 pull merges" || ko "$shell 04 merge"
  grep -q "ahead of 'origin/main' by 1 commit" "$T/04-rejected-push.log" && ok "$shell 04 status shows ahead by 1" || ko "$shell 04 ahead"
  grep -q "branch 'add-vlan-30' set up to track 'origin/add-vlan-30'" "$T/05-push-a-branch.log" && ok "$shell 05 pushes branch with upstream" || ko "$shell 05 branch push"
  [[ ! -f "$HOME/.gitconfig" ]] && ok "$shell global ~/.gitconfig untouched" || ko "$shell wrote global config"
  git -C "$GIT_COURSE_LAB/unit02/server/network-configs.git" ls-tree -r add-vlan-30 > "/tmp/u2-tree-$shell.txt"
  if "${runner[@]}" "$HERE/$shell/01-create-remote-and-push.$ext" >/dev/null 2>&1; then ko "$shell 01 overwrote existing lab"; else ok "$shell 01 refuses existing lab"; fi
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99.log" 2>&1 && [[ ! -e "$GIT_COURSE_LAB/unit02" ]] && ok "$shell 99 cleanup removed lab" || ko "$shell cleanup"
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99b.log" 2>&1 && grep -q 'Nothing to clean' "$T/99b.log" && ok "$shell 99 second run is a no-op" || ko "$shell cleanup rerun"
  mkdir -p "$GIT_COURSE_LAB/unit02/precious" && echo keep > "$GIT_COURSE_LAB/unit02/precious/file"
  if "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" >/dev/null 2>&1; then ko "$shell deleted unmarked folder"; else [[ -f "$GIT_COURSE_LAB/unit02/precious/file" ]] && ok "$shell 99 refuses unmarked folder" || ko "$shell unmarked folder damaged"; fi
  rm -rf "$GIT_COURSE_LAB"
  if "${runner[@]}" "$HERE/$shell/02-clone.$ext" >/dev/null 2>&1; then ko "$shell 02 ran without lab"; else ok "$shell 02 refuses without lab"; fi
  rm -rf "$T"
}
run_set bash
run_set pwsh
if diff <(awk '{print $3, $4}' /tmp/u2-tree-bash.txt) <(awk '{print $3, $4}' /tmp/u2-tree-pwsh.txt) >/dev/null; then ok "bash and pwsh remotes end with identical file content (same blob hashes)"; else ko "bash/pwsh tree mismatch"; diff /tmp/u2-tree-bash.txt /tmp/u2-tree-pwsh.txt; fi
echo; echo "TOTAL: $pass passed, $fail failed"; (( fail == 0 ))
