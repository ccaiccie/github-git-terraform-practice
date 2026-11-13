# Verifies the finished lab: clones match the remote, upstreams set, one merge commit, pushed branch, local-only URLs.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
git -C $Colleague fetch -q; git -C $Laptop fetch -q
$script:fail = $false
function Check([string]$Name, [scriptblock]$Test) { if (& $Test) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:fail = $true } }
$rm = git -C $Remote rev-parse main
$cfg = (git -C $Remote show main:configs/edge-router.cfg) -join "`n"
$isRemoteUrl = { param($u) $u -match '^(https?|ssh|git)://' -or $u -match '@' }
Check 'remote is a bare repository'            { (git -C $Remote rev-parse --is-bare-repository) -eq 'true' }
Check 'laptop main equals the remote main'     { (git -C $Laptop rev-parse main) -eq $rm }
Check 'laptop origin/main equals remote main'  { (git -C $Laptop rev-parse origin/main) -eq $rm }
Check 'colleague origin/main equals remote'    { (git -C $Colleague rev-parse origin/main) -eq $rm }
Check 'upstream of laptop main is origin/main' { (git -C $Laptop rev-parse --abbrev-ref 'main@{upstream}') -eq 'origin/main' }
Check '5 commits on the remote main'           { (git -C $Remote rev-list --count main) -eq '5' }
Check 'exactly 1 merge commit on the remote'   { (git -C $Remote rev-list --merges --count main) -eq '1' }
Check 'VLAN 20 and second NTP server present'  { $cfg -match '(?m)^vlan 20$' -and $cfg -match '(?m)^ntp server 198\.51\.100\.123$' }
Check 'ownership note present'                 { ((git -C $Remote show main:README.md) -join "`n") -match '(?m)^Owner:' }
Check 'branch add-vlan-30 is on the server'   { [bool](git -C $Remote for-each-ref refs/heads/add-vlan-30) }
Check 'add-vlan-30 tracks origin/add-vlan-30'   { (git -C $Laptop rev-parse --abbrev-ref 'add-vlan-30@{upstream}') -eq 'origin/add-vlan-30' }
Check 'laptop working tree clean'              { -not (git -C $Laptop status --porcelain) }
Check 'origin URLs are local paths only'       { -not (& $isRemoteUrl (git -C $Laptop remote get-url origin)) -and -not (& $isRemoteUrl (git -C $Colleague remote get-url origin)) }
Write-Host ''
git -C $Laptop log --oneline --graph --decorate --all
if ($script:fail) { Write-Host 'RESULT: FAIL'; exit 1 } else { Write-Host 'RESULT: PASS' }
