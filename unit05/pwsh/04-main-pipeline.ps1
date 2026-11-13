# The merge updates main, so a branch pipeline runs on main: stage test, then stage report. Then clean up the branch.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Push to main: pipeline on the default branch (source push)'
Invoke-Pipeline push main
Step 'Delete the merged branch'
git push -q origin --delete move-to-gitlab-ci 2>&1
git branch -d move-to-gitlab-ci 2>&1
Step 'History on main'
git log --oneline --graph -3
