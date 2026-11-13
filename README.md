# GitHub, Git and Terraform for Network Engineers

Practice files for a six-unit course on Git, GitHub, GitLab, and Terraform for network engineers.

https://www.youtube.com/playlist?list=PLYlnG0vk5f1Y

## Units

| Unit | Title | Folder |
| --- | --- | --- |
| 1 | Branches and merge | [unit01](unit01/) |
| 2 | Push, fetch and pull | [unit02](unit02/) |
| 3 | Pull requests and GitLab merge requests | [unit03](unit03/) |
| 4 | GitHub Actions and pull requests | [unit04](unit04/) |
| 5 | GitLab compared | [unit05](unit05/) |
| 6 | Terraform automation and drift detection | [unit06](unit06/) |

## How to run the labs

Each unit README is the source for these steps. The labs stay on your machine. You need Git 2.28 or later, and either Bash (Linux, macOS, WSL, or Git Bash on Windows) or PowerShell 7 (`pwsh`). The numbered scripts use a throwaway folder, `~/git-course-lab/unitNN` (on Windows, `%USERPROFILE%\git-course-lab\unitNN`). Set `GIT_COURSE_LAB` to use a different parent folder. They set `user.name` and `user.email` with `git config --local` inside the lab repository only. `99-cleanup` deletes that folder only when the lab's marker file is present. A second cleanup run is a no-op.

Steps that use a real GitHub or GitLab project are optional and manual. They are in `OPTIONAL-GITHUB.md` or `OPTIONAL-GITLAB.md` in the unit that has them. Typing the commands yourself from the unit's `HANDS-ON-UNIT0N.md` file is the better way to learn. Otherwise, change into the unit folder and run the numbered scripts in order, then cleanup.

Bash, Unit 1:

```bash
cd unit01
bash bash/00-check-prereqs.sh
for s in 01-create-lab 02-first-commit 03-second-commit-and-history 04-branch-and-fast-forward 05-diverge-and-merge-commit 06-verify; do bash "bash/$s.sh"; done
bash bash/99-cleanup.sh
```

Bash, Units 2 through 6, using Unit 2 as the example. The loop includes the prerequisite check and stops if a script fails:

```bash
cd unit02
for s in 00-check-prereqs 01-create-remote-and-push 02-clone 03-fetch-and-pull 04-rejected-push 05-push-a-branch 06-verify; do bash bash/$s.sh || break; done
bash bash/99-cleanup.sh
```

PowerShell 7, Unit 1:

```powershell
cd unit01
pwsh ./pwsh/00-check-prereqs.ps1
'01-create-lab','02-first-commit','03-second-commit-and-history','04-branch-and-fast-forward','05-diverge-and-merge-commit','06-verify' | ForEach-Object { pwsh "./pwsh/$_.ps1" }
pwsh ./pwsh/99-cleanup.ps1
```

PowerShell 7, Units 2 through 6, using Unit 2 as the example:

```powershell
cd unit02
foreach ($s in '00-check-prereqs','01-create-remote-and-push','02-clone','03-fetch-and-pull','04-rejected-push','05-push-a-branch','06-verify') { pwsh -NoProfile -File "pwsh/$s.ps1"; if ($LASTEXITCODE) { break } }
pwsh -NoProfile -File pwsh/99-cleanup.ps1
```

Use the script names for that unit. Bash files are `bash/<name>.sh`. PowerShell 7 files are `pwsh/<name>.ps1`.

| Unit | Scripts, in order, then `99-cleanup` |
| --- | --- |
| 1 | `00-check-prereqs`, `01-create-lab`, `02-first-commit`, `03-second-commit-and-history`, `04-branch-and-fast-forward`, `05-diverge-and-merge-commit`, `06-verify` |
| 2 | `00-check-prereqs`, `01-create-remote-and-push`, `02-clone`, `03-fetch-and-pull`, `04-rejected-push`, `05-push-a-branch`, `06-verify` |
| 3 | `00-check-prereqs`, `01-setup`, `02-open-pr-branch`, `03-merge-buttons`, `04-conflict`, `05-after-merge`, `06-verify` |
| 4 | `00-check-prereqs`, `01-setup`, `02-validate-workflow`, `03-open-pr-check`, `04-blocked-merge`, `05-fix-and-rerun`, `06-post-merge`, `07-verify` |
| 5 | `00-check-prereqs`, `01-setup`, `02-translate`, `03-merge-request`, `04-main-pipeline`, `05-opentofu-example`, `06-verify` |
| 6 | `00-check-prereqs`, `01-setup`, `02-plan-on-pr`, `03-review-and-merge`, `04-apply-on-merge`, `05-drift-check`, `06-revert-drift`, `07-codify-drift`, `08-verify` |

The last verify script prints `PASS:` lines and then `RESULT: PASS`. Commit IDs differ from the lesson because each hash includes the content, the author, and the time.
