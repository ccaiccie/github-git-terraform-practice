#!/usr/bin/env bash
# Checks that Git is installed and new enough (2.28+ for "git init -b").
source "$(dirname "$0")/lab-env.sh"
if ! command -v git >/dev/null 2>&1; then echo "FAIL: git is not installed or not on PATH"; exit 1; fi
ver="$(git --version | sed -E 's/^git version ([0-9]+)\.([0-9]+).*/\1 \2/')"
read -r major minor <<<"$ver"
echo "Found: $(git --version)"
if (( major > 2 || (major == 2 && minor >= 28) )); then echo "PASS: Git $major.$minor is new enough (need 2.28 or later)"
else echo "FAIL: Git $major.$minor is too old (need 2.28 or later)"; exit 1; fi
echo "Lab folder will be: $LAB"
if [[ -e "$LAB" ]]; then echo "NOTE: $LAB already exists. Run 99-cleanup.sh first if it is an old lab."; fi
