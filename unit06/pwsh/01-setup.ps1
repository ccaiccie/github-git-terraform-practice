# Builds the lab: a bare "server" repo (stand-in for GitHub), your laptop repo with Terraform code and three workflows,
# a simulated switch, and remote state. The switch and state start in sync with main (VLAN 10 and 20 already applied).
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (Test-Path -LiteralPath $Lab) { throw "$Lab already exists; refusing to overwrite. Run 99-cleanup.ps1 first." }
New-Item -ItemType Directory -Path (Join-Path $Lab 'server'), $Laptop, (Join-Path $Lab 'switch'), (Join-Path $Lab 'state'), $GH -Force | Out-Null
Set-Content -LiteralPath $Marker -Value $MarkerText -NoNewline
git init -q --bare -b main $Remote
Set-Location -LiteralPath $Laptop
git init -q -b main; Set-LabIdentity 'Lab Student' 'student@example.com'
Copy-Item -Path (Join-Path $Files 'repo' '*') -Destination . -Recurse -Force
Copy-Item -LiteralPath (Join-Path $Files 'repo' '.github') -Destination . -Recurse -Force
git add -A; git commit -q -m 'Add Terraform code and workflows'
git remote add origin $Remote; git push -q -u origin main 2>&1
Write-Switch @([pscustomobject]@{ Id = '10'; Name = 'USERS' }, [pscustomobject]@{ Id = '20'; Name = 'VOICE' })
Write-State @(Get-Desired (Join-Path $Laptop 'infra'))
Step 'git ls-files  (what the repository contains)'
git ls-files
Step 'The live switch (VLAN 10 and 20, applied earlier)'
Read-Text $Switch | ForEach-Object { Write-Host $_ }
