# Deletes only the Unit 4 lab folder, and only if it carries the lab marker file.
. (Join-Path $PSScriptRoot 'lab-env.ps1')
if (-not (Test-Path -LiteralPath $Lab)) { Write-Host "Nothing to clean: $Lab does not exist."; exit 0 }
if (-not (Test-Path -LiteralPath $Marker -PathType Leaf) -or ((Get-Content -LiteralPath $Marker -Raw) -ne $MarkerText)) {
  throw "$Lab exists but has no Unit 4 marker; refusing to delete it."
}
Remove-Item -LiteralPath $Lab -Recurse -Force
if ((Test-Path -LiteralPath $LabRoot) -and -not (Get-ChildItem -LiteralPath $LabRoot -Force)) { Remove-Item -LiteralPath $LabRoot }
Write-Host "Removed $Lab"
