# The scheduled drift check: exit code 0 (no drift). Then someone renames VLAN 20 by hand: exit code 2, an issue is opened.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
Step 'Scheduled drift check (06:17)'
Invoke-WfDrift
Step 'During an incident, someone renames VLAN 20 on the switch by hand'
Write-Switch @([pscustomobject]@{ Id = '10'; Name = 'USERS' }, [pscustomobject]@{ Id = '20'; Name = 'VOICE-TEMP' }, [pscustomobject]@{ Id = '30'; Name = 'CAMERAS' })
$t = Read-Text $Switch; $i = [array]::IndexOf($t, 'vlan 20'); Write-Host $t[$i]; Write-Host $t[$i + 1]
Step 'Next scheduled drift check'
Invoke-WfDrift
