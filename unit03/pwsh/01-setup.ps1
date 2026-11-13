# Builds the lab: a bare "server" repo (stand-in for GitHub/GitLab), your laptop clone with a baseline, and a colleague clone.
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (Test-Path -LiteralPath $Lab) { throw "$Lab already exists; refusing to overwrite. Run 99-cleanup.ps1 first." }
New-Item -ItemType Directory -Path (Join-Path $Lab 'server'), $Laptop -Force | Out-Null
Set-Content -LiteralPath $Marker -Value $MarkerText -NoNewline
git init -q --bare -b main $Remote
Set-Location -LiteralPath $Laptop
git init -q -b main; Set-LabIdentity 'Lab Student' 'student@example.com'
New-Item -ItemType Directory -Path configs -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $Files 'edge-router.cfg') -Destination configs/edge-router.cfg
Write-Lf README.md @('# network-configs', 'Device configurations for the lab network.')
git add README.md configs/edge-router.cfg; git commit -q -m 'Add edge router baseline config'
git remote add origin $Remote; git push -q -u origin main 2>&1
git clone -q $Remote $Colleague 2>&1
Set-Location -LiteralPath $Colleague; Set-LabIdentity 'Lab Colleague' 'colleague@example.com'
Step 'Lab ready: server, laptop and colleague share one commit'
git -C $Laptop log --oneline --decorate --all
