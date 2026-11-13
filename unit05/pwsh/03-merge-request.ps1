# A push alone creates no pipeline (workflow rules); the merge request does. Then GitLab merge checks: Free versus a Premium approval rule.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Branch push without a merge request (source push)'
Invoke-Pipeline push move-to-gitlab-ci
Step 'Merge request !1 opened: merge request pipeline (source merge_request_event)'
Invoke-Pipeline merge_request_event move-to-gitlab-ci
Step 'Merge checks on GitLab Free'
if (-not (Test-MergeChecks move-to-gitlab-ci Free 0)) { throw 'UNEXPECTED: blocked on Free' }
Step 'Merge checks with a Premium approval rule (1 approval required)'
if (Test-MergeChecks move-to-gitlab-ci Premium 1) { throw 'UNEXPECTED: merge allowed without approval' }
Step 'A reviewer approves, then the checks run again'
Add-Approval move-to-gitlab-ci 'Network Lead'
if (-not (Test-MergeChecks move-to-gitlab-ci Premium 1)) { throw 'Merge still blocked' }
Step 'Merge !1 into main'
git switch -q main
git pull -q 2>&1
git merge -q --no-ff move-to-gitlab-ci -m "Merge branch 'move-to-gitlab-ci' into 'main'"
git push 2>&1
