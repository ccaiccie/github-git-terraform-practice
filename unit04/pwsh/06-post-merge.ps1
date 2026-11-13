# The merge is a push to main, so the same workflow runs once more on main, including the report step. Then clean up.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Push to main: the workflow runs on main (event push)'
Invoke-CiRun push main
Step 'Delete the merged branch'
git push -q origin --delete add-vlan-40 2>&1
git branch -d add-vlan-40 2>&1
Step 'History on main'
git log --oneline --graph -4
