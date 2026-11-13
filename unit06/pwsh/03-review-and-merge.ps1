# The reviewer reads the plan comment, the required check has passed, so the pull request is merged.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'The plan comment on pull request #1 (what the reviewer reads)'
Read-Text (Join-Path $GH "pr-comment-$(Get-Head add-vlan-30).md") | ForEach-Object { Write-Host $_ }
Step 'Merge checks'
if (-not (Test-MergeGate add-vlan-30)) { throw 'Merge blocked' }
Step 'Merge pull request #1 into main'
git switch -q main
git pull -q 2>&1
git merge -q --no-ff add-vlan-30 -m 'Merge pull request #1 from add-vlan-30'
git push 2>&1
git push -q origin --delete add-vlan-30 2>&1; git branch -q -d add-vlan-30
