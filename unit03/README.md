# Unit 3 practice: pull requests and merge requests, offline

This practice matches the Unit 3 lesson, "Pull requests on GitHub and GitLab merge requests".
A pull request (GitHub) or merge request (GitLab) is a web page around normal Git operations. This lab runs those Git operations locally, so you can see exactly what each button does.

## What you will do
1. Build a lab: a **local bare repository** as the server, your laptop clone, and a colleague clone.
2. Create a feature branch with two commits and push it: the work behind a pull request. Read it the way a PR shows it (`main..branch` commits, `main...branch` diff).
3. Mirror GitHub's three merge buttons on throwaway branches: **merge commit**, **squash**, **rebase**. Then really merge PR #1 with a merge commit.
4. You and the colleague change the **same line**. Get a real **merge conflict**, read the markers, resolve it locally, push, and merge PR #2.
5. After merging: delete the branches on the server and locally, switch to main, pull, and prune.

## Safe by design
- Everything lives in one throwaway folder: `~/git-course-lab/unit03` (change it with `GIT_COURSE_LAB`).
- The "server" is a folder. No script contacts GitHub, GitLab or any network host, and no account is needed.
- Identities are set with `--local` inside the lab repositories only. Your global Git settings are never touched.
- `99-cleanup` deletes only the lab folder, and only if it contains the lab's marker file.
- Trying a real pull request or merge request is optional and manual: `OPTIONAL-GITHUB.md`, `OPTIONAL-GITLAB.md`.

## Prerequisites
- Git 2.28 or later (`git --version`).
- Bash (Linux, macOS, or Git Bash on Windows) **or** PowerShell 7 (`pwsh`).

## Files
| Path | Purpose |
|---|---|
| `bash/*.sh`, `pwsh/*.ps1` | The same steps in each shell: 00 to 06, then 99-cleanup |
| `files/edge-router.cfg` | Example device configuration (documentation IP ranges) |
| `HANDS-ON-UNIT03.md` | Step-by-step commands with expected results |
| `OPTIONAL-GITHUB.md` | Optional, manual: a real pull request in your own throwaway GitHub repository |
| `OPTIONAL-GITLAB.md` | Optional, manual: a real merge request in your own throwaway GitLab project |
| `tests/run-tests.sh` | Offline self-test of both shells (for maintainers) |

## Quick start
Bash:
```bash
cd unit03
for s in 00-check-prereqs 01-setup 02-open-pr-branch 03-merge-buttons 04-conflict 05-after-merge 06-verify; do bash bash/$s.sh || break; done
bash bash/99-cleanup.sh
```
PowerShell 7:
```powershell
cd unit03
foreach ($s in '00-check-prereqs','01-setup','02-open-pr-branch','03-merge-buttons','04-conflict','05-after-merge','06-verify') { pwsh -NoProfile -File "pwsh/$s.ps1"; if ($LASTEXITCODE) { break } }
pwsh -NoProfile -File pwsh/99-cleanup.ps1
```

## Expected result
`06-verify` prints ten `PASS:` lines, then `RESULT: PASS`. Your commit IDs will differ from the lesson's.
