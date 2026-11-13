# Shared settings for the Unit 6 practice (dot-sourced by every script). PowerShell 7+.
# The "remote" is a bare repository inside the lab folder. No account and no network are needed.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$LabRoot    = if ($env:GIT_COURSE_LAB) { $env:GIT_COURSE_LAB } else { Join-Path $HOME 'git-course-lab' }
$Lab        = Join-Path $LabRoot 'unit06'
$Remote     = Join-Path $Lab 'server' 'network-configs.git'    # plays the role of GitHub
$Laptop     = Join-Path $Lab 'laptop' 'network-configs'        # your clone
$Colleague  = Join-Path $Lab 'colleague' 'network-configs'     # a teammate's clone
$Marker     = Join-Path $Lab '.git-course-unit06'
$MarkerText = 'git-course unit06 practice lab - safe to delete with 99-cleanup'
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
$Switch = Join-Path $Lab 'switch' 'running-config'       # the live network: the lab switch's VLAN config
$State  = Join-Path $Lab 'state' 'terraform.tfstate'      # remote state (simulated; real Terraform state is JSON)
$Lock   = Join-Path $Lab 'state' 'terraform.tfstate.lock' # state lock
$GH     = Join-Path $Lab 'github'                         # what GitHub would show: checks, PR comments, issues, pending runs
$Runner = Join-Path $Lab 'runner'                         # each simulated workflow run gets a fresh clone here
$StateHeader = '# simulated state (real Terraform state is JSON)'
function Read-Text([string]$Path) { [IO.File]::ReadAllText($Path).TrimEnd("`n").Split("`n") }
# ---------- tfsim: a tiny stand-in for terraform, for the lab_vlan resource only ----------
function Get-Desired([string]$Dir) { # *.tf in Dir -> objects A, Id, Name
  foreach ($f in (Get-ChildItem -LiteralPath $Dir -Filter *.tf | Sort-Object Name)) {
    $a = ''; $id = ''; $nm = ''
    foreach ($ln in (Read-Text $f.FullName)) {
      if ($ln -match '^resource "lab_vlan" "([a-z0-9_]+)" \{') { $a = "lab_vlan.$($Matches[1])"; $id = ''; $nm = ''; continue }
      if ($a -and $ln -match '^  vlan_id *= *(\d+) *$') { $id = $Matches[1]; continue }
      if ($a -and $ln -match '^  name *= *"([^"]*)" *$') { $nm = $Matches[1]; continue }
      if ($a -and $ln -match '^}') { [pscustomobject]@{ A = $a; Id = $(if ($id) { $id } else { '-' }); Name = $(if ($nm) { $nm } else { '-' }) }; $a = '' }
    }
  }
}
function Get-SwitchVlans { $id = ''; foreach ($ln in (Read-Text $Switch)) { if ($ln -match '^vlan (\d+)$') { $id = $Matches[1] } elseif ($ln -match '^ name (\S+)') { [pscustomobject]@{ Id = $id; Name = $Matches[1] } } } }
function Get-SwitchName([string]$Id) { $v = @(Get-SwitchVlans | Where-Object Id -eq $Id); if ($v.Count) { $v[0].Name } else { '' } }
function Write-Switch($Vlans) { # objects Id, Name -> running-config, sorted by VLAN ID
  $out = foreach ($v in ($Vlans | Sort-Object { [int]$_.Id })) { "vlan $($v.Id)"; " name $($v.Name)"; '!' }
  Write-Lf $Switch @($out)
}
function Get-StateItems { if (Test-Path -LiteralPath $State) { foreach ($ln in (Read-Text $State)) { if ($ln -match '^(lab_vlan\.\S+) (\S+) (\S+)$') { [pscustomobject]@{ A = $Matches[1]; Id = $Matches[2]; Name = $Matches[3] } } } } }
function Write-State($Items) { Write-Lf $State (@($StateHeader) + @($Items | ForEach-Object { "$($_.A) $($_.Id) $($_.Name)" })) }
function Test-TfValid([string]$Dir, [switch]$Quiet) {
  $d = @(Get-Desired $Dir); $msgs = @()
  foreach ($r in $d) {
    if ($r.Id -eq '-' -or [int]$r.Id -lt 1 -or [int]$r.Id -gt 4094) { $msgs += "Error: $($r.A): vlan_id must be 1-4094" }
    if ($r.Name -eq '-') { $msgs += "Error: $($r.A): name is required" }
  }
  $dup = @($d | Group-Object Id | Where-Object Count -gt 1 | Sort-Object Name | Select-Object -First 1)
  if ($dup.Count) { $msgs += "Error: vlan_id $($dup[0].Name) is used by more than one resource" }
  if (-not $Quiet) { if ($msgs.Count) { $msgs | ForEach-Object { Write-Host $_ } } else { Write-Host 'Success! The configuration is valid.' } }
  -not $msgs.Count
}
# Invoke-Tf plan|apply [-Detailed] in Dir. Prints a Terraform-style plan. Returns the exit code: 0, 1 = error, 2 = changes (-Detailed).
function Invoke-Tf([string]$Mode, [string]$Dir, [switch]$Detailed) {
  if (Test-Path -LiteralPath $Lock) { Write-Host 'Error: Error acquiring the state lock'; Write-Host "Lock Info: held by $((Get-Content -LiteralPath $Lock -Raw).Trim())"; return 1 }
  if (-not (Test-TfValid $Dir -Quiet)) { [void](Test-TfValid $Dir); return 1 }
  $d = @(Get-Desired $Dir); $s = @(Get-StateItems); $drift = @(); $acts = @(); $add = 0; $chg = 0; $del = 0
  $refreshed = foreach ($r in $s) { # refresh: read the live switch for every object in state
    $cur = Get-SwitchName $r.Id
    if (-not $cur) { $drift += "  # $($r.A) has been deleted" }
    else { if ($cur -cne $r.Name) { $drift += "  # $($r.A) has changed"; $drift += "  ~ name: `"$($r.Name)`" -> `"$cur`"" }; [pscustomobject]@{ A = $r.A; Id = $r.Id; Name = $cur } }
  }
  $refreshed = @($refreshed)
  foreach ($r in $d) {
    $m = @($refreshed | Where-Object A -ceq $r.A)
    if (-not $m.Count) { $acts += "  # $($r.A) will be created"; $acts += "  + vlan_id = $($r.Id), name = `"$($r.Name)`""; $add++ }
    elseif ($m[0].Name -cne $r.Name) { $acts += "  # $($r.A) will be updated in-place"; $acts += "  ~ name = `"$($m[0].Name)`" -> `"$($r.Name)`""; $chg++ }
  }
  foreach ($r in $refreshed) { if (-not @($d | Where-Object A -ceq $r.A).Count) { $acts += "  # $($r.A) will be destroyed"; $acts += "  - vlan_id = $($r.Id)"; $del++ } }
  if ($drift.Count) { Write-Host 'Note: Objects have changed outside of Terraform'; $drift | ForEach-Object { Write-Host $_ } }
  if (-not $acts.Count) { Write-Host 'No changes. Your infrastructure matches the configuration.' }
  else { Write-Host 'Terraform will perform the following actions:'; $acts | ForEach-Object { Write-Host $_ }; Write-Host "Plan: $add to add, $chg to change, $del to destroy." }
  if ($Mode -eq 'apply') {
    Write-Lf $Lock "$(if ($env:USER) { $env:USER } else { 'runner' })@runner"
    $keep = @(Get-SwitchVlans | Where-Object { $sv = $_; -not @($s | Where-Object Id -eq $sv.Id).Count })   # VLANs Terraform does not manage
    Write-Switch (@($keep) + @($d | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Name = $_.Name } }))
    Write-State $d
    Remove-Item -LiteralPath $Lock; Write-Host "Apply complete! Resources: $add added, $chg changed, $del destroyed."; return 0
  }
  if ($acts.Count -and $Detailed) { return 2 }; return 0
}
# ---------- simulated GitHub Actions runs ----------
function New-Run([string]$Branch) {
  New-Item -ItemType Directory -Path $Runner, (Join-Path $GH 'checks') -Force | Out-Null
  $n = @(Get-ChildItem -LiteralPath $Runner -Directory).Count + 1; $run = Join-Path $Runner "run-$n"
  git clone -q -b $Branch $Remote $run 2>&1 | Out-Null; $run
}
function Get-Head([string]$Branch) { git -C $Remote rev-parse --short=7 "refs/heads/$Branch" }
function RunNo([string]$Run) { ($Run -split '-')[-1] }
# terraform-plan on a pull request: test-merge into main, validate, plan, post the plan as a PR comment.
function Invoke-WfPlan([string]$Branch) {
  $head = Get-Head $Branch; $run = New-Run main
  git -C $run -c user.name=runner -c user.email=runner@example.com merge -q --no-ff --no-edit "origin/$Branch" | Out-Null
  Write-Host "run #$(RunNo $run)  workflow: terraform-plan  event: pull_request  commit: $head"
  $infra = Join-Path $run 'infra'; $ok = $false
  Say 'terraform validate'
  if (Test-TfValid $infra) { Say 'terraform plan'; $lines = @(); $code = Invoke-Tf plan $infra 6>&1 | ForEach-Object { if ($_ -is [Management.Automation.InformationRecord]) { $lines += "$_" } else { $_ } }; $ok = ($code -eq 0); $lines | ForEach-Object { Write-Host $_ } }
  $chk = Join-Path $GH 'checks' $head
  if ($ok) { Write-Lf (Join-Path $GH "pr-comment-$head.md") (@("### terraform plan for $head") + $lines); Write-Host 'comment posted on the pull request'; Set-Content -LiteralPath $chk -Value success }
  else { Set-Content -LiteralPath $chk -Value failure }
  Write-Host "check terraform-plan / plan: $((Get-Content -LiteralPath $chk -Raw).Trim())"
}
function Test-MergeGate([string]$Branch) {
  $head = Get-Head $Branch; $f = Join-Path $GH 'checks' $head
  $st = if (Test-Path -LiteralPath $f) { (Get-Content -LiteralPath $f -Raw).Trim() } else { 'pending' }
  Write-Host "required check terraform-plan / plan on ${head}: $st"
  if ($st -eq 'success') { Write-Host 'Merge allowed'; return $true }; Write-Host 'Merging is blocked'; $false
}
# terraform-apply: starts on push to main (or by hand), then waits for the production environment review.
function Start-WfApply([string]$Event = 'push') {
  $run = New-Run main
  Write-Host "run #$(RunNo $run)  workflow: terraform-apply  event: $Event  commit: $(Get-Head main)"
  Write-Lf (Join-Path $GH 'pending-apply') $run; Write-Host 'job apply is waiting for review: environment production'
}
function Invoke-WfApplyJob {
  $pf = Join-Path $GH 'pending-apply'; $run = (Get-Content -LiteralPath $pf -Raw).Trim()
  if (-not (Test-Path -LiteralPath "$run.approved")) { Write-Host 'job apply is still waiting for review'; return }
  Write-Host "job apply (run #$(RunNo $run)):"; Say 'terraform apply -auto-approve'
  $code = Invoke-Tf apply (Join-Path $run 'infra')
  if ($code -eq 0) { Remove-Item -LiteralPath $pf; Write-Host 'job apply: success' } else { Write-Host 'job apply: failure' }
}
function Approve-WfApply([string]$Name) {
  $run = (Get-Content -LiteralPath (Join-Path $GH 'pending-apply') -Raw).Trim(); Set-Content -LiteralPath "$run.approved" -Value $Name
  Write-Host "$Name approved the deployment to production"; Invoke-WfApplyJob
}
# terraform-drift: scheduled plan with -detailed-exitcode on main. Exit 2 = drift: open an issue.
function Invoke-WfDrift {
  $run = New-Run main
  Write-Host "run #$(RunNo $run)  workflow: terraform-drift  event: schedule  commit: $(Get-Head main)"
  Say 'terraform plan -detailed-exitcode'
  $lines = @(); $code = Invoke-Tf plan (Join-Path $run 'infra') -Detailed 6>&1 | ForEach-Object { if ($_ -is [Management.Automation.InformationRecord]) { $lines += "$_" } else { $_ } }
  $lines | ForEach-Object { Write-Host $_ }; Write-Host "plan exit code: $code"; Write-Lf (Join-Path $GH 'last-drift-exit') "$code"
  switch ($code) {
    0 { Write-Host 'No drift.' }
    2 { $idir = Join-Path $GH 'issues'; New-Item -ItemType Directory -Path $idir -Force | Out-Null; $n = @(Get-ChildItem -LiteralPath $idir -Filter *.md).Count + 1
        Write-Lf (Join-Path $idir "$n.md") (@('# Drift detected') + $lines); Write-Host "issue #$n opened: Drift detected" }
    default { Write-Host 'drift check failed (error)' }
  }
}
