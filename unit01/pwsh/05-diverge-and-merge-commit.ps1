# Both branches move on, so the merge needs a merge commit with two parents.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Step 'git switch -c update-ntp, change the config'
git switch -c update-ntp
$cfg = 'configs/edge-router.cfg'
$lines = foreach ($l in (Get-Content -LiteralPath $cfg)) { if ($l -eq 'ntp server 198.51.100.123') { 'ntp server 203.0.113.123' } else { $l } }
Write-Lf $cfg $lines
git commit -am 'Replace second NTP server'
Step 'Meanwhile on main, someone documents the repository'
git switch main
Write-Lf README.md 'Owner: network team. Change one device per branch.' -Append
git commit -am 'Document repository ownership'
Step 'git log --oneline --graph --all (history has diverged)'
git log --oneline --graph --all --decorate
Step 'git merge update-ntp (three-way merge creates a merge commit)'
git merge --no-edit update-ntp
git branch -d update-ntp
git log --oneline --graph --all --decorate
