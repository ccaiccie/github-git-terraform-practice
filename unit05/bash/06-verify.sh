#!/usr/bin/env bash
# Verifies the finished lab.
source "$(dirname "$0")/lab-env.sh"; need_lab
git -C "$LAPTOP" fetch -q --prune
fail=0; check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
br="$(git -C "$REMOTE" log --format=%H --grep='^Add GitLab CI/CD pipeline$' main)"
mainh="$(git -C "$REMOTE" rev-parse main)"
CI() { git -C "$REMOTE" show main:.gitlab-ci.yml; }
check "main has .gitlab-ci.yml"                      'git -C "$REMOTE" cat-file -e main:.gitlab-ci.yml'
check "main still has the GitHub workflow"           'git -C "$REMOTE" cat-file -e main:.github/workflows/config-check.yml'
check "validate job is in stage test"                'CI | grep -q "^  stage: test$"'
check "merge request pipeline passed"                '[[ "$(cat "$PIPES/$br" 2>/dev/null)" == passed ]]'
check "one approval recorded"                        '[[ "$(wc -l < "$APPROVALS/$br" 2>/dev/null | tr -d " ")" == 1 ]]'
check "pipeline on main passed"                      '[[ "$(cat "$PIPES/$mainh" 2>/dev/null)" == passed ]]'
check "two pipelines ran (MR, then main)"         '[[ "$(find "$RUNNER" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d " ")" == 2 ]]'
check "one MR merge commit on main"                  '[[ "$(git -C "$REMOTE" log --merges --oneline --grep="^Merge branch .move-to-gitlab-ci. into .main.$" main | wc -l | tr -d " ")" == 1 ]]'
check "only main is left on the server"              '[[ "$(git -C "$REMOTE" for-each-ref --format="%(refname:short)" refs/heads)" == main ]]'
check "laptop working tree clean"                    '[[ -z "$(git -C "$LAPTOP" status --porcelain)" ]]'
check "origin URL is a local path"                   '! git -C "$LAPTOP" remote get-url origin | grep -Eq "^(https?|ssh|git)://|@"'
if (( fail )); then echo "RESULT: FAIL"; exit 1; else echo "RESULT: PASS"; fi
