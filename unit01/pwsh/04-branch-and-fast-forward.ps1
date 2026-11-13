# Creates a branch, commits on it, and merges it back with a fast-forward.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Step 'git switch -c add-vlan-20'
git switch -c add-vlan-20
Write-Lf configs/edge-router.cfg '!', 'vlan 20', ' name VOICE' -Append
git add configs/edge-router.cfg
git commit -m 'Add VLAN 20 for voice'
Step 'git log --oneline --graph --all (main has not moved)'
git log --oneline --graph --all --decorate
Step 'git switch main, then git merge add-vlan-20'
git switch main
git merge add-vlan-20
Step 'git branch -d add-vlan-20 (the label goes; the commits stay)'
git branch -d add-vlan-20
git log --oneline --graph --all --decorate
