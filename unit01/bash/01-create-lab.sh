#!/usr/bin/env bash
# Creates a brand-new local repository in a throwaway folder and sets a lab-only identity.
source "$(dirname "$0")/lab-env.sh"
if [[ -e "$LAB" ]]; then echo "ERROR: $LAB already exists; refusing to overwrite. Run 99-cleanup.sh first." >&2; exit 1; fi
mkdir -p "$REPO"
printf '%s' "$MARKER_TEXT" > "$MARKER"
cd "$REPO"
step "git init -b main"
git init -b main
step "Identity for this lab repository only (your global Git settings are not touched)"
git config --local user.name  "Lab Student"
git config --local user.email "student@example.com"
git config --local core.autocrlf false
git config --local user.name; git config --local user.email
step "git status"
git status
