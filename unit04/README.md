# Unit 4 practice: GitHub Actions and pull requests, offline

This practice matches the Unit 4 lesson, "GitHub Actions and pull requests".
A real workflow runs on GitHub's servers. Here, small helper functions **simulate** what GitHub does: a fresh checkout for each run, the same check script the workflow runs, a pass/fail result stored per commit, and branch protection that refuses to merge until the check passes. Nothing contacts GitHub.

## What you will do
1. Build a lab: a **local bare repository** as the server, and your repository with router configs, a check script and a workflow file (`.github/workflows/config-check.yml`).
2. **Validate the workflow file locally** with basic structure checks, and watch the same checks catch a broken copy. Run the check script yourself.
3. Open a "pull request" whose change has a mistake (a duplicate VLAN ID). The simulated workflow run fails: a **red check**.
4. Try to merge: **blocked**, because the check is required.
5. Push a fix to the same branch. The check **runs again** on the new commit, turns green, and the merge is allowed.
6. After the merge, the workflow runs once more **on main** (a push event), including a small report step. Delete the branch.

## Safe by design
- Everything lives in one throwaway folder: `~/git-course-lab/unit04` (change it with `GIT_COURSE_LAB`).
- No script contacts GitHub or any network host. No account is needed.
- Identities are set with `--local` inside the lab repository only.
- `99-cleanup` deletes only the lab folder, and only if it contains the lab's marker file.
- Trying the workflow on real GitHub is optional and manual: `OPTIONAL-GITHUB.md`.

## Prerequisites
- Git 2.28 or later (`git --version`).
- Bash (Linux, macOS, or Git Bash on Windows) **or** PowerShell 7 (`pwsh`).
- Optional, not needed for the lab: [actionlint](https://github.com/rhysd/actionlint) for full workflow validation.

## Files
| Path | Purpose |
|---|---|
| `bash/*.sh`, `pwsh/*.ps1` | The same steps in each shell: 00 to 07, then 99-cleanup |
| `bash/lab-env.sh`, `pwsh/lab-env.ps1` | Settings plus the simulators: workflow run, required-check merge gate, workflow lint |
| `files/repo/` | The starting repository: configs, `scripts/check-configs.sh` and `.ps1`, and the workflow file |
| `HANDS-ON-UNIT04.md` | Step-by-step commands with expected results |
| `OPTIONAL-GITHUB.md` | Optional, manual: the same workflow and a required check on your own throwaway GitHub repository |
| `tests/run-tests.sh` | Offline self-test of both shells (for maintainers) |

## Quick start
Bash:
```bash
cd unit04
for s in 00-check-prereqs 01-setup 02-validate-workflow 03-open-pr-check 04-blocked-merge 05-fix-and-rerun 06-post-merge 07-verify; do bash bash/$s.sh || break; done
bash bash/99-cleanup.sh
```
PowerShell 7:
```powershell
cd unit04
foreach ($s in '00-check-prereqs','01-setup','02-validate-workflow','03-open-pr-check','04-blocked-merge','05-fix-and-rerun','06-post-merge','07-verify') { pwsh -NoProfile -File "pwsh/$s.ps1"; if ($LASTEXITCODE) { break } }
pwsh -NoProfile -File pwsh/99-cleanup.ps1
```

## Expected result
`07-verify` prints eleven `PASS:` lines, then `RESULT: PASS`. Your commit IDs will differ from the lesson's.

## What the simulation does not do
It does not run YAML through GitHub's parser, start virtual machines, or download `actions/checkout`. The lint is a basic structure check, not a full validator. The behaviour it mirrors (which events trigger the workflow, red/green checks per commit, required checks blocking a merge, reruns on new commits, a run on main after the merge) is what you will see on GitHub.
