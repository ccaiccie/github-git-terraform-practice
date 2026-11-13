# After merging: delete the branches (server and local), switch to main, pull, prune stale remote-tracking branches.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step "git push origin --delete add-vlan-30 change-ntp  (GitHub's Delete branch button)"
git push origin --delete add-vlan-30 change-ntp 2>&1
Step 'git switch main && git pull'
git switch main 2>&1
git pull 2>&1
Step 'git branch -d add-vlan-30 change-ntp'
git branch -d add-vlan-30 change-ntp 2>&1
Step "In the colleague's clone: git fetch --prune"
Set-Location -LiteralPath $Colleague
git pull -q 2>&1
git fetch --prune 2>&1
git branch -a
