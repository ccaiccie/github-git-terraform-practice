# Hands-on: Unit 6, step by step

Run the scripts in order, from the `unit06` folder.
- Bash: `bash bash/NN-name.sh`
- PowerShell 7: `pwsh -NoProfile -File pwsh/NN-name.ps1`

Both shells print the same lines. Commit IDs will differ.

| Script | What happens | Expected |
|---|---|---|
| 00-check-prereqs | Checks Git | `PASS: Git 2.xx is new enough` |
| 01-setup | Builds repo, switch and state | The file list, then VLAN 10 USERS and 20 VOICE on the switch |
| 02-plan-on-pr | Branch `add-vlan-30`, then `terraform-plan` on pull request #1 | `Success! The configuration is valid.`, `Plan: 1 to add, 0 to change, 0 to destroy.`, `comment posted on the pull request`, `check terraform-plan / plan: success`. The switch still shows only VLAN 10 and 20 |
| 03-review-and-merge | Shows the plan comment, then checks and merges | `### terraform plan for <commit>`, `Merge allowed` |
| 04-apply-on-merge | Apply waits for review; the lock blocks the first try; a re-run applies | `job apply is waiting for review: environment production`, `Error: Error acquiring the state lock`, then `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` The switch shows VLAN 30 |
| 05-drift-check | Scheduled plan with `-detailed-exitcode`, then a hand change and a second check | `plan exit code: 0`, `No drift.` Then `Note: Objects have changed outside of Terraform`, `~ name: "VOICE" -> "VOICE-TEMP"`, `plan exit code: 2`, `issue #1 opened: Drift detected` |
| 06-revert-drift | Runs `terraform-apply` by hand (workflow_dispatch) and approves it | `Apply complete! Resources: 0 added, 1 changed, 0 destroyed.`, then `plan exit code: 0` |
| 07-codify-drift | VLAN 30 renamed to CCTV by hand, then a pull request changes the code to match | `plan exit code: 2`, `issue #2 opened`. The PR plan says `No changes.` The apply reports `0 added, 0 changed, 0 destroyed`. The final drift check gives `plan exit code: 0` |
| 08-verify | Checks the finished lab | Twelve `PASS:` lines, then `RESULT: PASS` |
| 99-cleanup | Removes `~/git-course-lab/unit06` (only if marked) | `Removed ...` |

## Exit codes of `terraform plan -detailed-exitcode`
| Code | Meaning | What the drift workflow does |
|---|---|---|
| 0 | No changes: the live network matches the code | Nothing |
| 1 | Error | The job fails (red) |
| 2 | Changes present: drift, or code that has not been applied yet | Opens an issue with the plan |

## Revert or codify?
- **Revert:** the hand change was a mistake or a temporary fix. Re-apply main, and the code wins.
- **Codify:** the hand change should stay. Change the code in a pull request until the plan is empty, then merge.
