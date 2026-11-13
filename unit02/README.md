# Unit 2 practice: push, fetch and pull

This practice matches the Unit 2 lesson, "Push, fetch and pull".

## What you will do
1. Create a **local bare repository** that plays the server (GitHub or GitLab), then connect it as `origin` and push with `-u`.
2. Clone it as a "colleague".
3. The colleague pushes. You **fetch** (download only), look, then **pull** (fetch + merge).
4. Both sides commit. Your push is **rejected**. You pull (merge), then push again.
5. Push a new branch with `-u`. This is the starting point for a pull request in Unit 3.

## Safe by design
- Everything lives in one throwaway folder: `~/git-course-lab/unit02`. You can change it with the `GIT_COURSE_LAB` environment variable.
- The "server" is a folder, so nothing goes to the internet and no account is needed.
- Identities are set with `--local` inside the lab repositories only. Your global Git settings are never touched.
- `99-cleanup` deletes only the lab folder, and only if it contains the lab's marker file.
- Pushing to a real GitHub repository is a separate, optional step in `OPTIONAL-GITHUB.md`. No script does it.

## Prerequisites
- Git 2.28 or later (`git --version`).
- Bash (Linux, macOS, or Git Bash on Windows) **or** PowerShell 7 (`pwsh`).

## Files
| Path | Purpose |
|---|---|
| `bash/*.sh`, `pwsh/*.ps1` | The same steps in each shell: 00 to 06, then 99-cleanup |
| `files/edge-router.cfg` | Example device configuration (documentation IP ranges) |
| `HANDS-ON-UNIT02.md` | Step-by-step commands with expected results |
| `OPTIONAL-GITHUB.md` | Optional: the same flow against your own throwaway GitHub repository |
| `tests/run-tests.sh` | Offline self-test of both shells (for maintainers) |

## Quick start
Bash:
```bash
cd unit02
for s in 00-check-prereqs 01-create-remote-and-push 02-clone 03-fetch-and-pull 04-rejected-push 05-push-a-branch 06-verify; do bash bash/$s.sh || break; done
bash bash/99-cleanup.sh
```
PowerShell 7:
```powershell
cd unit02
foreach ($s in '00-check-prereqs','01-create-remote-and-push','02-clone','03-fetch-and-pull','04-rejected-push','05-push-a-branch','06-verify') { pwsh -NoProfile -File "pwsh/$s.ps1"; if ($LASTEXITCODE) { break } }
pwsh -NoProfile -File pwsh/99-cleanup.ps1
```

## Expected result
`06-verify` prints thirteen `PASS:` lines, then `RESULT: PASS`. Your commit IDs will differ from the lesson's.
