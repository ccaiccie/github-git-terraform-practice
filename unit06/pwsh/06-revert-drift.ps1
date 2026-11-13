# Decision 1, revert: the hand change was not wanted. Run terraform-apply by hand on main; the code wins. Check again.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Step 'Run terraform-apply by hand (workflow_dispatch) on main'
Start-WfApply workflow_dispatch
Approve-WfApply 'Network Lead'
Step 'Drift check after the revert'
Invoke-WfDrift
