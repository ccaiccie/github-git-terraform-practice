# Creates a local bare repository as the "remote", a first commit on your laptop repo, then connects and pushes.
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (Test-Path -LiteralPath $Lab) { throw "$Lab already exists; refusing to overwrite. Run 99-cleanup.ps1 first." }
New-Item -ItemType Directory -Path (Join-Path $Lab 'server'), $Laptop -Force | Out-Null
Set-Content -LiteralPath $Marker -Value $MarkerText -NoNewline
Step 'git init --bare -b main  (the stand-in for GitHub: history only, no working files)'
git init --bare -b main $Remote
Set-Location -LiteralPath $Laptop
git init -q -b main
Set-LabIdentity 'Lab Student' 'student@example.com'
New-Item -ItemType Directory -Path configs -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $Files 'edge-router.cfg') -Destination configs/edge-router.cfg
Write-Lf README.md @('# network-configs', 'Device configurations for the lab network.')
git add README.md configs/edge-router.cfg
git commit -q -m 'Add edge router baseline config'
Step 'git remote add origin <url>'
git remote add origin $Remote
git remote -v
Step 'git push -u origin main'
git push -u origin main
Step 'git branch -vv'
git branch -vv
Step 'git log --oneline --decorate --all'
git log --oneline --decorate --all
