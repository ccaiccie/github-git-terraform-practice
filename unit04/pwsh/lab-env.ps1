# Shared settings for the Unit 4 practice (dot-sourced by every script). PowerShell 7+.
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$LabRoot    = if ($env:GIT_COURSE_LAB) { $env:GIT_COURSE_LAB } else { Join-Path $HOME 'git-course-lab' }
$Lab        = Join-Path $LabRoot 'unit04'
$Remote     = Join-Path $Lab 'server' 'network-configs.git'    # plays the role of GitHub or GitLab
$Laptop     = Join-Path $Lab 'laptop' 'network-configs'        # your clone
$Colleague  = Join-Path $Lab 'colleague' 'network-configs'     # a teammate's clone
$Marker     = Join-Path $Lab '.git-course-unit04'
$MarkerText = 'git-course unit04 practice lab - safe to delete with 99-cleanup'
$Files      = Join-Path $PSScriptRoot '..' 'files'
function Assert-Lab {
  if (-not (Test-Path -LiteralPath $Marker -PathType Leaf) -or ((Get-Content -LiteralPath $Marker -Raw) -ne $MarkerText)) {
    throw "Lab not found at $Lab (run 01-setup.ps1 first)."
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
# Replace one exact line in a file, keeping LF endings.
function Set-Line([string]$Path, [string]$Old, [string]$New) {
  $full = Join-Path (Get-Location).ProviderPath $Path
  $lines = [IO.File]::ReadAllText($full).TrimEnd("`n").Split("`n") | ForEach-Object { if ($_ -ceq $Old) { $New } else { $_ } }
  Write-Lf $full $lines
}
function Say([string]$Cmd) { Write-Host "`$ $Cmd" } # show the command being run
$Pwsh   = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName   # this PowerShell 7, to run the check script
$Runner = Join-Path $Lab 'runner'   # each simulated workflow run gets a fresh clone here, like a new runner VM
$Checks = Join-Path $Lab 'checks'   # one file per commit: the check result GitHub would show on that commit
# Simulates one run of .github/workflows/config-check.yml, job "validate". Event = pull_request or push.
function Invoke-CiRun([string]$Event, [string]$Branch) {
  $head = git -C $Remote rev-parse "refs/heads/$Branch"
  New-Item -ItemType Directory -Path $Runner, $Checks -Force | Out-Null
  $n = @(Get-ChildItem -LiteralPath $Runner -Directory).Count + 1; $run = Join-Path $Runner "run-$n"
  git clone -q $Remote $run 2>&1
  if ($Event -eq 'pull_request') { # like GitHub: test the branch as if it were merged into main
    git -C $run switch -q -c pr-merge-test origin/main
    git -C $run -c user.name=runner -c user.email=runner@example.com merge -q --no-ff --no-edit "origin/$Branch" | Out-Null
  }
  Write-Host "run #$n  workflow: config-check  job: validate  event: $Event  commit: $($head.Substring(0, 7))"
  Push-Location -LiteralPath $run
  try {
    $PSNativeCommandUseErrorActionPreference = $false
    & $Pwsh -NoProfile -File scripts/check-configs.ps1 configs | ForEach-Object { Write-Host $_ }
    $status = if ($LASTEXITCODE -eq 0) { 'success' } else { 'failure' }
    if ($status -eq 'success' -and $Event -eq 'push') { Write-Host 'Config report: VLAN lines'; Write-Host (@(Select-String -Path configs/*.cfg -Pattern '^vlan ').Count) }
  } finally { Pop-Location; $PSNativeCommandUseErrorActionPreference = $true }
  Set-Content -LiteralPath (Join-Path $Checks $head) -Value $status
  Write-Host "check config-check / validate: $status"
}
# Simulates branch protection with a required status check. Returns $true when the merge is allowed.
function Test-MergeGate([string]$Branch) {
  $head = git -C $Remote rev-parse "refs/heads/$Branch"; $f = Join-Path $Checks $head
  $st = if (Test-Path -LiteralPath $f) { (Get-Content -LiteralPath $f -Raw).Trim() } else { 'pending' }
  Write-Host "required check config-check / validate on $($head.Substring(0, 7)): $st"
  if ($st -eq 'success') { Write-Host 'Merge allowed'; return $true }
  Write-Host 'Merging is blocked: the required check has not passed'; return $false
}
# Basic structure checks for a workflow file (no YAML module needed). Full validation: actionlint (optional).
function Test-Workflow([string]$Path, [string]$Repo) {
  $Path = (Resolve-Path -LiteralPath $Path).ProviderPath; $Repo = (Resolve-Path -LiteralPath $Repo).ProviderPath
  $lines = [IO.File]::ReadAllText($Path).TrimEnd("`n").Split("`n"); $script:wfFail = $false
  function ok($m) { Write-Host "PASS: $m" }; function ko($m) { Write-Host "FAIL: $m"; $script:wfFail = $true }
  $tab = 0; for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].Contains("`t")) { $tab = $i + 1; break } }
  if ($tab) { ko "tab character on line $tab (YAML indentation must use spaces)" } else { ok 'no tab characters' }
  $has = { param($re) [bool]($lines | Where-Object { $_ -match $re }) }
  if ((& $has '^name:') -and (& $has '^on:') -and (& $has '^jobs:')) { ok 'top-level keys name, on, jobs' } else { ko 'missing name:, on: or jobs:' }
  if (& $has '^  pull_request:') { ok 'runs on pull requests' } else { ko 'no pull_request trigger' }
  if (& $has '^  push:') { ok 'runs on push (after merge)' } else { ko 'no push trigger' }
  if (& $has '^permissions:') { ok 'permissions are set explicitly' } else { ko 'no permissions: block' }
  $inJobs = $false; $jobs = 0
  foreach ($l in $lines) { if ($l -match '^jobs:') { $inJobs = $true; continue }; if ($l -match '^[^ #]') { $inJobs = $false }; if ($inJobs -and $l -match '^  [A-Za-z0-9_-]+:\s*$') { $jobs++ } }
  $runs = @($lines | Where-Object { $_ -match '^    runs-on:' }).Count; $steps = @($lines | Where-Object { $_ -match '^    steps:' }).Count
  if ($jobs -gt 0 -and $runs -eq $jobs -and $steps -eq $jobs) { ok "$jobs job(s), each with runs-on and steps" } else { ko "jobs: $jobs, runs-on: $runs, steps: $steps (each job needs both)" }
  if (@($lines | Where-Object { $_ -match '^\s*-?\s*uses:' -and $_ -notmatch '@' }).Count) { ko 'an action is not pinned to a version (@...)' } else { ok 'actions pinned to a version' }
  foreach ($l in $lines) { if ($l -match '^\s*run: bash (\S+)') { $s = $Matches[1]; if (Test-Path -LiteralPath (Join-Path $Repo $s) -PathType Leaf) { ok "script exists: $s" } else { ko "script not found: $s" } } }
  if ($script:wfFail) { Write-Host 'RESULT: FAIL'; return $false }; Write-Host 'RESULT: PASS'; return $true
}
