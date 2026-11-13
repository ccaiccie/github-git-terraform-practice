# Verifies the finished lab.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
git -C $Laptop fetch -q --prune; git -C $Colleague fetch -q --prune
$script:fail = $false
function Check([string]$Name, [scriptblock]$Test) { if (& $Test) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:fail = $true } }
$cfg = (git -C $Remote show main:configs/edge-router.cfg) -join "`n"
$isRemoteUrl = { param($u) $u -match '^(https?|ssh|git)://' -or $u -match '@' }
Check 'server main has VLAN 30 named CAMERAS'   { $cfg -cmatch '(?m)^ name CAMERAS$' }
Check 'conflict resolved to ntp 192.0.2.200'    { $cfg -match '(?m)^ntp server 192\.0\.2\.200$' -and $cfg -notmatch '192\.0\.2\.250' }
Check 'no conflict markers on the server'       { $cfg -notmatch '(?m)^(<<<<<<<|=======|>>>>>>>)' }
Check 'two PR merge commits on main'            { @(git -C $Remote log --merges --oneline '--grep=^Merge pull request' main).Count -eq 2 }
Check 'only main is left on the server'         { (git -C $Remote for-each-ref '--format=%(refname:short)' refs/heads) -eq 'main' }
Check 'laptop main equals the server main'      { (git -C $Laptop rev-parse main) -eq (git -C $Remote rev-parse main) }
Check 'laptop has only the main branch'         { (git -C $Laptop branch '--format=%(refname:short)') -eq 'main' }
Check 'colleague has no stale remote branches'  { @(git -C $Colleague for-each-ref '--format=%(refname)' refs/remotes/origin | Where-Object { $_ -notin 'refs/remotes/origin/HEAD','refs/remotes/origin/main' }).Count -eq 0 }
Check 'laptop working tree clean'               { -not (git -C $Laptop status --porcelain) }
Check 'origin URLs are local paths only'        { -not (& $isRemoteUrl (git -C $Laptop remote get-url origin)) -and -not (& $isRemoteUrl (git -C $Colleague remote get-url origin)) }
Write-Host ''
git -C $Laptop log --oneline --graph --decorate -8
if ($script:fail) { Write-Host 'RESULT: FAIL'; exit 1 } else { Write-Host 'RESULT: PASS' }
