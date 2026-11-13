#!/usr/bin/env bash
# Shared settings for the Unit 6 practice (sourced by every script).
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
set -euo pipefail
LAB_ROOT="${GIT_COURSE_LAB:-$HOME/git-course-lab}"
LAB="$LAB_ROOT/unit06"
REMOTE="$LAB/server/network-configs.git"   # plays the role of GitHub
LAPTOP="$LAB/laptop/network-configs"       # your clone
COLLEAGUE="$LAB/colleague/network-configs" # a teammate's clone
MARKER="$LAB/.git-course-unit06"
MARKER_TEXT="git-course unit06 practice lab - safe to delete with 99-cleanup"
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
SWITCH="$LAB/switch/running-config"     # the live network: the lab switch's VLAN config
STATE="$LAB/state/terraform.tfstate"     # remote state (simulated; real Terraform state is JSON)
LOCK="$LAB/state/terraform.tfstate.lock" # state lock
GH="$LAB/github"                         # what GitHub would show: checks, PR comments, issues, pending runs
RUNNER="$LAB/runner"                     # each simulated workflow run gets a fresh clone here
# ---------- tfsim: a tiny stand-in for terraform, for the lab_vlan resource only ----------
tf_desired() { # *.tf in the current folder -> "address id name" lines
  awk '/^resource "lab_vlan" "[a-z0-9_]+" \{/ { gsub(/"/, "", $3); a = "lab_vlan." $3; id = ""; nm = ""; next }
       a != "" && /^  vlan_id *= *[0-9]+ *$/ { id = $3; next }
       a != "" && /^  name *= *"[^"]*" *$/ { nm = $0; sub(/^[^"]*"/, "", nm); sub(/".*$/, "", nm); next }
       a != "" && /^}/ { print a, (id == "" ? "-" : id), (nm == "" ? "-" : nm); a = "" }' *.tf
}
sw_vlans() { awk '/^vlan [0-9]+$/ { id = $2 } /^ name / { print id, $2 }' "$SWITCH"; }
sw_name() { sw_vlans | awk -v i="$1" '$1 == i { print $2; f = 1 } END { if (!f) print "" }'; }
sw_write() { # stdin = "id name" lines -> running-config, sorted by VLAN ID
  sort -n | awk '{ print "vlan " $1; print " name " $2; print "!" }' > "$SWITCH.tmp" && mv "$SWITCH.tmp" "$SWITCH"
}
tf_validate() {
  local d err=0; d="$(tf_desired)"
  while read -r a id nm; do
    [[ -z $a ]] && continue
    if [[ $id == - ]] || (( id < 1 || id > 4094 )); then echo "Error: $a: vlan_id must be 1-4094"; err=1; fi
    [[ $nm == - ]] && { echo "Error: $a: name is required"; err=1; }
  done <<<"$d"
  local dup; dup="$(awk '{ print $2 }' <<<"$d" | sort | uniq -d | head -1)"
  [[ -n $dup ]] && { echo "Error: vlan_id $dup is used by more than one resource"; err=1; }
  (( err )) && return 1; echo "Success! The configuration is valid."
}
# tfsim plan [-detailed-exitcode] | tfsim apply. Prints a Terraform-style plan. Exit: 0, 1 = error, 2 = changes (-detailed-exitcode).
tf_run() {
  local mode=$1 detailed=${2:-} d s line a id nm cur add=0 chg=0 del=0 drift="" acts=""
  if [[ -f $LOCK ]]; then echo "Error: Error acquiring the state lock"; echo "Lock Info: held by $(cat "$LOCK")"; return 1; fi
  tf_validate >/dev/null || { tf_validate; return 1; }
  d="$(tf_desired)"; s=""
  [[ -f $STATE ]] && s="$(grep '^lab_vlan\.' "$STATE" || true)"
  local refreshed=""
  while read -r a id nm; do # refresh: read the live switch for every object in state
    [[ -z $a ]] && continue; cur="$(sw_name "$id")"
    if [[ -z $cur ]]; then drift+="  # $a has been deleted"$'\n'
    else [[ $cur != "$nm" ]] && drift+="  # $a has changed"$'\n'"  ~ name: \"$nm\" -> \"$cur\""$'\n'; refreshed+="$a $id $cur"$'\n'; fi
  done <<<"$s"
  while read -r a id nm; do
    [[ -z $a ]] && continue; line="$(awk -v a="$a" '$1 == a' <<<"$refreshed")"
    if [[ -z $line ]]; then acts+="  # $a will be created"$'\n'"  + vlan_id = $id, name = \"$nm\""$'\n'; add=$((add + 1))
    else cur="$(awk '{ print $3 }' <<<"$line")"; [[ $cur != "$nm" ]] && { acts+="  # $a will be updated in-place"$'\n'"  ~ name = \"$cur\" -> \"$nm\""$'\n'; chg=$((chg + 1)); }; fi
  done <<<"$d"
  while read -r a id nm; do
    [[ -z $a ]] && continue; awk -v a="$a" '$1 == a { f = 1 } END { exit !f }' <<<"$d" || { acts+="  # $a will be destroyed"$'\n'"  - vlan_id = $id"$'\n'; del=$((del + 1)); }
  done <<<"$refreshed"
  [[ -n $drift ]] && { echo "Note: Objects have changed outside of Terraform"; printf '%s' "$drift"; }
  if [[ -z $acts ]]; then echo "No changes. Your infrastructure matches the configuration."
  else echo "Terraform will perform the following actions:"; printf '%s' "$acts"; echo "Plan: $add to add, $chg to change, $del to destroy."; fi
  if [[ $mode == apply ]]; then
    echo "${USER:-runner}@runner" > "$LOCK"
    { sw_vlans | while read -r id nm; do # keep VLANs that Terraform does not manage
        awk -v i="$id" '$2 == i { f = 1 } END { exit !f }' <<<"$s" || echo "$id $nm"; done
      awk '{ print $2, $3 }' <<<"$d"; } | sw_write
    { echo "# simulated state (real Terraform state is JSON)"; printf '%s\n' "$d"; } > "$STATE"
    rm -f "$LOCK"; echo "Apply complete! Resources: $add added, $chg changed, $del destroyed."; return 0
  fi
  [[ -n $acts && $detailed == -detailed-exitcode ]] && return 2; return 0
}
tfsim() { case "$1" in validate) tf_validate ;; plan) tf_run plan "${2:-}" ;; apply) tf_run apply ;; *) echo "tfsim: unknown command $1" >&2; return 1 ;; esac; }
# ---------- simulated GitHub Actions runs ----------
new_run() { # $1 = workflow, $2 = event, $3 = branch -> prints the run folder
  local n; mkdir -p "$RUNNER" "$GH/checks"; n=$(( $(find "$RUNNER" -mindepth 1 -maxdepth 1 -type d | wc -l) + 1 ))
  git clone -q -b "$3" "$REMOTE" "$RUNNER/run-$n" >/dev/null 2>&1; echo "$RUNNER/run-$n"
}
run_head() { git -C "$REMOTE" rev-parse --short=7 "refs/heads/$1"; }
# terraform-plan on a pull request: test-merge into main, validate, plan, post the plan as a PR comment.
wf_plan() {
  local br=$1 run head code; head="$(run_head "$br")"; run="$(new_run terraform-plan pull_request main)"
  git -C "$run" -c user.name=runner -c user.email=runner@example.com merge -q --no-ff --no-edit "origin/$br" >/dev/null
  echo "run #${run##*-}  workflow: terraform-plan  event: pull_request  commit: $head"
  code=0; (cd "$run/infra" && say "terraform validate" && tfsim validate && say "terraform plan" && tfsim plan > "$run/plan.txt") || code=$?
  [[ -f $run/plan.txt ]] && cat "$run/plan.txt"
  if (( code == 0 )); then
    { echo "### terraform plan for $head"; cat "$run/plan.txt"; } > "$GH/pr-comment-$head.md"
    echo "comment posted on the pull request"; echo success > "$GH/checks/$head"
  else echo failure > "$GH/checks/$head"; fi
  echo "check terraform-plan / plan: $(cat "$GH/checks/$head")"
}
merge_gate() {
  local head st; head="$(run_head "$1")"; st="$(cat "$GH/checks/$head" 2>/dev/null || echo pending)"
  echo "required check terraform-plan / plan on $head: $st"
  [[ $st == success ]] && { echo "Merge allowed"; return 0; }; echo "Merging is blocked"; return 1
}
# terraform-apply: starts on push to main (or by hand), then waits for the production environment review.
wf_apply_start() {
  local ev=${1:-push} run; run="$(new_run terraform-apply "$ev" main)"
  echo "run #${run##*-}  workflow: terraform-apply  event: $ev  commit: $(run_head main)"
  echo "$run" > "$GH/pending-apply"; echo "job apply is waiting for review: environment production"
}
wf_apply_job() { # runs the pending apply job (after approval, or as a re-run)
  local run code; run="$(cat "$GH/pending-apply")"
  [[ -f $run.approved ]] || { echo "job apply is still waiting for review"; return 1; }
  echo "job apply (run #${run##*-}):"; say "terraform apply -auto-approve"
  code=0; (cd "$run/infra" && tfsim apply) || code=$?
  if (( code == 0 )); then rm -f "$GH/pending-apply"; echo "job apply: success"; else echo "job apply: failure"; fi
  return 0
}
wf_apply_approve() { local run; run="$(cat "$GH/pending-apply")"; echo "$1" > "$run.approved"; echo "$1 approved the deployment to production"; wf_apply_job; }
# terraform-drift: scheduled plan with -detailed-exitcode on main. Exit 2 = drift: open an issue.
wf_drift() {
  local run code n; run="$(new_run terraform-drift schedule main)"
  echo "run #${run##*-}  workflow: terraform-drift  event: schedule  commit: $(run_head main)"
  say "terraform plan -detailed-exitcode"
  code=0; (cd "$run/infra" && tfsim plan -detailed-exitcode > "$run/plan.txt") || code=$?
  cat "$run/plan.txt"; echo "plan exit code: $code"; echo "$code" > "$GH/last-drift-exit"
  case $code in
    0) echo "No drift." ;;
    2) mkdir -p "$GH/issues"; n=$(( $(find "$GH/issues" -name '*.md' | wc -l) + 1 ))
       { echo "# Drift detected"; cat "$run/plan.txt"; } > "$GH/issues/$n.md"; echo "issue #$n opened: Drift detected" ;;
    *) echo "drift check failed (error)" ;;
  esac
}
