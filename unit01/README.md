# Unit 1 practice: branches and merge

Matches the Unit 1 lesson, "Branches and merge".

## What you will do
1. Create a brand-new local Git repository called `network-configs`.
2. Record commits for a router configuration.
3. Read the history (a `.gitignore` keeps a fake secret out of Git).
4. Create a branch and merge it back twice: first as a fast forward, then as a real merge commit.

## Safe by design
- **Local only.** No account, no Git Hub, no remote and no network access are needed. Nothing is pushed anywhere.
- **Throwaway folder.** Everything happens in `~/git-course-lab/unit01`. On Windows that is `%USERPROFILE%\git-course-lab\unit01`. Set the environment variable `GIT_COURSE_LAB` to use a different parent folder.
- **Lab-only identity.** The scripts set `user.name` / `user.email` with `git config --local`, inside the lab repository only. Your global Git settings are never read or changed. `06-verify` checks that no remote exists.
- **No overwrite.** `01-create-lab` refuses to run if the lab folder already exists.
- **Guarded cleanup.** `99-cleanup` deletes the lab folder only if it contains the lab's marker file. It refuses anything else.

## Prerequisites
- Git **2.28 or later**. `git init -b` needs 2.28 and `git switch` needs 2.23. Check with `git --version`.
- **Either** Bash (Linux, macOS, WSL or Git Bash on Windows) **or** PowerShell 7 (`pwsh`) on Windows, macOS or Linux.
- About 5 minutes and a few kilobytes of disk space.

## Files
| Path | Purpose |
|---|---|
| `HANDS-ON-UNIT01.md` | Step-by-step guide with every command, the expected result and why it matters. |
| `bash/00-check-prereqs.sh` … `bash/06-verify.sh`, `bash/99-cleanup.sh` | Bash version of each step. `lab-env.sh` holds the shared settings. |
| `pwsh/00-check-prereqs.ps1` … `pwsh/06-verify.ps1`, `pwsh/99-cleanup.ps1` | PowerShell 7 version of each step. `lab-env.ps1` holds the shared settings. |
| `files/edge-router.cfg` | Starting router configuration. It uses documentation-only addresses: 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24. |
| `files/gitignore-example` | The complete `.gitignore` shown in the lesson. |
| `tests/run-tests.sh` | Offline self-test of both script sets in a temporary home folder. For maintainers. |

## Quick start
Bash:
```bash
cd unit01
bash bash/00-check-prereqs.sh
for s in 01-create-lab 02-first-commit 03-second-commit-and-history 04-branch-and-fast-forward 05-diverge-and-merge-commit 06-verify; do bash "bash/$s.sh"; done
bash bash/99-cleanup.sh
```
PowerShell 7:
```powershell
cd unit01
pwsh ./pwsh/00-check-prereqs.ps1
'01-create-lab','02-first-commit','03-second-commit-and-history','04-branch-and-fast-forward','05-diverge-and-merge-commit','06-verify' | ForEach-Object { pwsh "./pwsh/$_.ps1" }
pwsh ./pwsh/99-cleanup.ps1
```
Running the scripts one at a time and reading the output is the better way to learn. Better still, type the commands yourself from `HANDS-ON-UNIT01.md`.

## Expected result
`06-verify` prints eleven `PASS:` lines and then `RESULT: PASS`. The final history looks like this, though your commit IDs will be different:
```
*   80906fa (HEAD -> main) Merge branch 'update-ntp'
|\
| * bac6c03 Replace second NTP server
* | a9f1b5b Document repository ownership
|/
* 02c2e71 Add VLAN 20 for voice
* 09d08f4 Ignore secrets, backups and editor files
* ae794a2 Add second NTP server
* eee7114 Add edge router baseline config
```
Commit IDs are hashes of content, author and time, so yours differ from the lesson's. That is expected.

## Cleanup
Run `bash/99-cleanup.sh` or `pwsh/99-cleanup.ps1`. Running it a second time is a harmless no-op.
