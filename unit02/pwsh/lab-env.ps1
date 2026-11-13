# Shared settings for the Unit 2 practice (dot-sourced by every script). PowerShell 7+.
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$LabRoot    = if ($env:GIT_COURSE_LAB) { $env:GIT_COURSE_LAB } else { Join-Path $HOME 'git-course-lab' }
$Lab        = Join-Path $LabRoot 'unit02'
$Remote     = Join-Path $Lab 'server' 'network-configs.git'    # plays the role of GitHub or GitLab
$Laptop     = Join-Path $Lab 'laptop' 'network-configs'        # your clone
$Colleague  = Join-Path $Lab 'colleague' 'network-configs'     # a teammate's clone
$Marker     = Join-Path $Lab '.git-course-unit02'
$MarkerText = 'git-course unit02 practice lab - safe to delete with 99-cleanup'
$Files      = Join-Path $PSScriptRoot '..' 'files'
function Assert-Lab {
  if (-not (Test-Path -LiteralPath $Marker -PathType Leaf) -or ((Get-Content -LiteralPath $Marker -Raw) -ne $MarkerText)) {
    throw "Lab not found at $Lab (run 01-create-remote-and-push.ps1 first)."
  }
}
function Set-LabIdentity([string]$Name, [string]$Email) { # stored in this repository only
  git config --local user.name $Name; git config --local user.email $Email
  git config --local core.autocrlf false; git config --local pull.rebase false
}
function Step([string]$Text) { Write-Host "`n== $Text ==" }
# Write text with LF line endings so Bash and PowerShell labs produce identical files.
function Write-Lf([string]$Path, [string[]]$Lines, [switch]$Append) {
  $text = ($Lines -join "`n") + "`n"
  if (-not [IO.Path]::IsPathRooted($Path)) { $Path = Join-Path (Get-Location).ProviderPath $Path }
  if ($Append) { [IO.File]::AppendAllText($Path, $text) } else { [IO.File]::WriteAllText($Path, $text) }
}
