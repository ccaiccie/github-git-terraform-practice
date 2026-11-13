# Verifies the finished lab.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
git -C $Laptop fetch -q --prune
$script:fail = $false
function Check([string]$Name, [scriptblock]$Test) { if (& $Test) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:fail = $true } }
$pr1 = git -C $Remote log --format=%h --abbrev=7 '--grep=^Add VLAN 30 for cameras$' main
$rd = { param($f) if (Test-Path -LiteralPath $f) { (Get-Content -LiteralPath $f -Raw).Trim() } else { '' } }
Check 'main defines VLAN 30 as CCTV'                { ((git -C $Remote show main:infra/main.tf) -join "`n") -cmatch '(?m)^  name    = "CCTV"$' }
Check 'switch matches main (10 USERS, 20 VOICE, 30 CCTV)' { ((Get-SwitchVlans | ForEach-Object { "$($_.Id) $($_.Name)" }) -join ' ') -ceq '10 USERS 20 VOICE 30 CCTV' }
Check 'state matches main'                          { $s = @(Get-StateItems); $s.Count -eq 3 -and @($s | Where-Object { $_.A -ceq 'lab_vlan.cameras' -and $_.Id -eq '30' -and $_.Name -ceq 'CCTV' }).Count -eq 1 }
Check "first pull request's plan check passed"      { (& $rd (Join-Path $GH 'checks' $pr1)) -eq 'success' }
Check 'plan comment was posted for it'              { (& $rd (Join-Path $GH "pr-comment-$pr1.md")) -match '1 to add' }
Check 'two drift issues were opened'                { @(Get-ChildItem -LiteralPath (Join-Path $GH 'issues') -Filter *.md).Count -eq 2 }
Check 'last drift check exit code was 0'            { (& $rd (Join-Path $GH 'last-drift-exit')) -eq '0' }
Check 'no apply is left waiting'                    { -not (Test-Path -LiteralPath (Join-Path $GH 'pending-apply')) }
Check 'no state lock is left'                       { -not (Test-Path -LiteralPath $Lock) }
Check 'only main is left on the server'             { (git -C $Remote for-each-ref '--format=%(refname:short)' refs/heads) -eq 'main' }
Check 'laptop working tree clean'                   { -not (git -C $Laptop status --porcelain) }
Check 'origin URL is a local path'                  { (git -C $Laptop remote get-url origin) -notmatch '^(https?|ssh|git)://|@' }
if ($script:fail) { Write-Host 'RESULT: FAIL'; exit 1 } else { Write-Host 'RESULT: PASS' }
