# Shared settings for the Unit 5 practice (dot-sourced by every script). PowerShell 7+.
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$LabRoot    = if ($env:GIT_COURSE_LAB) { $env:GIT_COURSE_LAB } else { Join-Path $HOME 'git-course-lab' }
$Lab        = Join-Path $LabRoot 'unit05'
$Remote     = Join-Path $Lab 'server' 'network-configs.git'    # plays the role of GitLab
$Laptop     = Join-Path $Lab 'laptop' 'network-configs'        # your clone
$Colleague  = Join-Path $Lab 'colleague' 'network-configs'     # a teammate's clone
$Marker     = Join-Path $Lab '.git-course-unit05'
$MarkerText = 'git-course unit05 practice lab - safe to delete with 99-cleanup'
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
$Pwsh      = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName   # this PowerShell 7, to run the check script
$Runner    = Join-Path $Lab 'runner'      # each simulated pipeline gets a fresh clone here, like a new runner job
$Pipes     = Join-Path $Lab 'pipelines'   # one file per commit: the pipeline status GitLab would show for that commit
$Approvals = Join-Path $Lab 'approvals'   # one line per approval, per commit
$Reserved  = 'stages', 'workflow', 'default', 'variables', 'include', 'image', 'services', 'cache', 'before_script', 'after_script'
# --- tiny readers for the simple .gitlab-ci.yml layout used in this lab (no YAML module needed) ---
function Read-Lines([string]$Path) { [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).ProviderPath).TrimEnd("`n").Split("`n") }
function Get-CiStages([string[]]$Y) { foreach ($l in $Y) { if ($l -match '^stages: *\[(.*)\] *$') { return @($Matches[1].Replace(' ', '').Split(',')) } }; @() }
function Get-CiJobs([string[]]$Y) { foreach ($l in $Y) { if ($l -match '^([A-Za-z0-9_.-]+):' -and $Matches[1] -notin $Reserved) { $Matches[1] } } }
function Get-CiBlock([string[]]$Y, [string]$Name) { $on = $false; foreach ($l in $Y) { if ($l -match "^$([regex]::Escape($Name)):") { $on = $true; continue }; if ($l -match '^[^ #]') { $on = $false }; if ($on) { $l } } }
function Get-CiJobStage([string[]]$Y, [string]$Job) { foreach ($l in (Get-CiBlock $Y $Job)) { if ($l -match '^  stage: *(\S+) *$') { return $Matches[1] } }; '' }
function Get-CiIfLines([string[]]$Block) { foreach ($l in $Block) { if ($l -match '^ *- if: *(.*\S) *$') { $Matches[1] } } }
function Get-CiJobScript([string[]]$Y, [string]$Job) { $on = $false; foreach ($l in (Get-CiBlock $Y $Job)) { if ($l -match '^  script:') { $on = $true; continue }; if ($l -match '^  [a-z]') { $on = $false }; if ($on -and $l -match '^    - (.*)$') { $Matches[1] } } }
# Evaluates the two rule expressions used in this lab.
function Test-Rule([string]$Expr, [string]$Source, [string]$Branch) {
  switch ($Expr) {
    '$CI_PIPELINE_SOURCE == "merge_request_event"' { return $Source -eq 'merge_request_event' }
    '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH' { return $Source -eq 'push' -and $Branch -eq 'main' }
    default { throw "unsupported rule in this simulator: $Expr" }
  }
}
function Test-Rules([string[]]$Exprs, [string]$Source, [string]$Branch) { # no rules at all = match
  $Exprs = @($Exprs | Where-Object { $_ }); if (-not $Exprs.Count) { return $true }
  foreach ($e in $Exprs) { if (Test-Rule $e $Source $Branch) { return $true } }; $false
}
# Runs one job script line. The lab's lines are Bash; PowerShell runs the matching .ps1 or an equivalent, so no Bash is needed.
function Invoke-JobLine([string]$Line) {
  if ($Line -match '^bash scripts/(\S+)\.sh (.*)$') { & $Pwsh -NoProfile -File "scripts/$($Matches[1]).ps1" $Matches[2] | ForEach-Object { Write-Host $_ }; return $LASTEXITCODE -eq 0 }
  if ($Line -eq "grep -c '^vlan ' configs/*.cfg") { Write-Host (@(Select-String -Path configs/*.cfg -Pattern '^vlan ').Count); return $true }
  throw "no PowerShell equivalent for: $Line"
}
# Simulates one GitLab pipeline. Source = merge_request_event or push.
# Like a merge request pipeline on GitLab Free, it tests the source branch as it is (merged results pipelines are Premium).
function Invoke-Pipeline([string]$Source, [string]$Branch) {
  $head = git -C $Remote rev-parse "refs/heads/$Branch"; $short = $head.Substring(0, 7)
  New-Item -ItemType Directory -Path $Runner, $Pipes -Force | Out-Null
  $n = @(Get-ChildItem -LiteralPath $Runner -Directory).Count + 1; $run = Join-Path $Runner "pipeline-$n"
  git clone -q -b $Branch $Remote $run 2>&1
  $Y = Read-Lines (Join-Path $run '.gitlab-ci.yml')
  if (-not (Test-Rules (Get-CiIfLines (Get-CiBlock $Y 'workflow')) $Source $Branch)) {
    Remove-Item -LiteralPath $run -Recurse -Force; Write-Host "source: $Source  ref: $Branch  commit: $short"; Write-Host 'no pipeline created (workflow rules)'; return
  }
  Write-Host "pipeline #$n  source: $Source  ref: $Branch  commit: $short"
  $stages = Get-CiStages $Y; Write-Host "stages: $($stages -join ' ')"; $status = 'passed'
  foreach ($st in $stages) {
    foreach ($j in (Get-CiJobs $Y)) {
      if ((Get-CiJobStage $Y $j) -ne $st) { continue }
      if (-not (Test-Rules (Get-CiIfLines (Get-CiBlock $Y $j)) $Source $Branch)) { Write-Host "job ${j}: not in this pipeline (rules)"; continue }
      if ($status -eq 'failed') { Write-Host "job ${j}: skipped (an earlier stage failed)"; continue }
      Write-Host "job $j (stage $st):"
      Push-Location -LiteralPath $run
      try {
        $PSNativeCommandUseErrorActionPreference = $false; $ok = $true
        foreach ($line in (Get-CiJobScript $Y $j)) { Write-Host "`$ $line"; if (-not (Invoke-JobLine $line)) { $ok = $false; break } }
      } finally { Pop-Location; $PSNativeCommandUseErrorActionPreference = $true }
      if ($ok) { Write-Host "job ${j}: passed" } else { Write-Host "job ${j}: failed"; $status = 'failed' }
    }
  }
  Set-Content -LiteralPath (Join-Path $Pipes $head) -Value $status
  Write-Host "pipeline #${n}: $status"
}
# Records an approval for the merge request's latest commit.
function Add-Approval([string]$Branch, [string]$Name) {
  $head = git -C $Remote rev-parse "refs/heads/$Branch"; New-Item -ItemType Directory -Path $Approvals -Force | Out-Null
  Add-Content -LiteralPath (Join-Path $Approvals $head) -Value $Name; Write-Host "$Name approved the merge request (commit $($head.Substring(0, 7)))"
}
# Simulates GitLab merge checks with "Pipelines must succeed". Tier = Free or Premium; Need = approvals required by a rule.
# On Free, approvals are optional; required approval rules need Premium or Ultimate. Returns $true when the merge is allowed.
function Test-MergeChecks([string]$Branch, [string]$Tier, [int]$Need) {
  $head = git -C $Remote rev-parse "refs/heads/$Branch"; $pf = Join-Path $Pipes $head; $af = Join-Path $Approvals $head
  $ps = if (Test-Path -LiteralPath $pf) { (Get-Content -LiteralPath $pf -Raw).Trim() } else { 'none' }
  $got = if (Test-Path -LiteralPath $af) { @(Get-Content -LiteralPath $af).Count } else { 0 }
  Write-Host "merge checks (tier: $Tier) for $($head.Substring(0, 7))"; $blocked = $false
  if ($ps -eq 'passed') { Write-Host '  pipeline: passed' } else { Write-Host "  pipeline: $ps (Pipelines must succeed)"; $blocked = $true }
  if ($Tier -eq 'Free') { Write-Host "  approvals: $got given, optional on Free" }
  else { Write-Host "  approval rule: $got of $Need required"; if ($got -lt $Need) { $blocked = $true } }
  if ($blocked) { Write-Host 'Merge blocked'; return $false }; Write-Host 'Ready to merge'; $true
}
# Basic structure checks for a .gitlab-ci.yml (no YAML module needed). Full validation: the CI Lint tool in GitLab (optional).
function Test-GitLabCi([string]$Path, [string]$Repo) {
  $Y = Read-Lines $Path; $Repo = (Resolve-Path -LiteralPath $Repo).ProviderPath; $script:ciFail = $false
  function ok($m) { Write-Host "PASS: $m" }; function ko($m) { Write-Host "FAIL: $m"; $script:ciFail = $true }
  $tab = 0; for ($i = 0; $i -lt $Y.Count; $i++) { if ($Y[$i].Contains("`t")) { $tab = $i + 1; break } }
  if ($tab) { ko "tab character on line $tab (YAML indentation must use spaces)" } else { ok 'no tab characters' }
  $stages = @(Get-CiStages $Y)
  if ($stages.Count) { ok "stages: $($stages -join ' ')" } else { ko 'no stages: list' }
  $wf = (Get-CiBlock $Y 'workflow') -join "`n"
  if ($wf -match 'merge_request_event') { ok 'pipelines run for merge requests' } else { ko 'no merge_request_event rule' }
  if ($wf -match 'CI_DEFAULT_BRANCH') { ok 'pipelines run on the default branch (after merge)' } else { ko 'no default-branch rule' }
  if (@($Y | Where-Object { $_ -match '^\s*(runs-on|steps|uses):' }).Count) { ko 'GitHub Actions keyword found (runs-on, steps or uses)' } else { ok 'no GitHub Actions keywords left' }
  foreach ($j in (Get-CiJobs $Y)) {
    $st = Get-CiJobStage $Y $j
    if (-not $st) { ko "job $j has no stage" } elseif ($st -in $stages) { ok "job ${j}: stage $st is listed in stages" } else { ko "job ${j}: stage '$st' is not listed in stages" }
    if (@(Get-CiJobScript $Y $j).Count) { ok "job $j has a script" } else { ko "job $j has no script" }
  }
  foreach ($l in $Y) { if ($l -match '^ *- bash (\S+)') { $s = $Matches[1]; if (Test-Path -LiteralPath (Join-Path $Repo $s) -PathType Leaf) { ok "script exists: $s" } else { ko "script not found: $s" } } }
  if ($script:ciFail) { Write-Host 'RESULT: FAIL'; return $false }; Write-Host 'RESULT: PASS'; $true
}
# Structure checks for the OpenTofu component example. Dir = folder with .gitlab-ci.yml and backend.tf.
function Test-TofuExample([string]$Dir) {
  $Y = Read-Lines (Join-Path $Dir '.gitlab-ci.yml'); $script:tfFail = $false
  function ok($m) { Write-Host "PASS: $m" }; function ko($m) { Write-Host "FAIL: $m"; $script:tfFail = $true }
  if (@($Y | Where-Object { $_ -match 'component: .*components/opentofu/' }).Count) { ok 'includes the OpenTofu CI/CD component' } else { ko 'OpenTofu component not included' }
  $pin = ''; foreach ($l in $Y) { if ($l -match 'components/opentofu/[a-z-]+@(\S+) *$') { $pin = $Matches[1] } }
  if ($pin -match '^\d+\.\d+\.\d+$') { ok "component pinned to release $pin" } else { ko "component not pinned to a release (found '@$(if ($pin) { $pin } else { 'nothing' })')" }
  $inver = ''; foreach ($l in $Y) { if ($l -match '^ +version: *(\S+) *$') { $inver = $Matches[1] } }
  if ($pin -and $inver -eq $pin) { ok 'inputs.version matches the pin' } else { ko "inputs.version ($inver) must equal the pinned version ($pin)" }
  $s = ' ' + ((Get-CiStages $Y) -join ' ') + ' '
  if ($s -match ' validate (.* )?build (.* )?deploy ') { ok 'stages validate, build, deploy (in order)' } else { ko 'stages must include validate, build, deploy in that order' }
  if (@(Read-Lines (Join-Path $Dir 'backend.tf') | Where-Object { $_ -match '^ *backend "http"' }).Count) { ok 'backend.tf uses the http backend (GitLab-managed state)' } else { ko 'backend.tf has no http backend' }
  if ($script:tfFail) { Write-Host 'RESULT: FAIL'; return $false }; Write-Host 'RESULT: PASS'; $true
}
