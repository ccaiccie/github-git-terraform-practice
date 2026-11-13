# Changes a tracked file, inspects the difference, commits, and adds a .gitignore.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
$cfg = 'configs/edge-router.cfg'
$lines = foreach ($l in (Get-Content -LiteralPath $cfg)) { $l; if ($l -eq 'ntp server 192.0.2.123') { 'ntp server 198.51.100.123' } }
Write-Lf $cfg $lines
Step 'git diff (what changed but is not staged yet)'
git --no-pager diff
git add $cfg
git commit -m 'Add second NTP server'
Step '.gitignore keeps secrets and clutter out'
Copy-Item -LiteralPath (Join-Path $Files 'gitignore-example') -Destination .gitignore
New-Item -ItemType Directory -Path secrets -Force | Out-Null
Write-Lf secrets/enable.key 'enable-secret-placeholder'
git status --short
git add .gitignore
git commit -m 'Ignore secrets, backups and editor files'
Step 'git log --oneline'
git log --oneline --decorate
