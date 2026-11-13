#!/usr/bin/env bash
# Shared settings for the Unit 4 practice (sourced by every script).
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
set -euo pipefail
LAB_ROOT="${GIT_COURSE_LAB:-$HOME/git-course-lab}"
LAB="$LAB_ROOT/unit04"
REMOTE="$LAB/server/network-configs.git"   # plays the role of GitHub or GitLab
LAPTOP="$LAB/laptop/network-configs"       # your clone
COLLEAGUE="$LAB/colleague/network-configs" # a teammate's clone
MARKER="$LAB/.git-course-unit04"
MARKER_TEXT="git-course unit04 practice lab - safe to delete with 99-cleanup"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="$HERE/../files"
need_lab() {
  if [[ ! -f "$MARKER" ]] || [[ "$(cat "$MARKER")" != "$MARKER_TEXT" ]]; then
    echo "ERROR: lab not found at $LAB (run 01-setup.sh first)." >&2; exit 1
  fi
}
lab_identity() { # $1 = name, $2 = email; stored in this repository only
  git config --local user.name "$1"; git config --local user.email "$2"
  git config --local core.autocrlf false; git config --local pull.rebase false
}
step() { printf '\n== %s ==\n' "$*"; }
replace_line() { # $1 file, $2 exact old line, $3 new line (portable awk, LF endings)
  awk -v o="$2" -v n="$3" '{ if ($0 == o) print n; else print }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
say() { printf '$ %s\n' "$1"; } # show the command being run
RUNNER="$LAB/runner"   # each simulated workflow run gets a fresh clone here, like a new runner VM
CHECKS="$LAB/checks"   # one file per commit: the check result GitHub would show on that commit
# Simulates one run of .github/workflows/config-check.yml, job "validate". $1 = pull_request|push, $2 = branch.
ci_run() {
  local event=$1 br=$2 head n run status
  head="$(git -C "$REMOTE" rev-parse "refs/heads/$br")"
  mkdir -p "$RUNNER" "$CHECKS"; n=$(( $(find "$RUNNER" -mindepth 1 -maxdepth 1 -type d | wc -l) + 1 )); run="$RUNNER/run-$n"
  git clone -q "$REMOTE" "$run" 2>&1
  if [[ $event == pull_request ]]; then # like GitHub: test the branch as if it were merged into main
    git -C "$run" switch -q -c pr-merge-test origin/main
    git -C "$run" -c user.name=runner -c user.email=runner@example.com merge -q --no-ff --no-edit "origin/$br" >/dev/null
  fi
  echo "run #$n  workflow: config-check  job: validate  event: $event  commit: ${head:0:7}"
  if (cd "$run" && bash scripts/check-configs.sh configs); then status=success; else status=failure; fi
  if [[ $status == success && $event == push ]]; then echo "Config report: VLAN lines"; (cd "$run" && grep -c '^vlan ' configs/*.cfg); fi
  echo "$status" > "$CHECKS/$head"
  echo "check config-check / validate: $status"
}
# Simulates branch protection with a required status check. $1 = branch. Returns 1 when merging is blocked.
merge_gate() {
  local br=$1 head st
  head="$(git -C "$REMOTE" rev-parse "refs/heads/$br")"
  st="$(cat "$CHECKS/$head" 2>/dev/null || echo pending)"
  echo "required check config-check / validate on ${head:0:7}: $st"
  if [[ $st == success ]]; then echo "Merge allowed"; return 0; fi
  echo "Merging is blocked: the required check has not passed"; return 1
}
# Basic structure checks for a workflow file (no YAML library needed). Full validation: actionlint (optional).
lint_workflow() {
  local wf=$1 repo=$2 fail=0 jobs runs steps
  ok() { echo "PASS: $1"; }; ko() { echo "FAIL: $1"; fail=1; }
  if grep -qn $'\t' "$wf"; then ko "tab character on line $(grep -n $'\t' "$wf" | head -1 | cut -d: -f1) (YAML indentation must use spaces)"; else ok "no tab characters"; fi
  if grep -q '^name:' "$wf" && grep -q '^on:' "$wf" && grep -q '^jobs:' "$wf"; then ok "top-level keys name, on, jobs"; else ko "missing name:, on: or jobs:"; fi
  grep -q '^  pull_request:' "$wf" && ok "runs on pull requests" || ko "no pull_request trigger"
  grep -q '^  push:' "$wf" && ok "runs on push (after merge)" || ko "no push trigger"
  grep -q '^permissions:' "$wf" && ok "permissions are set explicitly" || ko "no permissions: block"
  jobs=$(awk '/^jobs:/{j=1;next} /^[^ #]/{j=0} j && /^  [A-Za-z0-9_-]+:[ ]*$/{c++} END{print c+0}' "$wf")
  runs=$(grep -c '^    runs-on:' "$wf" || true); steps=$(grep -c '^    steps:' "$wf" || true)
  if (( jobs > 0 && runs == jobs && steps == jobs )); then ok "$jobs job(s), each with runs-on and steps"; else ko "jobs: $jobs, runs-on: $runs, steps: $steps (each job needs both)"; fi
  if grep -E '^\s*-?\s*uses:' "$wf" | grep -vq '@'; then ko "an action is not pinned to a version (@...)"; else ok "actions pinned to a version"; fi
  local s; while read -r s; do [[ -f "$repo/$s" ]] && ok "script exists: $s" || ko "script not found: $s"; done < <(sed -nE 's/^\s*run: bash ([^ ]+).*/\1/p' "$wf")
  if (( fail )); then echo "RESULT: FAIL"; return 1; fi; echo "RESULT: PASS"
}
