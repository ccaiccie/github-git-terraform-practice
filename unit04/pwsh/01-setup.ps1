# Builds the lab: a bare "server" repo (stand-in for GitHub) and your laptop repo with configs, a check script and a workflow file.
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (Test-Path -LiteralPath $Lab) { throw "$Lab already exists; refusing to overwrite. Run 99-cleanup.ps1 first." }
New-Item -ItemType Directory -Path (Join-Path $Lab 'server'), $Laptop -Force | Out-Null
Set-Content -LiteralPath $Marker -Value $MarkerText -NoNewline
git init -q --bare -b main $Remote
Set-Location -LiteralPath $Laptop
git init -q -b main; Set-LabIdentity 'Lab Student' 'student@example.com'
Copy-Item -Path (Join-Path $Files 'repo' '*') -Destination . -Recurse -Force
Copy-Item -LiteralPath (Join-Path $Files 'repo' '.github') -Destination . -Recurse -Force
git add -A; git commit -q -m 'Add configs, check script and workflow'
git remote add origin $Remote; git push -q -u origin main 2>&1
Step 'git ls-files  (what the repository contains)'
git ls-files
