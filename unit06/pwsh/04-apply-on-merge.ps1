# The push to main starts terraform-apply. It waits for the production review; a laptop apply holds the lock; then it applies.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Step 'Push to main: terraform-apply starts'
Start-WfApply push
Step 'Meanwhile a colleague runs terraform apply on a laptop (holds the state lock)'
Write-Lf $Lock 'colleague@laptop'; Write-Host 'state locked by colleague@laptop'
Step 'Network Lead approves the production deployment'
Approve-WfApply 'Network Lead'
Step 'The laptop run finishes and releases the lock; re-run the failed job'
Remove-Item -LiteralPath $Lock; Write-Host 'state lock released'
Invoke-WfApplyJob
Step 'The live switch now'
Read-Text $Switch | ForEach-Object { Write-Host $_ }
