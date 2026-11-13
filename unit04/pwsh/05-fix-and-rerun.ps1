# Push a fix to the same branch: the workflow runs again on the new commit, the check turns green, the merge is allowed.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Fix: use VLAN 40 for guests, commit, push to the same branch'
Write-Lf configs/edge-router.cfg (@(git show main:configs/edge-router.cfg) + @('vlan 40', ' name GUEST', '!'))
git commit -q -am 'Use VLAN 40 for guests'
git push 2>&1
Step 'New commit on the pull request: the workflow runs again (pull_request, synchronize)'
Invoke-CiRun pull_request add-vlan-40
Step 'Try to merge pull request #1 again'
if (-not (Test-MergeGate add-vlan-40)) { throw 'Merge still blocked' }
Step 'Merge pull request #1 into main'
git switch -q main
git pull -q 2>&1
git merge -q --no-ff add-vlan-40 -m 'Merge pull request #1 from add-vlan-40'
git push 2>&1
