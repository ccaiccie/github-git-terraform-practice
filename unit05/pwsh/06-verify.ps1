# Verifies the finished lab.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
git -C $Laptop fetch -q --prune
$script:fail = $false
function Check([string]$Name, [scriptblock]$Test) { if (& $Test) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:fail = $true } }
$br = git -C $Remote log --format=%H '--grep=^Add GitLab CI/CD pipeline$' main
$mainh = git -C $Remote rev-parse main
$ci = (git -C $Remote show main:.gitlab-ci.yml) -join "`n"
$st = { param($h) $f = Join-Path $Pipes $h; if (Test-Path -LiteralPath $f) { (Get-Content -LiteralPath $f -Raw).Trim() } else { '' } }
Check 'main has .gitlab-ci.yml'                    { git -C $Remote cat-file -e main:.gitlab-ci.yml; $LASTEXITCODE -eq 0 }
Check 'main still has the GitHub workflow'         { git -C $Remote cat-file -e main:.github/workflows/config-check.yml; $LASTEXITCODE -eq 0 }
Check 'validate job is in stage test'              { $ci -cmatch '(?m)^  stage: test$' }
Check 'merge request pipeline passed'              { (& $st $br) -eq 'passed' }
Check 'one approval recorded'                      { $f = Join-Path $Approvals $br; (Test-Path -LiteralPath $f) -and @(Get-Content -LiteralPath $f).Count -eq 1 }
Check 'pipeline on main passed'                    { (& $st $mainh) -eq 'passed' }
Check 'two pipelines ran (MR, then main)'          { @(Get-ChildItem -LiteralPath $Runner -Directory).Count -eq 2 }
Check 'one MR merge commit on main'                { @(git -C $Remote log --merges --oneline "--grep=^Merge branch .move-to-gitlab-ci. into .main.$" main).Count -eq 1 }
Check 'only main is left on the server'            { (git -C $Remote for-each-ref '--format=%(refname:short)' refs/heads) -eq 'main' }
Check 'laptop working tree clean'                  { -not (git -C $Laptop status --porcelain) }
Check 'origin URL is a local path'                 { (git -C $Laptop remote get-url origin) -notmatch '^(https?|ssh|git)://|@' }
if ($script:fail) { Write-Host 'RESULT: FAIL'; exit 1 } else { Write-Host 'RESULT: PASS' }
