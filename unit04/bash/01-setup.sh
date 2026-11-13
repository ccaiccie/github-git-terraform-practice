#!/usr/bin/env bash
# Builds the lab: a bare "server" repo (stand-in for GitHub) and your laptop repo with configs, a check script and a workflow file.
source "$(dirname "$0")/lab-env.sh"
if [[ -e "$LAB" ]]; then echo "ERROR: $LAB already exists; refusing to overwrite. Run 99-cleanup.sh first." >&2; exit 1; fi
mkdir -p "$LAB/server" "$LAPTOP"
printf '%s' "$MARKER_TEXT" > "$MARKER"
git init -q --bare -b main "$REMOTE"
cd "$LAPTOP"; git init -q -b main; lab_identity "Lab Student" "student@example.com"
cp -R "$FILES/repo/." .
git add -A; git commit -q -m "Add configs, check script and workflow"
git remote add origin "$REMOTE"; git push -q -u origin main 2>&1
step "git ls-files  (what the repository contains)"
git ls-files
