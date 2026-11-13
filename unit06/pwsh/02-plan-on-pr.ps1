# A pull request that adds VLAN 30: the plan workflow validates, plans and posts the plan. Nothing changes on the switch.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'Branch add-vlan-30: add a lab_vlan resource'
git switch -c add-vlan-30 2>&1
Write-Lf infra/main.tf @('', 'resource "lab_vlan" "cameras" {', '  vlan_id = 30', '  name    = "CAMERAS"', '}') -Append
git commit -q -am 'Add VLAN 30 for cameras'
git push -q -u origin add-vlan-30 2>&1
git log --oneline -1
Step 'Pull request #1 opened: terraform-plan runs'
Invoke-WfPlan add-vlan-30
Step 'A plan changes nothing: the switch still has no VLAN 30'
if (@(Read-Text $Switch | Where-Object { $_ -ceq 'vlan 30' }).Count) { throw 'UNEXPECTED: VLAN 30 exists' }
Read-Text $Switch | Where-Object { $_ -like 'vlan*' } | ForEach-Object { Write-Host $_ }
