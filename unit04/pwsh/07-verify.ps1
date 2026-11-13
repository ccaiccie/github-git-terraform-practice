# Verifies the finished lab.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
git -C $Laptop fetch -q --prune
$script:fail = $false
function Check([string]$Name, [scriptblock]$Test) { if (& $Test) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:fail = $true } }
$cfg = (git -C $Remote show main:configs/edge-router.cfg) -join "`n"
$first = git -C $Remote log --format=%H '--grep=^Add guest VLAN$' main
$fix = git -C $Remote log --format=%H '--grep=^Use VLAN 40 for guests$' main
$mainh = git -C $Remote rev-parse main
$st = { param($h) $f = Join-Path $Checks $h; if (Test-Path -LiteralPath $f) { (Get-Content -LiteralPath $f -Raw).Trim() } else { '' } }
Check 'main has the workflow file'          { git -C $Remote cat-file -e main:.github/workflows/config-check.yml; $LASTEXITCODE -eq 0 }
Check 'main has VLAN 40 named GUEST'        { $cfg -cmatch '(?m)^vlan 40$' -and $cfg -cmatch '(?m)^ name GUEST$' }
Check 'main has exactly one VLAN 10'        { ([regex]::Matches($cfg, '(?m)^vlan 10$')).Count -eq 1 }
Check 'first PR commit has a failed check'  { (& $st $first) -eq 'failure' }
Check 'fix commit has a successful check'   { (& $st $fix) -eq 'success' }
Check 'post-merge run on main succeeded'    { (& $st $mainh) -eq 'success' }
Check 'three workflow runs happened'        { @(Get-ChildItem -LiteralPath $Runner -Directory).Count -eq 3 }
Check 'one PR merge commit on main'         { @(git -C $Remote log --merges --oneline '--grep=^Merge pull request' main).Count -eq 1 }
Check 'only main is left on the server'     { (git -C $Remote for-each-ref '--format=%(refname:short)' refs/heads) -eq 'main' }
Check 'laptop working tree clean'           { -not (git -C $Laptop status --porcelain) }
Check 'origin URL is a local path'          { (git -C $Laptop remote get-url origin) -notmatch '^(https?|ssh|git)://|@' }
if ($script:fail) { Write-Host 'RESULT: FAIL'; exit 1 } else { Write-Host 'RESULT: PASS' }
