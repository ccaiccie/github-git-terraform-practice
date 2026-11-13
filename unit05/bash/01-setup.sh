#!/usr/bin/env bash
# Builds the lab: a bare "server" repo (stand-in for GitLab) and your laptop repo with the Unit 4 files: configs, check script, GitHub workflow.
source "$(dirname "$0")/lab-env.sh"
if [[ -e "$LAB" ]]; then echo "ERROR: $LAB already exists; refusing to overwrite. Run 99-cleanup.sh first." >&2; exit 1; fi
mkdir -p "$LAB/server" "$LAPTOP"
printf '%s' "$MARKER_TEXT" > "$MARKER"
git init -q --bare -b main "$REMOTE"
cd "$LAPTOP"; git init -q -b main; lab_identity "Lab Student" "student@example.com"
cp -R "$FILES/repo/." .
git add -A; git commit -q -m "Add configs, check script and GitHub workflow"
git remote add origin "$REMOTE"; git push -q -u origin main 2>&1
step "git ls-files  (what the repository contains)"
git ls-files
