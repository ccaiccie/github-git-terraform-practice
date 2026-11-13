# Unit 5 practice: from GitHub Actions to GitLab CI/CD, offline

This practice matches the Unit 5 lesson, "GitLab compared".
A real GitLab pipeline runs on GitLab runners. Here, small helper functions **simulate** what GitLab does:
- a fresh clone for each pipeline;
- `workflow:rules` and job `rules` deciding what runs;
- stages that run in order;
- merge checks with "Pipelines must succeed", on Free and with a Premium approval rule.

Nothing contacts GitLab.

## What you will do
1. Build a lab: a **local bare repository** as the server, and your repository with the Unit 4 files (configs, check script, GitHub workflow).
2. **Translate** the GitHub workflow into a `.gitlab-ci.yml`. A local structure check catches the mistake in the first translation (a job in a stage that does not exist). Fix it, commit, push.
3. Pushing the branch alone creates **no pipeline**, because of the workflow rules. Opening the "merge request" does. The `report` job is left out of that pipeline by its own rule.
4. **Merge checks**:
   - On Free, approvals are optional, so the merge is allowed once the pipeline passes.
   - With a Premium approval rule that requires one approval, the merge is blocked until a reviewer approves.
5. After the merge, a pipeline runs **on main**: stage `test`, then stage `report`.
6. Check the structure of an **OpenTofu CI/CD component** example that uses GitLab-managed state. This step is read-only. A copy that follows `~latest` instead of a pinned release fails.

## Safe by design
- Everything lives in one throwaway folder: `~/git-course-lab/unit05` (change it with `GIT_COURSE_LAB`).
- No script contacts GitLab or any network host. No account is needed. The OpenTofu example is never run.
- Identities are set with `--local` inside the lab repository only.
- `99-cleanup` deletes only the lab folder, and only if it contains the lab's marker file.
- Trying the pipeline on real GitLab is optional and manual: `OPTIONAL-GITLAB.md`.

## Prerequisites
- Git 2.28 or later (`git --version`).
- Bash (Linux, macOS, or Git Bash on Windows) **or** PowerShell 7 (`pwsh`).

## Files
| Path | Purpose |
|---|---|
| `bash/*.sh`, `pwsh/*.ps1` | The same steps in each shell: 00 to 06, then 99-cleanup |
| `bash/lab-env.sh`, `pwsh/lab-env.ps1` | Settings plus the simulators: pipeline run, merge checks, approvals, `.gitlab-ci.yml` lint, OpenTofu example lint |
| `files/repo/` | The starting repository from Unit 4: configs, check scripts, `.github/workflows/config-check.yml` |
| `files/gitlab/starter.gitlab-ci.yml` | The first translation, with one deliberate mistake |
| `files/gitlab/opentofu-example/` | Read-only example: OpenTofu component include and an `http` backend |
| `HANDS-ON-UNIT05.md` | Step-by-step commands with expected results |
| `OPTIONAL-GITLAB.md` | Optional, manual: the same pipeline and merge checks on your own throwaway GitLab project |
| `tests/run-tests.sh` | Offline self-test of both shells (for maintainers) |

## Quick start
Bash:
```bash
cd unit05
for s in 00-check-prereqs 01-setup 02-translate 03-merge-request 04-main-pipeline 05-opentofu-example 06-verify; do bash bash/$s.sh || break; done
bash bash/99-cleanup.sh
```
PowerShell 7:
```powershell
cd unit05
foreach ($s in '00-check-prereqs','01-setup','02-translate','03-merge-request','04-main-pipeline','05-opentofu-example','06-verify') { pwsh -NoProfile -File "pwsh/$s.ps1"; if ($LASTEXITCODE) { break } }
pwsh -NoProfile -File pwsh/99-cleanup.ps1
```

## Expected result
`06-verify` prints eleven `PASS:` lines, then `RESULT: PASS`. Your commit IDs will differ from the lesson's.

## What the simulation does not do
- It does not parse YAML the way GitLab does. It understands only the simple layout used here and two rule expressions.
- It does not start runner containers and does not download the OpenTofu component.
- The lint is a basic structure check, not GitLab's CI Lint.
- Approvals and tiers are modelled as inputs; nothing is licensed or configured.

The behaviour it mirrors is what you will see on GitLab:
- which pipelines are created, and which jobs run;
- stage order;
- "Pipelines must succeed";
- optional approvals on Free versus a required approval rule on Premium.
