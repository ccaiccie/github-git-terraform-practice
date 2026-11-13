#!/usr/bin/env bash
# Creates a local bare repository as the "remote", a first commit on your laptop repo, then connects and pushes.
source "$(dirname "$0")/lab-env.sh"
if [[ -e "$LAB" ]]; then echo "ERROR: $LAB already exists; refusing to overwrite. Run 99-cleanup.sh first." >&2; exit 1; fi
mkdir -p "$LAB/server" "$LAPTOP"
printf '%s' "$MARKER_TEXT" > "$MARKER"
step "git init --bare -b main  (the stand-in for GitHub: history only, no working files)"
git init --bare -b main "$REMOTE"
cd "$LAPTOP"
git init -q -b main
lab_identity "Lab Student" "student@example.com"
mkdir -p configs; cp "$FILES/edge-router.cfg" configs/edge-router.cfg
printf '# network-configs\nDevice configurations for the lab network.\n' > README.md
git add README.md configs/edge-router.cfg
git commit -q -m "Add edge router baseline config"
step "git remote add origin <url>"
git remote add origin "$REMOTE"
git remote -v
step "git push -u origin main"
git push -u origin main 2>&1
step "git branch -vv"
git branch -vv
step "git log --oneline --decorate --all"
git log --oneline --decorate --all
