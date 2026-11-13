# The colleague pushes a change. You fetch (download only), inspect, then pull (fetch + merge).
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Colleague
Write-Lf configs/edge-router.cfg @('vlan 20', ' name VOICE', '!') -Append
git commit -q -am 'Add VLAN 20 for voice'
Step 'colleague: git push'
git push
Set-Location -LiteralPath $Laptop
Step 'git fetch'
git fetch
Step 'git status'
git status
Step 'git log --oneline --graph --decorate --all'
git log --oneline --graph --decorate --all
Step 'git pull'
git pull
Step 'git status'
git status
