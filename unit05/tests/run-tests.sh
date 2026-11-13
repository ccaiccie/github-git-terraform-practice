#!/usr/bin/env bash
# Offline test of the Unit 5 practice in an isolated temporary HOME. The only "remote" is a local bare repository.
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
  for s in 00-check-prereqs 01-setup 02-translate 03-merge-request 04-main-pipeline 05-opentofu-example 06-verify; do
    if "${runner[@]}" "$HERE/$shell/$s.$ext" > "$T/$s.log" 2>&1; then ok "$shell $s"; else ko "$shell $s"; sed 's/^/    /' "$T/$s.log"; fi
  done
  grep -q 'RESULT: PASS' "$T/06-verify.log" && ok "$shell verify RESULT: PASS" || ko "$shell verify result"
  grep -q "FAIL: job validate: stage 'check' is not listed in stages" "$T/02-translate.log" && grep -c 'RESULT: PASS' "$T/02-translate.log" | grep -q 1 && ok "$shell 02 lint catches the wrong stage, passes after the fix" || ko "$shell 02 lint"
  grep -q 'no pipeline created (workflow rules)' "$T/03-merge-request.log" && grep -q 'job report: not in this pipeline (rules)' "$T/03-merge-request.log" && ok "$shell 03 rules: no branch pipeline, report job not in MR pipeline" || ko "$shell 03 rules"
  grep -q 'approvals: 0 given, optional on Free' "$T/03-merge-request.log" && grep -q 'Merge blocked' "$T/03-merge-request.log" && grep -c 'Ready to merge' "$T/03-merge-request.log" | grep -q 2 && ok "$shell 03 Free merges without approval; Premium rule blocks until approved" || ko "$shell 03 merge checks"
  grep -q 'job report (stage report):' "$T/04-main-pipeline.log" && grep -q 'pipeline #2: passed' "$T/04-main-pipeline.log" && ok "$shell 04 main pipeline runs both stages" || ko "$shell 04 main pipeline"
  grep -q "found '@~latest'" "$T/05-opentofu-example.log" && grep -c 'RESULT: PASS' "$T/05-opentofu-example.log" | grep -q 1 && ok "$shell 05 OpenTofu example passes, unpinned copy fails" || ko "$shell 05 tofu lint"
  [[ ! -f "$HOME/.gitconfig" ]] && ok "$shell global ~/.gitconfig untouched" || ko "$shell wrote global config"
  git -C "$GIT_COURSE_LAB/unit05/server/network-configs.git" ls-tree -r main > "/tmp/u5-tree-$shell.txt"
  if "${runner[@]}" "$HERE/$shell/01-setup.$ext" >/dev/null 2>&1; then ko "$shell 01 overwrote existing lab"; else ok "$shell 01 refuses existing lab"; fi
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99.log" 2>&1 && [[ ! -e "$GIT_COURSE_LAB/unit05" ]] && ok "$shell 99 cleanup removed lab" || ko "$shell cleanup"
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99b.log" 2>&1 && grep -q 'Nothing to clean' "$T/99b.log" && ok "$shell 99 second run is a no-op" || ko "$shell cleanup rerun"
  mkdir -p "$GIT_COURSE_LAB/unit05/precious" && echo keep > "$GIT_COURSE_LAB/unit05/precious/file"
  if "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" >/dev/null 2>&1; then ko "$shell deleted unmarked folder"; else [[ -f "$GIT_COURSE_LAB/unit05/precious/file" ]] && ok "$shell 99 refuses unmarked folder" || ko "$shell unmarked folder damaged"; fi
  rm -rf "$GIT_COURSE_LAB"
  if "${runner[@]}" "$HERE/$shell/03-merge-request.$ext" >/dev/null 2>&1; then ko "$shell 03 ran without lab"; else ok "$shell 03 refuses without lab"; fi
  rm -rf "/tmp/u5-logs-$shell"; mkdir -p "/tmp/u5-logs-$shell"; cp "$T"/0[2-6]-*.log "/tmp/u5-logs-$shell/"
  rm -rf "$T"
}
run_set bash
run_set pwsh
if diff <(awk '{print $3, $4}' /tmp/u5-tree-bash.txt) <(awk '{print $3, $4}' /tmp/u5-tree-pwsh.txt) >/dev/null; then ok "bash and pwsh remotes end with identical file content (same blob hashes)"; else ko "bash/pwsh tree mismatch"; diff /tmp/u5-tree-bash.txt /tmp/u5-tree-pwsh.txt; fi

if grep -rIEq 'https?://' "$HERE/bash" "$HERE/pwsh" "$HERE/files"; then ko "a URL appears in scripts or files"; grep -rIEn 'https?://' "$HERE/bash" "$HERE/pwsh" "$HERE/files"; else ok "no URLs in scripts or lab files (nothing to contact)"; fi
norm(){ sed -E 's/[0-9a-f]{7}/SHA/g; s#/tmp/[^ ]*/lab/#LAB/#g' "$1"; }
same=1; for f in /tmp/u5-logs-bash/*.log; do diff <(norm "$f") <(norm "/tmp/u5-logs-pwsh/$(basename "$f")") >/dev/null || { same=0; echo "    differs: $(basename "$f")"; }; done
(( same )) && ok "bash and pwsh scripts 02-06 print identical output (commit IDs and temp paths masked)" || ko "bash/pwsh output differs"

# the bash and PowerShell check scripts must agree on a deliberately broken config set
X="$(mktemp -d)"; cp "$HERE/files/repo/configs/edge-router.cfg" "$X/a.cfg"; printf 'vlan 30\n name CAMERAS\n!\nvlan 30\n!\nvlan 5000\n name BAD\n!\n' > "$X/b.cfg"
if diff <(bash "$HERE/files/repo/scripts/check-configs.sh" "$X"; echo "exit $?") <("$PWSH" -NoProfile -File "$HERE/files/repo/scripts/check-configs.ps1" "$X"; echo "exit $?") >/dev/null; then ok "check-configs.sh and .ps1 give identical results and exit codes"; else ko "checker mismatch"; fi
rm -rf "$X"
echo; echo "TOTAL: $pass passed, $fail failed"; (( fail == 0 ))
