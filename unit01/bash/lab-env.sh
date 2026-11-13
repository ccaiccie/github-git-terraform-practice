#!/usr/bin/env bash
# Shared settings for the Unit 1 practice (sourced by every script).
# Everything happens inside one throwaway folder. Nothing is pushed anywhere.
set -euo pipefail
LAB_ROOT="${GIT_COURSE_LAB:-$HOME/git-course-lab}"
LAB="$LAB_ROOT/unit01"
REPO="$LAB/network-configs"
MARKER="$LAB/.git-course-unit01"
MARKER_TEXT="git-course unit01 practice lab - safe to delete with 99-cleanup"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="$HERE/../files"
need_lab() {
  if [[ ! -f "$MARKER" ]] || [[ "$(cat "$MARKER")" != "$MARKER_TEXT" ]]; then
    echo "ERROR: lab not found at $LAB (run 01-create-lab.sh first)." >&2; exit 1
  fi
  cd "$REPO"
}
step() { printf '\n== %s ==\n' "$*"; }
