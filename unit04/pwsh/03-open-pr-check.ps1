# A pull request with a mistake: the simulated workflow run fails, so the check is red.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Branch add-vlan-40 with a mistake: the guest VLAN reuses ID 10'
git switch -c add-vlan-40 2>&1
Write-Lf configs/edge-router.cfg @('vlan 10', ' name GUEST', '!') -Append
git commit -q -am 'Add guest VLAN'
git push -q -u origin add-vlan-40 2>&1
git log --oneline -1
Step 'Pull request opened: the workflow runs (event pull_request)'
Invoke-CiRun pull_request add-vlan-40
