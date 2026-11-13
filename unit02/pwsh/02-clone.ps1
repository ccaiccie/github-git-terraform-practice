# A colleague clones the shared repository: full history, origin preset, main tracking origin/main.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
if (Test-Path -LiteralPath $Colleague) { throw "$Colleague already exists." }
Step 'git clone <url>'
git clone $Remote $Colleague
Set-Location -LiteralPath $Colleague
Set-LabIdentity 'Lab Colleague' 'colleague@example.com'
Step 'git remote -v'
git remote -v
Step 'git branch -vv'
git branch -vv
Step 'git log --oneline --decorate --all'
git log --oneline --decorate --all
