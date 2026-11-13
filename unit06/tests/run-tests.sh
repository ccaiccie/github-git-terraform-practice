#!/usr/bin/env bash
# Offline test of the Unit 6 practice in an isolated temporary HOME. The only "remote" is a local bare repository.
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
  for s in 00-check-prereqs 01-setup 02-plan-on-pr 03-review-and-merge 04-apply-on-merge 05-drift-check 06-revert-drift 07-codify-drift 08-verify; do
    if "${runner[@]}" "$HERE/$shell/$s.$ext" > "$T/$s.log" 2>&1; then ok "$shell $s"; else ko "$shell $s"; sed 's/^/    /' "$T/$s.log"; fi
  done
  grep -q 'RESULT: PASS' "$T/08-verify.log" && ok "$shell verify RESULT: PASS" || ko "$shell verify result"
  grep -q 'Plan: 1 to add, 0 to change, 0 to destroy.' "$T/02-plan-on-pr.log" && grep -q 'comment posted on the pull request' "$T/02-plan-on-pr.log" && ! grep -q '^vlan 30$' "$T/02-plan-on-pr.log" && ok "$shell 02 PR plan: 1 to add, comment posted, switch unchanged" || ko "$shell 02 plan"
  grep -q 'Merge allowed' "$T/03-review-and-merge.log" && grep -q '^### terraform plan for' "$T/03-review-and-merge.log" && ok "$shell 03 reviewer sees the plan comment, merge allowed" || ko "$shell 03 merge"
  grep -q 'waiting for review: environment production' "$T/04-apply-on-merge.log" && grep -q 'Error acquiring the state lock' "$T/04-apply-on-merge.log" && grep -q 'Apply complete! Resources: 1 added' "$T/04-apply-on-merge.log" && ok "$shell 04 apply waits for review, lock blocks, re-run applies" || ko "$shell 04 apply"
  grep -q 'plan exit code: 0' "$T/05-drift-check.log" && grep -q 'plan exit code: 2' "$T/05-drift-check.log" && grep -q 'issue #1 opened' "$T/05-drift-check.log" && ok "$shell 05 drift: exit 0, then exit 2 and an issue" || ko "$shell 05 drift"
  grep -q '1 changed' "$T/06-revert-drift.log" && grep -q 'plan exit code: 0' "$T/06-revert-drift.log" && ok "$shell 06 revert by apply, then exit 0" || ko "$shell 06 revert"
  grep -q 'issue #2 opened' "$T/07-codify-drift.log" && grep -q 'Resources: 0 added, 0 changed, 0 destroyed' "$T/07-codify-drift.log" && tail -3 "$T/07-codify-drift.log" | grep -q 'plan exit code: 0' && ok "$shell 07 codify: empty plan, exit 0" || ko "$shell 07 codify"
  ( cd "$GIT_COURSE_LAB/unit06" && cat switch/running-config state/terraform.tfstate github/issues/*.md; cat github/pr-comment-*.md | sed -E 's/[0-9a-f]{7}/SHA/g' | sort ) > "/tmp/u6-data-$shell.txt"
  [[ ! -f "$HOME/.gitconfig" ]] && ok "$shell global ~/.gitconfig untouched" || ko "$shell wrote global config"
  git -C "$GIT_COURSE_LAB/unit06/server/network-configs.git" ls-tree -r main > "/tmp/u6-tree-$shell.txt"
  if "${runner[@]}" "$HERE/$shell/01-setup.$ext" >/dev/null 2>&1; then ko "$shell 01 overwrote existing lab"; else ok "$shell 01 refuses existing lab"; fi
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99.log" 2>&1 && [[ ! -e "$GIT_COURSE_LAB/unit06" ]] && ok "$shell 99 cleanup removed lab" || ko "$shell cleanup"
  "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" > "$T/99b.log" 2>&1 && grep -q 'Nothing to clean' "$T/99b.log" && ok "$shell 99 second run is a no-op" || ko "$shell cleanup rerun"
  mkdir -p "$GIT_COURSE_LAB/unit06/precious" && echo keep > "$GIT_COURSE_LAB/unit06/precious/file"
  if "${runner[@]}" "$HERE/$shell/99-cleanup.$ext" >/dev/null 2>&1; then ko "$shell deleted unmarked folder"; else [[ -f "$GIT_COURSE_LAB/unit06/precious/file" ]] && ok "$shell 99 refuses unmarked folder" || ko "$shell unmarked folder damaged"; fi
  rm -rf "$GIT_COURSE_LAB"
  if "${runner[@]}" "$HERE/$shell/04-apply-on-merge.$ext" >/dev/null 2>&1; then ko "$shell 03 ran without lab"; else ok "$shell 04 refuses without lab"; fi
  rm -rf "/tmp/u6-logs-$shell"; mkdir -p "/tmp/u6-logs-$shell"; cp "$T"/0[1-8]-*.log "/tmp/u6-logs-$shell/"
  rm -rf "$T"
}
run_set bash
run_set pwsh
if diff <(awk '{print $3, $4}' /tmp/u6-tree-bash.txt) <(awk '{print $3, $4}' /tmp/u6-tree-pwsh.txt) >/dev/null; then ok "bash and pwsh remotes end with identical file content (same blob hashes)"; else ko "bash/pwsh tree mismatch"; diff /tmp/u6-tree-bash.txt /tmp/u6-tree-pwsh.txt; fi

if grep -rIEq 'https?://' "$HERE/bash" "$HERE/pwsh" "$HERE/files"; then ko "a URL appears in scripts or files"; grep -rIEn 'https?://' "$HERE/bash" "$HERE/pwsh" "$HERE/files"; else ok "no URLs in scripts or lab files (nothing to contact)"; fi
norm(){ sed -E 's/[0-9a-f]{7}/SHA/g; s#/tmp/[^ ]*/lab/#LAB/#g' "$1"; }
same=1; for f in /tmp/u6-logs-bash/*.log; do diff <(norm "$f") <(norm "/tmp/u6-logs-pwsh/$(basename "$f")") >/dev/null || { same=0; echo "    differs: $(basename "$f")"; }; done
(( same )) && ok "bash and pwsh scripts 01-08 print identical output (commit IDs and temp paths masked)" || ko "bash/pwsh output differs"

diff /tmp/u6-data-bash.txt /tmp/u6-data-pwsh.txt >/dev/null && ok "bash and pwsh leave identical switch config, state, issues and PR comments" || ko "lab data differs"
# the bash and PowerShell check scripts must agree on a deliberately broken config set
X="$(mktemp -d)"; export GIT_COURSE_LAB="$X/nolab"
mkdir -p "$X/bad" "$X/good"; cp "$HERE/files/repo/infra/main.tf" "$X/good/"
printf 'resource "lab_vlan" "a" {\n  vlan_id = 10\n  name    = "A"\n}\n\nresource "lab_vlan" "b" {\n  vlan_id = 5000\n}\n\nresource "lab_vlan" "c" {\n  vlan_id = 10\n  name    = "C"\n}\n' > "$X/bad/main.tf"
for d in bad good; do
  b="$(bash -c 'source "$1/bash/lab-env.sh"; set +e; cd "$2"; tfsim plan -detailed-exitcode; echo "exit $?"' _ "$HERE" "$X/$d" 2>&1)"
  printf 'param($h, $d)\n. (Join-Path $h "pwsh/lab-env.ps1")\n$c = Invoke-Tf plan $d -Detailed\nWrite-Host "exit $c"\n' > "$X/t.ps1"
  p="$("$PWSH" -NoProfile -File "$X/t.ps1" "$HERE" "$X/$d" 2>&1)"
  want=$([[ $d == bad ]] && echo 1 || echo 2)
  if [[ "$b" == "$p" && "$b" == *"exit $want" ]]; then ok "tfsim $d config: bash and pwsh agree, -detailed-exitcode gives $want"; else ko "tfsim $d config"; echo "$b"; echo "$p"; fi
done
rm -rf "$X"
echo; echo "TOTAL: $pass passed, $fail failed"; (( fail == 0 ))
