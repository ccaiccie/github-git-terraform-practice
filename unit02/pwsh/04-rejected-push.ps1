# Both sides commit. The colleague pushes first, so your push is rejected. Pull (merge), then push again.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Write-Lf README.md @('Owner: network team (netops@example.com)') -Append
git commit -q -am 'Document repository ownership'
Step 'git status  (after your local commit)'
git status
Set-Location -LiteralPath $Colleague
git pull -q
Write-Lf configs/edge-router.cfg @('ntp server 198.51.100.123') -Append
git commit -q -am 'Add second NTP server'
Step 'colleague: git push'
git push
Set-Location -LiteralPath $Laptop
Step 'git push  (expected to be rejected)'
$PSNativeCommandUseErrorActionPreference = $false
git push
$rejected = $LASTEXITCODE -ne 0
$PSNativeCommandUseErrorActionPreference = $true
if (-not $rejected) { throw 'UNEXPECTED: push was accepted' }
Step 'git pull --no-edit'
git pull --no-edit
Step 'git push'
git push
Step 'git log --oneline --graph --decorate --all'
git log --oneline --graph --decorate --all
