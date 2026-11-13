# Adds the first files, shows the three states and records the first commit.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
New-Item -ItemType Directory -Path configs -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $Files 'edge-router.cfg') -Destination configs/edge-router.cfg
Write-Lf README.md '# network-configs', 'Version-controlled device configurations for the lab.'
Step 'git status (untracked files)'
git status --short
Step 'git add (stage the files)'
git add README.md configs/edge-router.cfg
git status --short
Step 'git commit'
git commit -m 'Add edge router baseline config'
Step 'git log --oneline'
git log --oneline --decorate
