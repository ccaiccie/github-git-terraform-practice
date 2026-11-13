#!/usr/bin/env bash
# Builds the lab: a bare "server" repo (stand-in for GitHub), your laptop repo with Terraform code and three workflows,
# a simulated switch, and remote state. The switch and state start in sync with main (VLAN 10 and 20 already applied).
source "$(dirname "$0")/lab-env.sh"
if [[ -e "$LAB" ]]; then echo "ERROR: $LAB already exists; refusing to overwrite. Run 99-cleanup.sh first." >&2; exit 1; fi
mkdir -p "$LAB/server" "$LAPTOP" "$LAB/switch" "$LAB/state" "$GH"
printf '%s' "$MARKER_TEXT" > "$MARKER"
git init -q --bare -b main "$REMOTE"
cd "$LAPTOP"; git init -q -b main; lab_identity "Lab Student" "student@example.com"
cp -R "$FILES/repo/." .
git add -A; git commit -q -m "Add Terraform code and workflows"
git remote add origin "$REMOTE"; git push -q -u origin main 2>&1
printf '10 USERS\n20 VOICE\n' | sw_write
{ echo "# simulated state (real Terraform state is JSON)"; (cd infra && tf_desired); } > "$STATE"
step "git ls-files  (what the repository contains)"
git ls-files
step "The live switch (VLAN 10 and 20, applied earlier)"
cat "$SWITCH"
