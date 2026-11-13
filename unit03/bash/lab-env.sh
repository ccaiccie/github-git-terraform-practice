#!/usr/bin/env bash
# Shared settings for the Unit 3 practice (sourced by every script).
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
set -euo pipefail
LAB_ROOT="${GIT_COURSE_LAB:-$HOME/git-course-lab}"
LAB="$LAB_ROOT/unit03"
REMOTE="$LAB/server/network-configs.git"   # plays the role of GitHub or GitLab
LAPTOP="$LAB/laptop/network-configs"       # your clone
COLLEAGUE="$LAB/colleague/network-configs" # a teammate's clone
MARKER="$LAB/.git-course-unit03"
MARKER_TEXT="git-course unit03 practice lab - safe to delete with 99-cleanup"
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
