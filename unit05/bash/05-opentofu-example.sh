#!/usr/bin/env bash
# Structure check of the OpenTofu component example (GitLab-managed state). Nothing is run, nothing contacts GitLab.
source "$(dirname "$0")/lab-env.sh"; need_lab
ex="$FILES/gitlab/opentofu-example"
step "The example pipeline"
cat "$ex/.gitlab-ci.yml"
step "Lint the example"
lint_tofu_example "$ex"
step "Lint a copy that follows ~latest (expected to fail)"
bad="$LAB/tofu-latest"; mkdir -p "$bad"; cp "$ex/backend.tf" "$bad/"
sed 's/@5\.1\.0$/@~latest/' "$ex/.gitlab-ci.yml" > "$bad/.gitlab-ci.yml"
if lint_tofu_example "$bad"; then echo "UNEXPECTED: unpinned copy passed" >&2; exit 1; fi
rm -rf "$bad"
