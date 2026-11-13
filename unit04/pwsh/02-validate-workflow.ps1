# Checks the workflow file's structure locally, then shows the same check catching a broken copy.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Lint .github/workflows/config-check.yml'
if (-not (Test-Workflow '.github/workflows/config-check.yml' '.')) { exit 1 }
Step 'Lint a broken copy (a tab in front of runs-on; expected to fail)'
$broken = Join-Path $Lab 'broken-workflow.yml'
Write-Lf $broken ([IO.File]::ReadAllText((Join-Path $Laptop '.github/workflows/config-check.yml')).TrimEnd("`n").Split("`n") | ForEach-Object { $_ -replace '^    runs-on:', "`truns-on:" })
if (Test-Workflow $broken '.') { throw 'UNEXPECTED: the broken copy passed' }
Remove-Item -LiteralPath $broken
Step 'Run the check script locally, like the workflow will'
& $Pwsh -NoProfile -File scripts/check-configs.ps1 configs
