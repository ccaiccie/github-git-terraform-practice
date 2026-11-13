# Pushes a new feature branch: the step right before opening a pull request (Unit 3).
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'git switch -c add-vlan-30'
git switch -c add-vlan-30
Write-Lf configs/edge-router.cfg @('vlan 30', ' name CAMERAS', '!') -Append
git commit -q -am 'Add VLAN 30 for cameras'
Step 'git push -u origin add-vlan-30'
git push -u origin add-vlan-30
Step 'git branch -vv'
git branch -vv
Step 'git branch -r'
git branch -r
Step 'git switch main'
git switch main
