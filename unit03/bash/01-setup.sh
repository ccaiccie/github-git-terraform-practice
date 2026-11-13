#!/usr/bin/env bash
# Builds the lab: a bare "server" repo (stand-in for GitHub/GitLab), your laptop clone with a baseline, and a colleague clone.
source "$(dirname "$0")/lab-env.sh"
if [[ -e "$LAB" ]]; then echo "ERROR: $LAB already exists; refusing to overwrite. Run 99-cleanup.sh first." >&2; exit 1; fi
mkdir -p "$LAB/server" "$LAPTOP"
printf '%s' "$MARKER_TEXT" > "$MARKER"
git init -q --bare -b main "$REMOTE"
cd "$LAPTOP"; git init -q -b main; lab_identity "Lab Student" "student@example.com"
mkdir -p configs; cp "$FILES/edge-router.cfg" configs/edge-router.cfg
printf '# network-configs\nDevice configurations for the lab network.\n' > README.md
git add README.md configs/edge-router.cfg; git commit -q -m "Add edge router baseline config"
git remote add origin "$REMOTE"; git push -q -u origin main 2>&1
git clone -q "$REMOTE" "$COLLEAGUE" 2>&1
cd "$COLLEAGUE"; lab_identity "Lab Colleague" "colleague@example.com"
step "Lab ready: server, laptop and colleague share one commit"
git -C "$LAPTOP" log --oneline --decorate --all
