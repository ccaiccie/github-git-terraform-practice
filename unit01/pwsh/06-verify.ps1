# Verifies the finished lab: expected commits, a fast-forward, one merge commit, ignored secret, clean tree.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
$script:fail = $false
function Check([string]$Name, [scriptblock]$Test) {
  $ok = $false; try { $ok = [bool](& $Test) } catch { $ok = $false }
  if ($ok) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:fail = $true }
}
$PSNativeCommandUseErrorActionPreference = $false
Check 'on branch main'                    { (git branch --show-current) -eq 'main' }
Check '7 commits reachable from main'     { (git rev-list --count main) -eq '7' }
Check 'exactly 1 merge commit'            { (git rev-list --merges --count main) -eq '1' }
Check 'merge commit has 2 parents'        { ((git log -1 --merges --format=%p main) -split ' ').Count -eq 2 }
Check 'VLAN 20 present in config'         { (Get-Content configs/edge-router.cfg) -contains 'vlan 20' }
Check 'NTP 203.0.113.123 present'         { (Get-Content configs/edge-router.cfg) -contains 'ntp server 203.0.113.123' }
Check 'secrets/enable.key is ignored'     { git check-ignore -q secrets/enable.key; $LASTEXITCODE -eq 0 }
Check 'secret never committed'            { -not ((git log --all --format= --name-only) -match '^secrets/') }
Check 'working tree clean'                { [string]::IsNullOrEmpty((git status --porcelain)) }
Check 'only branch left is main'          { (git branch --format='%(refname:short)') -eq 'main' }
Check 'no remote configured (local only)' { [string]::IsNullOrEmpty((git remote)) }
Write-Host ''; git log --oneline --graph --all --decorate
if ($script:fail) { Write-Host 'RESULT: FAIL'; exit 1 } else { Write-Host 'RESULT: PASS' }
