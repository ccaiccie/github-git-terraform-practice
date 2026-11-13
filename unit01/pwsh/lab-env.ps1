# Shared settings for the Unit 1 practice (dot-sourced by every script). PowerShell 7+.
# Everything happens inside one throwaway folder. Nothing is pushed anywhere.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$LabRoot    = if ($env:GIT_COURSE_LAB) { $env:GIT_COURSE_LAB } else { Join-Path $HOME 'git-course-lab' }
$Lab        = Join-Path $LabRoot 'unit01'
$Repo       = Join-Path $Lab 'network-configs'
$Marker     = Join-Path $Lab '.git-course-unit01'
$MarkerText = 'git-course unit01 practice lab - safe to delete with 99-cleanup'
$Files      = Join-Path $PSScriptRoot '..' 'files'
function Assert-Lab {
  if (-not (Test-Path -LiteralPath $Marker -PathType Leaf) -or ((Get-Content -LiteralPath $Marker -Raw) -ne $MarkerText)) {
    throw "Lab not found at $Lab (run 01-create-lab.ps1 first)."
  }
  Set-Location -LiteralPath $Repo
}
function Step([string]$Text) { Write-Host "`n== $Text ==" }
# Write text with LF line endings so Bash and PowerShell labs produce identical files.
function Write-Lf([string]$Path, [string[]]$Lines, [switch]$Append) {
  $text = ($Lines -join "`n") + "`n"
  # .NET file APIs use the process directory, not the PowerShell location, so resolve the path first
  if (-not [IO.Path]::IsPathRooted($Path)) { $Path = Join-Path (Get-Location).ProviderPath $Path }
  if ($Append) { [IO.File]::AppendAllText($Path, $text) } else { [IO.File]::WriteAllText($Path, $text) }
}
