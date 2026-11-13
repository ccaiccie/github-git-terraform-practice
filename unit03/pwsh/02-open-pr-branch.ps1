# The work behind a pull request: a feature branch with two commits, pushed, then read the way a PR shows it.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'git switch -c add-vlan-30'
git switch -c add-vlan-30 2>&1
Write-Lf configs/edge-router.cfg @('vlan 30', ' name CAMERA', '!') -Append
git commit -q -am 'Add VLAN 30 for cameras'
Set-Line configs/edge-router.cfg ' name CAMERA' ' name CAMERAS'
git commit -q -am 'Fix VLAN 30 name'
Step 'git push -u origin add-vlan-30'
git push -u origin add-vlan-30 2>&1
Step "git log --oneline main..add-vlan-30  (the PR's commits)"
git log --oneline main..add-vlan-30
Step "git diff main...add-vlan-30  (the PR's Files changed tab)"
git --no-pager diff main...add-vlan-30
