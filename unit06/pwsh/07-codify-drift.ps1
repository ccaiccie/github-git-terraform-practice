# Decision 2, codify: the team agrees VLAN 30 is now called CCTV, as set by hand. Change the code to match; the plan is empty.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Set-Location -LiteralPath $Laptop
Step 'VLAN 30 renamed to CCTV by hand, then the drift check'
Write-Switch @([pscustomobject]@{ Id = '10'; Name = 'USERS' }, [pscustomobject]@{ Id = '20'; Name = 'VOICE' }, [pscustomobject]@{ Id = '30'; Name = 'CCTV' })
Invoke-WfDrift
Step 'Codify: a pull request that renames VLAN 30 in the code'
git switch -c rename-vlan-30 2>&1
Set-Line infra/main.tf '  name    = "CAMERAS"' '  name    = "CCTV"'
git commit -q -am 'Rename VLAN 30 to CCTV (codify drift)'
git push -q -u origin rename-vlan-30 2>&1
Invoke-WfPlan rename-vlan-30
Step 'Merge, apply on main, and check again'
if (-not (Test-MergeGate rename-vlan-30)) { throw 'Merge blocked' }
git switch -q main; git pull -q 2>&1
git merge -q --no-ff rename-vlan-30 -m 'Merge pull request #2 from rename-vlan-30'
git push -q 2>&1; git push -q origin --delete rename-vlan-30 2>&1; git branch -q -d rename-vlan-30
Start-WfApply push
Approve-WfApply 'Network Lead'
Invoke-WfDrift
