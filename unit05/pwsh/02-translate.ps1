# Translate the Unit 4 GitHub workflow into a .gitlab-ci.yml, check its structure, fix the mistake the check finds, commit.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Branch move-to-gitlab-ci: add a first translation of the workflow'
git switch -c move-to-gitlab-ci 2>&1
Copy-Item -LiteralPath (Join-Path $Files 'gitlab' 'starter.gitlab-ci.yml') -Destination .gitlab-ci.yml
Step 'Lint the first translation (expected to fail)'
if (Test-GitLabCi .gitlab-ci.yml .) { throw 'UNEXPECTED: the first translation passed' }
Step 'Fix: the validate job belongs to stage test'
Set-Line .gitlab-ci.yml '  stage: check' '  stage: test'
if (-not (Test-GitLabCi .gitlab-ci.yml .)) { exit 1 }
Step 'Commit and push the branch'
git add .gitlab-ci.yml; git commit -q -m 'Add GitLab CI/CD pipeline'
git push -q -u origin move-to-gitlab-ci 2>&1
git log --oneline -1
