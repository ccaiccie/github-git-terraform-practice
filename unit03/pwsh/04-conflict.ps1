# Two people change the same line. The PR now has a conflict. Resolve it locally on the branch, push, then merge.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
git switch -q -c change-ntp main
Set-Line configs/edge-router.cfg 'ntp server 192.0.2.123' 'ntp server 192.0.2.200'
git commit -q -am 'Move NTP to 192.0.2.200'
git push -q -u origin change-ntp 2>&1
Set-Location -LiteralPath $Colleague
git pull -q 2>&1
Set-Line configs/edge-router.cfg 'ntp server 192.0.2.123' 'ntp server 192.0.2.250'
git commit -q -am 'Move NTP to 192.0.2.250'
git push -q 2>&1
Set-Location -LiteralPath $Laptop
git fetch -q
Step 'git merge origin/main  (on the PR branch; expected conflict)'
$PSNativeCommandUseErrorActionPreference = $false
git merge origin/main 2>&1
$code = $LASTEXITCODE
$PSNativeCommandUseErrorActionPreference = $true
if ($code -eq 0) { throw 'UNEXPECTED: no conflict' }
Step 'git status --short'
git status --short
Step 'The conflicted lines in configs/edge-router.cfg'
Select-String -Path configs/edge-router.cfg -Pattern '^<<<<<<<' -Context 0,4 | ForEach-Object {
  $n = $_.LineNumber; Write-Host "${n}:$($_.Line)"; $i = $n; foreach ($l in $_.Context.PostContext) { $i++; Write-Host "$i-$l" } }
Step 'Resolve: keep 192.0.2.200, remove the markers, add, commit'
$out = [Collections.Generic.List[string]]::new(); $skip = $false
foreach ($l in [IO.File]::ReadAllText((Join-Path $Laptop 'configs/edge-router.cfg')).TrimEnd("`n").Split("`n")) {
  if ($l.StartsWith('<<<<<<< ')) { $skip = $false; continue }
  if ($l.StartsWith('=======')) { $skip = $true; continue }
  if ($l.StartsWith('>>>>>>> ')) { $skip = $false; continue }
  if (-not $skip) { $out.Add($l) } }
Write-Lf configs/edge-router.cfg $out
Select-String -Path configs/edge-router.cfg -Pattern '^ntp server' | ForEach-Object { Write-Host "$($_.LineNumber):$($_.Line)" }
git add configs/edge-router.cfg
git commit -q --no-edit
git push 2>&1
Step 'Merge PR #2 into main'
git switch -q main
git pull -q 2>&1
git merge -q --no-ff change-ntp -m 'Merge pull request #2 from change-ntp'
git push 2>&1
git log --oneline --graph -6
