# Branch protection requires the check to pass, so the merge is refused. The same check, run locally, shows why.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Try to merge pull request #1 (expected to be blocked)'
if (Test-MergeGate add-vlan-40) { throw 'UNEXPECTED: merge allowed' }
Step 'Run the same check locally to see the problem'
$PSNativeCommandUseErrorActionPreference = $false
& $Pwsh -NoProfile -File scripts/check-configs.ps1 configs
$code = $LASTEXITCODE; $PSNativeCommandUseErrorActionPreference = $true
if ($code -eq 0) { throw 'UNEXPECTED: check passed' }
exit 0
