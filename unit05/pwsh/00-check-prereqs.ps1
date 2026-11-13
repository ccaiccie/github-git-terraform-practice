# Checks that Git is installed and new enough (2.28+ for "git init -b", 2.23+ for "git switch").
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host 'FAIL: git is not installed or not on PATH'; exit 1 }
$raw = (git --version)
Write-Host "Found: $raw"
if ($raw -notmatch 'git version (\d+)\.(\d+)') { Write-Host 'FAIL: could not read the Git version'; exit 1 }
$major = [int]$Matches[1]; $minor = [int]$Matches[2]
if ($major -gt 2 -or ($major -eq 2 -and $minor -ge 28)) { Write-Host "PASS: Git $major.$minor is new enough (need 2.28 or later)" }
else { Write-Host "FAIL: Git $major.$minor is too old (need 2.28 or later)"; exit 1 }
Write-Host "Lab folder will be: $Lab"
if (Test-Path -LiteralPath $Lab) { Write-Host "NOTE: $Lab already exists. Run 99-cleanup.ps1 first if it is an old lab." }
