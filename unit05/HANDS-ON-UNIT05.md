# Hands-on: Unit 5, step by step

Run the scripts in order, from the `unit05` folder.
- Bash: `bash bash/NN-name.sh`
- PowerShell 7: `pwsh -NoProfile -File pwsh/NN-name.ps1`

Both shells print the same lines. Commit IDs will differ.

## 00-check-prereqs
Checks Git 2.28 or later and shows the lab folder.

Expected: `PASS: Git 2.xx is new enough`.

## 01-setup
Creates the bare "server" repository and your laptop clone with the Unit 4 files.

Expected file list:
- `.github/workflows/config-check.yml`
- `README.md`
- `configs/edge-router.cfg`
- `scripts/check-configs.ps1`
- `scripts/check-configs.sh`

## 02-translate
Creates branch `move-to-gitlab-ci` and copies in `files/gitlab/starter.gitlab-ci.yml` as `.gitlab-ci.yml`.

How the GitHub workflow maps to the new file:

| GitHub Actions (Unit 4) | GitLab CI/CD (this file) |
|---|---|
| `on: pull_request` / `push` to main | `workflow: rules:` with `merge_request_event` / the default branch |
| `jobs: validate:` with `runs-on` | job `validate:` in a stage; the runner picks it up, `default: image:` sets the container |
| `steps:` with `actions/checkout` | not needed: the runner clones the repository for every job |
| `run:` | `script:` |
| `if: github.event_name == 'push'` | `report` job with its own `rules:` (default branch only) |

The lint then runs:
1. **First run.** Expected: `FAIL: job validate: stage 'check' is not listed in stages`, then `RESULT: FAIL`.
2. **The fix.** The script changes `stage: check` to `stage: test`.
3. **Second run.** Expected: `RESULT: PASS`.

Finally the change is committed as `Add GitLab CI/CD pipeline` and pushed.

## 03-merge-request
1. **Branch push only.** Expected: `no pipeline created (workflow rules)`.
2. **Merge request opened.** Expected:
   - `pipeline #1  source: merge_request_event`
   - `job validate: passed`
   - `job report: not in this pipeline (rules)`
   - `pipeline #1: passed`
3. **Merge checks on Free.** Expected: `approvals: 0 given, optional on Free`, then `Ready to merge`.
4. **Premium approval rule (1 required).** Expected: `approval rule: 0 of 1 required`, then `Merge blocked`.
5. **Approve, then check again.** Expected: `approval rule: 1 of 1 required`, then `Ready to merge`.
6. **Merge.** Main gets the merge commit `Merge branch 'move-to-gitlab-ci' into 'main'`.

## 04-main-pipeline
Runs the pipeline on main (source `push`).

Expected:
- `stages: test report`
- `job validate: passed`
- `job report (stage report):` followed by the VLAN line count `1`
- `pipeline #2: passed`

Then the branch is deleted and the history on main is shown.

## 05-opentofu-example
Prints `files/gitlab/opentofu-example/.gitlab-ci.yml` and checks its structure:
- it includes the component;
- the component is pinned to `5.1.0`, and `inputs.version` matches the pin;
- the stages are `validate`, `build`, `deploy`;
- `backend.tf` has an `http` backend.

Expected: `RESULT: PASS`. Then a copy using `@~latest` must fail with `found '@~latest'`. Nothing is run.

## 06-verify
Expected: eleven `PASS:` lines and `RESULT: PASS`.

## 99-cleanup
Removes `~/git-course-lab/unit05`, only if it carries the lab marker.

## Notes
- **GitLab Free merge request pipelines** test the source branch as it is. Testing the merged result (a "merged results pipeline") needs Premium or Ultimate. GitHub Actions tests the merge result for pull requests by default (Unit 4).
- **Why pin the component?** A pinned release changes only when you change it, in a reviewed merge request. That is the same reason Unit 4 pinned `actions/checkout@v7`.
