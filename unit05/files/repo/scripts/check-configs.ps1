# Checks router configs: VLAN IDs 1-4094, no duplicate VLAN IDs, every VLAN named, at least one NTP server.
# Same rules and messages as check-configs.sh. Exit code 0 = pass (green check), 1 = problem (red check).
param([string]$Dir = 'configs')
$files = @(Get-ChildItem -Path (Join-Path $Dir '*.cfg') -File -ErrorAction SilentlyContinue | Sort-Object Name)
if ($files.Count -eq 0) { Write-Host "FAIL: no .cfg files in $Dir"; exit 1 }
$fail = $false
foreach ($file in $files) {
  $f = "$Dir/$($file.Name)"; $out = [Collections.Generic.List[string]]::new()
  $seen = @{}; $cur = $null; $curLine = 0; $named = $false; $ntp = $false; $nr = 0
  foreach ($line in [IO.File]::ReadAllText($file.FullName).TrimEnd("`n").Split("`n")) {
    $nr++
    if ($line -match '^vlan (\d+)$') { $id = [int]$Matches[1]
      if ($id -lt 1 -or $id -gt 4094) { $out.Add("FAIL ${f}:${nr}: VLAN $id is outside 1-4094") }
      if ($seen.ContainsKey($id)) { $out.Add("FAIL ${f}:${nr}: duplicate VLAN $id (first defined on line $($seen[$id]))") } else { $seen[$id] = $nr }
      $cur = $id; $curLine = $nr; $named = $false; continue }
    if ($null -ne $cur -and $line -match '^ name [^ ]') { $named = $true; continue }
    if ($line -eq '!') { if ($null -ne $cur -and -not $named) { $out.Add("FAIL ${f}:${curLine}: VLAN $cur has no name") }; $cur = $null; continue }
    if ($line -match '^ntp server ') { $ntp = $true }
  }
  if ($null -ne $cur -and -not $named) { $out.Add("FAIL ${f}:${curLine}: VLAN $cur has no name") }
  if (-not $ntp) { $out.Add("FAIL ${f}: no ntp server line") }
  if ($out.Count) { $out | ForEach-Object { Write-Host $_ }; $fail = $true } else { Write-Host "PASS $f" }
}
if ($fail) { Write-Host "RESULT: FAIL ($($files.Count) file(s) checked)"; exit 1 }
Write-Host "RESULT: PASS ($($files.Count) file(s) checked)"
