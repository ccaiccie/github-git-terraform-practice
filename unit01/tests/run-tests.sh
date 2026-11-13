#!/usr/bin/env bash
# Offline test of the Unit 1 practice in an isolated temporary HOME. No network, no remote, no global config change.
# Runs the Bash and PowerShell 7 sets end to end, compares outcomes, and checks the safety guards.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PWSH="${PWSH:-pwsh}"
pass=0; fail=0
ok(){ echo "PASS: $*"; pass=$((pass+1)); }
ko(){ echo "FAIL: $*"; fail=$((fail+1)); }
run_set(){ # $1 = bash|pwsh
  local shell=$1 T; T="$(mktemp -d)"; export HOME="$T/home" GIT_COURSE_LAB="$T/lab" GIT_CONFIG_NOSYSTEM=1; mkdir -p "$HOME"
  local ext=sh runner=(bash); [[ $shell == pwsh ]] && ext=ps1 runner=("$PWSH" -NoProfile -File)
  for s in 00-check-prereqs 01-create-lab 02-first-commit 03-second-commit-and-history 04-branch-and-fast-forward 05-diverge-and-merge-commit 06-verify; do
    if "${runner[@]}" "$HERE/$shell/$s.$ext" > "$T/$s.log" 2>&1; then ok "$shell $s"; else ko "$shell $s"; sed 's/^/    /' "$T/$s.log"; fi
  done
  grep -q 'RESULT: PASS' "$T/06-verify.log" && ok "$shell verify RESULT: PASS" || ko "$shell verify result"
  grep -q 'Fast-forward' "$T/04-branch-and-fast-forward.log" && ok "$shell 04 shows Fast-forward" || ko "$shell 04 Fast-forward"
  grep -q "Merge made by the 'ort' strategy" "$T/05-diverge-and-merge-commit.log" && ok "$shell 05 shows ort merge" || ko "$shell 05 merge commit"
  [[ ! -f "$HOME/.gitconfig" ]] && ok "$shell global ~/.gitconfig untouched" || ko "$shell wrote global config"
  # tree content for cross-shell comparison
  git -C "$GIT_COURSE_LAB/unit01/network-configs" ls-tree -r HEAD > "$T/tree.txt"; cp "$T/tree.txt" "/tmp/u1-tree-$shell.txt"
  # guard: create refuses to overwrite
  if "${runner[@]}" "$HERE/$shell/01-create-lab.$ext" >/dev/null 2>&1; then ko "$shell 01 overwrote existing lab"; else ok "$shell 01 refuses existing lab"; fi
  # cleanup
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99.log" 2>&1 && [[ ! -e "$GIT_COURSE_LAB/unit01" ]] && ok "$shell 99 cleanup removed lab" || ko "$shell cleanup"
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99b.log" 2>&1 && grep -q 'Nothing to clean' "$T/99b.log" && ok "$shell 99 second run is a no-op" || ko "$shell cleanup rerun"
  # guard: unmarked folder is never deleted
  mkdir -p "$GIT_COURSE_LAB/unit01/precious" && echo keep > "$GIT_COURSE_LAB/unit01/precious/file"
  if "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" >/dev/null 2>&1; then ko "$shell deleted unmarked folder"; else [[ -f "$GIT_COURSE_LAB/unit01/precious/file" ]] && ok "$shell 99 refuses unmarked folder" || ko "$shell unmarked folder damaged"; fi
  # guard: later scripts refuse without a lab
  rm -rf "$GIT_COURSE_LAB"
  if "${runner[@]}" "$HERE/$shell/02-first-commit.$ext" >/dev/null 2>&1; then ko "$shell 02 ran without lab"; else ok "$shell 02 refuses without lab"; fi
  rm -rf "$T"
}
run_set bash
run_set pwsh
if diff <(cut -f2 /tmp/u1-tree-bash.txt | sort) <(cut -f2 /tmp/u1-tree-pwsh.txt | sort) >/dev/null && diff <(awk '{print $3}' /tmp/u1-tree-bash.txt) <(awk '{print $3}' /tmp/u1-tree-pwsh.txt) >/dev/null; then ok "bash and pwsh labs end with identical file content (same blob hashes)"; else ko "bash/pwsh tree mismatch"; diff /tmp/u1-tree-bash.txt /tmp/u1-tree-pwsh.txt; fi
echo; echo "TOTAL: $pass passed, $fail failed"; (( fail == 0 ))
