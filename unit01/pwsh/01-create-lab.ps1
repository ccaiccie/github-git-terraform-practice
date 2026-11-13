# Creates a brand-new local repository in a throwaway folder and sets a lab-only identity.
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (Test-Path -LiteralPath $Lab) { throw "$Lab already exists; refusing to overwrite. Run 99-cleanup.ps1 first." }
New-Item -ItemType Directory -Path $Repo -Force | Out-Null
Set-Content -LiteralPath $Marker -Value $MarkerText -NoNewline
Set-Location -LiteralPath $Repo
Step 'git init -b main'
git init -b main
Step 'Identity for this lab repository only (your global Git settings are not touched)'
git config --local user.name  'Lab Student'
git config --local user.email 'student@example.com'
git config --local core.autocrlf false
git config --local user.name; git config --local user.email
Step 'git status'
git status
