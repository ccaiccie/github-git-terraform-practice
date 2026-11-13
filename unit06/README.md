# Unit 6 practice: Terraform automation and drift detection, offline

This practice matches the Unit 6 lesson, "Terraform automation and drift detection".

In real life, GitHub Actions runs Terraform against a cloud or a network controller. Here, nothing contacts any host or cloud:
- **The live network** is a simulated switch: a text file holding a VLAN config.
- **`tfsim`** is a small Bash/PowerShell stand-in for `terraform`. It handles a single resource type, `lab_vlan`, and supports `validate`, `plan`, `plan -detailed-exitcode` and `apply`.
  - Its plans print in Terraform's style, with the same exit codes: 0 = no changes, 1 = error, 2 = changes.
- **Remote state and its lock** are files in the lab folder.
- **GitHub** is simulated by helper functions. They create a fresh clone per run, PR comments, a required check, an environment review, and issues.

The three workflow files in `files/repo/.github/workflows/` are real GitHub Actions workflows, written for a real cloud account. AWS is the example, with OIDC login. The lab only simulates what they do.

## What you will do
1. Build the lab: a local bare repository as the server, your repository with `infra/main.tf` (VLAN 10 and 20) and three workflows, a switch, and state that matches main.
2. **Plan on a pull request.** Add VLAN 30 on a branch. `terraform-plan` validates, plans (`1 to add`) and posts the plan as a PR comment. The switch does not change.
3. **Review and merge.** Read the plan comment. The required check has passed, so you merge.
4. **Apply on merge.** `terraform-apply` waits for a review of the `production` environment.
   - A colleague's laptop apply holds the **state lock**, so the first attempt fails.
   - The lock is released, the job is re-run, and VLAN 30 is created.
5. **Drift check.** The scheduled plan with `-detailed-exitcode` returns 0.
   - Someone renames VLAN 20 by hand. The next check returns **2**, and an issue is opened.
6. **Decision 1, revert.** Run `terraform-apply` by hand. The code wins, and the drift check returns 0.
7. **Decision 2, codify.** VLAN 30 is renamed to CCTV by hand, on purpose. A pull request changes the code to match.
   - Its plan is empty, the apply changes nothing, and the drift check returns 0.

## Safe by design
- Everything lives in one throwaway folder: `~/git-course-lab/unit06` (change it with `GIT_COURSE_LAB`).
- No script contacts GitHub, a Terraform registry, a cloud or any network host. Terraform does not need to be installed. No account is needed.
- Identities are set with `--local` inside the lab repository only.
- `99-cleanup` deletes only the lab folder, and only if it contains the lab's marker file.
- Trying the workflows on real GitHub is optional and manual: `OPTIONAL-GITHUB.md`.

## Prerequisites
- Git 2.28 or later.
- Bash (Linux, macOS, or Git Bash on Windows) **or** PowerShell 7 (`pwsh`).

## Files
| Path | Purpose |
|---|---|
| `bash/*.sh`, `pwsh/*.ps1` | The same steps in each shell: 00 to 08, then 99-cleanup |
| `bash/lab-env.sh`, `pwsh/lab-env.ps1` | Settings, `tfsim`, and the simulated plan, apply and drift workflows |
| `files/repo/infra/main.tf` | The Terraform code: two `lab_vlan` resources |
| `files/repo/.github/workflows/` | `terraform-plan.yml`, `terraform-apply.yml`, `terraform-drift.yml` |
| `HANDS-ON-UNIT06.md` | Step-by-step commands with expected results |
| `OPTIONAL-GITHUB.md` | Optional, manual: running the real workflows |
| `tests/run-tests.sh` | Offline self-test of both shells (for maintainers) |

## Quick start
Bash:
```bash
cd unit06
for s in 00-check-prereqs 01-setup 02-plan-on-pr 03-review-and-merge 04-apply-on-merge 05-drift-check 06-revert-drift 07-codify-drift 08-verify; do bash bash/$s.sh || break; done
bash bash/99-cleanup.sh
```
PowerShell 7:
```powershell
cd unit06
foreach ($s in '00-check-prereqs','01-setup','02-plan-on-pr','03-review-and-merge','04-apply-on-merge','05-drift-check','06-revert-drift','07-codify-drift','08-verify') { pwsh -NoProfile -File "pwsh/$s.ps1"; if ($LASTEXITCODE) { break } }
pwsh -NoProfile -File pwsh/99-cleanup.ps1
```

## Expected result
`08-verify` prints twelve `PASS:` lines, then `RESULT: PASS`.

## What the simulation does not do
- `tfsim` is not Terraform. It reads only the simple `lab_vlan` blocks used here.
- Its state is a plain text file, not Terraform's JSON.
- It does not download providers, talk to a backend, or use real credentials.
- The terminal shows `terraform ...` for readability; those commands are run by `tfsim`.

The behaviour it mirrors is what you will see with real Terraform and GitHub Actions:
- plan output and the `-detailed-exitcode` codes;
- state locking;
- plan comments, required checks and environment reviews;
- scheduled drift checks that open issues.
