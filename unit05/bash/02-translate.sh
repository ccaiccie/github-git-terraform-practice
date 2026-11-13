#!/usr/bin/env bash
# Translate the Unit 4 GitHub workflow into a .gitlab-ci.yml, check its structure, fix the mistake the check finds, commit.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
step "Branch move-to-gitlab-ci: add a first translation of the workflow"
git switch -c move-to-gitlab-ci 2>&1
cp "$FILES/gitlab/starter.gitlab-ci.yml" .gitlab-ci.yml
step "Lint the first translation (expected to fail)"
if lint_gitlab_ci .gitlab-ci.yml .; then echo "UNEXPECTED: the first translation passed" >&2; exit 1; fi
step "Fix: the validate job belongs to stage test"
replace_line .gitlab-ci.yml "  stage: check" "  stage: test"
lint_gitlab_ci .gitlab-ci.yml .
step "Commit and push the branch"
git add .gitlab-ci.yml; git commit -q -m "Add GitLab CI/CD pipeline"
git push -q -u origin move-to-gitlab-ci 2>&1
git log --oneline -1
