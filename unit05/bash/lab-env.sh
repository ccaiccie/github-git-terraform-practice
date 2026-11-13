#!/usr/bin/env bash
# Shared settings for the Unit 5 practice (sourced by every script).
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
set -euo pipefail
LAB_ROOT="${GIT_COURSE_LAB:-$HOME/git-course-lab}"
LAB="$LAB_ROOT/unit05"
REMOTE="$LAB/server/network-configs.git"   # plays the role of GitLab
LAPTOP="$LAB/laptop/network-configs"       # your clone
COLLEAGUE="$LAB/colleague/network-configs" # a teammate's clone
MARKER="$LAB/.git-course-unit05"
MARKER_TEXT="git-course unit05 practice lab - safe to delete with 99-cleanup"
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
RUNNER="$LAB/runner"       # each simulated pipeline gets a fresh clone here, like a new runner job
PIPES="$LAB/pipelines"     # one file per commit: the pipeline status GitLab would show for that commit
APPROVALS="$LAB/approvals" # one line per approval, per commit
RESERVED=" stages workflow default variables include image services cache before_script after_script "
# --- tiny readers for the simple .gitlab-ci.yml layout used in this lab (no YAML library needed) ---
ci_stages() { sed -nE 's/^stages: *\[(.*)\] *$/\1/p' "$1" | tr -d ' ' | tr ',' '\n'; }
ci_jobs() { local k; while read -r k; do [[ $RESERVED == *" $k "* ]] || echo "$k"; done < <(sed -nE 's/^([A-Za-z0-9_.-]+):.*$/\1/p' "$1"); }
ci_block() { awk -v j="$2" '$0 ~ "^"j":" {on=1; next} /^[^ #]/ {on=0} on' "$1"; } # lines of one top-level block
ci_job_stage() { ci_block "$1" "$2" | sed -nE 's/^  stage: *([^ ]+) *$/\1/p'; }
ci_if_lines() { sed -nE 's/^ *- if: *(.*[^ ]) *$/\1/p'; }
ci_job_script() { ci_block "$1" "$2" | awk '/^  script:/ {on=1; next} /^  [a-z]/ {on=0} on' | sed -nE 's/^    - (.*)$/\1/p'; }
# Evaluates the two rule expressions used in this lab. $1 = expression, $2 = pipeline source, $3 = branch.
rule_true() {
  case "$1" in
    '$CI_PIPELINE_SOURCE == "merge_request_event"') [[ $2 == merge_request_event ]] ;;
    '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH') [[ $2 == push && $3 == main ]] ;;
    *) echo "unsupported rule in this simulator: $1" >&2; return 1 ;;
  esac
}
rules_match() { # stdin = rule expressions; no rules at all = match
  local any=0 e; while read -r e; do any=1; rule_true "$e" "$1" "$2" && return 0; done; (( any == 0 ))
}
# Simulates one GitLab pipeline. $1 = merge_request_event|push, $2 = branch.
# Like a merge request pipeline on GitLab Free, it tests the source branch as it is (merged results pipelines are Premium).
pipeline_run() {
  local src=$1 br=$2 head n run f status=passed st j line stages=()
  head="$(git -C "$REMOTE" rev-parse "refs/heads/$br")"
  mkdir -p "$RUNNER" "$PIPES"; n=$(( $(find "$RUNNER" -mindepth 1 -maxdepth 1 -type d | wc -l) + 1 )); run="$RUNNER/pipeline-$n"
  git clone -q -b "$br" "$REMOTE" "$run" 2>&1; f="$run/.gitlab-ci.yml"
  if ! ci_block "$f" workflow | ci_if_lines | rules_match "$src" "$br"; then
    rm -rf "$run"; echo "source: $src  ref: $br  commit: ${head:0:7}"; echo "no pipeline created (workflow rules)"; return 0; fi
  echo "pipeline #$n  source: $src  ref: $br  commit: ${head:0:7}"
  mapfile -t stages < <(ci_stages "$f"); echo "stages: ${stages[*]}"
  for st in "${stages[@]}"; do
    for j in $(ci_jobs "$f"); do
      [[ "$(ci_job_stage "$f" "$j")" == "$st" ]] || continue
      if ! ci_block "$f" "$j" | ci_if_lines | rules_match "$src" "$br"; then echo "job $j: not in this pipeline (rules)"; continue; fi
      if [[ $status == failed ]]; then echo "job $j: skipped (an earlier stage failed)"; continue; fi
      echo "job $j (stage $st):"
      if (cd "$run" && while read -r line; do echo "\$ $line"; bash -c "$line" || exit 1; done < <(ci_job_script "$f" "$j")); then echo "job $j: passed"; else echo "job $j: failed"; status=failed; fi
    done
  done
  echo "$status" > "$PIPES/$head"
  echo "pipeline #$n: $status"
}
# Records an approval for the merge request's latest commit. $1 = branch, $2 = approver name.
mr_approve() {
  local head; head="$(git -C "$REMOTE" rev-parse "refs/heads/$1")"; mkdir -p "$APPROVALS"
  echo "$2" >> "$APPROVALS/$head"; echo "$2 approved the merge request (commit ${head:0:7})"
}
# Simulates GitLab merge checks with "Pipelines must succeed". $1 = branch, $2 = Free|Premium, $3 = approvals required by a rule.
# On Free, approvals are optional; required approval rules need Premium or Ultimate. Returns 1 when merging is blocked.
mr_merge_check() {
  local br=$1 tier=$2 need=$3 head ps got ok=0
  head="$(git -C "$REMOTE" rev-parse "refs/heads/$br")"
  ps="$(cat "$PIPES/$head" 2>/dev/null || echo none)"; got=$( [[ -f "$APPROVALS/$head" ]] && wc -l < "$APPROVALS/$head" | tr -d ' ' || echo 0)
  echo "merge checks (tier: $tier) for ${head:0:7}"
  if [[ $ps == passed ]]; then echo "  pipeline: passed"; else echo "  pipeline: $ps (Pipelines must succeed)"; ok=1; fi
  if [[ $tier == Free ]]; then echo "  approvals: $got given, optional on Free"
  elif (( got >= need )); then echo "  approval rule: $got of $need required"
  else echo "  approval rule: $got of $need required"; ok=1; fi
  if (( ok )); then echo "Merge blocked"; return 1; fi; echo "Ready to merge"
}
# Basic structure checks for a .gitlab-ci.yml (no YAML library needed). Full validation: the CI Lint tool in GitLab (optional).
lint_gitlab_ci() {
  local f=$1 repo=$2 fail=0 j st s stages
  ok() { echo "PASS: $1"; }; ko() { echo "FAIL: $1"; fail=1; }
  if grep -q $'\t' "$f"; then ko "tab character on line $(grep -n $'\t' "$f" | head -1 | cut -d: -f1) (YAML indentation must use spaces)"; else ok "no tab characters"; fi
  stages=" $(ci_stages "$f" | tr '\n' ' ')"
  [[ -n "${stages// /}" ]] && ok "stages: $(echo $stages)" || ko "no stages: list"
  ci_block "$f" workflow | grep -q 'merge_request_event' && ok "pipelines run for merge requests" || ko "no merge_request_event rule"
  ci_block "$f" workflow | grep -q 'CI_DEFAULT_BRANCH' && ok "pipelines run on the default branch (after merge)" || ko "no default-branch rule"
  if grep -Eq '^\s*(runs-on|steps|uses):' "$f"; then ko "GitHub Actions keyword found (runs-on, steps or uses)"; else ok "no GitHub Actions keywords left"; fi
  for j in $(ci_jobs "$f"); do
    st="$(ci_job_stage "$f" "$j")"
    if [[ -z $st ]]; then ko "job $j has no stage"; elif [[ $stages == *" $st "* ]]; then ok "job $j: stage $st is listed in stages"; else ko "job $j: stage '$st' is not listed in stages"; fi
    [[ -n "$(ci_job_script "$f" "$j")" ]] && ok "job $j has a script" || ko "job $j has no script"
  done
  while read -r s; do [[ -f "$repo/$s" ]] && ok "script exists: $s" || ko "script not found: $s"; done < <(sed -nE 's/^ *- bash ([^ ]+).*/\1/p' "$f")
  if (( fail )); then echo "RESULT: FAIL"; return 1; fi; echo "RESULT: PASS"
}
# Structure checks for the OpenTofu component example. $1 = folder with .gitlab-ci.yml and backend.tf.
lint_tofu_example() {
  local d=$1 fail=0 f pin inver stages s
  ok() { echo "PASS: $1"; }; ko() { echo "FAIL: $1"; fail=1; }
  f="$d/.gitlab-ci.yml"
  grep -q 'component: .*components/opentofu/' "$f" && ok "includes the OpenTofu CI/CD component" || ko "OpenTofu component not included"
  pin="$(sed -nE 's#.*components/opentofu/[a-z-]+@([^ ]+) *$#\1#p' "$f")"
  if [[ $pin =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then ok "component pinned to release $pin"; else ko "component not pinned to a release (found '@${pin:-nothing}')"; fi
  inver="$(sed -nE 's/^ +version: *([^ ]+) *$/\1/p' "$f")"
  [[ -n $pin && $inver == "$pin" ]] && ok "inputs.version matches the pin" || ko "inputs.version ($inver) must equal the pinned version ($pin)"
  stages=" $(ci_stages "$f" | tr '\n' ' ')"
  if [[ $stages =~ \ validate\ (.*\ )?build\ (.*\ )?deploy\  ]]; then ok "stages validate, build, deploy (in order)"; else ko "stages must include validate, build, deploy in that order"; fi
  grep -Eq '^ *backend "http"' "$d/backend.tf" && ok "backend.tf uses the http backend (GitLab-managed state)" || ko "backend.tf has no http backend"
  if (( fail )); then echo "RESULT: FAIL"; return 1; fi; echo "RESULT: PASS"
}
