#!/usr/bin/env bash
# Checks the workflow file's structure locally, then shows the same check catching a broken copy.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Lint .github/workflows/config-check.yml"
lint_workflow .github/workflows/config-check.yml .
step "Lint a broken copy (a tab in front of runs-on; expected to fail)"
broken="$LAB/broken-workflow.yml"
sed $'s/^    runs-on:/\truns-on:/' .github/workflows/config-check.yml > "$broken"
if lint_workflow "$broken" .; then echo "UNEXPECTED: the broken copy passed" >&2; exit 1; fi
rm -f "$broken"
step "Run the check script locally, like the workflow will"
bash scripts/check-configs.sh configs
