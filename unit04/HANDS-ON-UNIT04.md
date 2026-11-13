# Hands-on guide: Unit 4, GitHub Actions and pull requests

Commands work in **Bash and PowerShell 7**. The scripts call small simulator functions from `lab-env`: `ci_run` / `Invoke-CiRun` (one workflow run), `merge_gate` / `Test-MergeGate` (branch protection with a required check) and `lint_workflow` / `Test-Workflow`. Commit IDs are examples; yours will differ.

## Step 1: the repository
Script: `01-setup`. **Expected:**
```
.github/workflows/config-check.yml
README.md
configs/edge-router.cfg
scripts/check-configs.ps1
scripts/check-configs.sh
```
The workflow file runs `scripts/check-configs.sh` on pull requests to main and on pushes to main.

## Step 2: validate the workflow locally
Script: `02-validate-workflow`. **Expected:** eight `PASS:` lines for the real file. For the broken copy:
```
FAIL: tab character on line 16 (YAML indentation must use spaces)
FAIL: jobs: 1, runs-on: 0, steps: 1 (each job needs both)
RESULT: FAIL
```
**Why it matters:** a broken workflow file never produces a check at all, so catch mistakes before you push. For full validation use `actionlint` (optional).

## Step 3: a pull request with a mistake
Script: `03-open-pr-check`. The branch adds a guest VLAN but reuses ID 10. **Expected:**
```
run #1  workflow: config-check  job: validate  event: pull_request  commit: 57a8456
FAIL configs/edge-router.cfg:11: duplicate VLAN 10 (first defined on line 7)
RESULT: FAIL (1 file(s) checked)
check config-check / validate: failure
```

## Step 4: the merge is blocked
Script: `04-blocked-merge`. **Expected:**
```
required check config-check / validate on 57a8456: failure
Merging is blocked: the required check has not passed
```
Run the check yourself (`bash scripts/check-configs.sh configs`) to see the same message the check shows on GitHub.

## Step 5: push a fix, the check reruns
Script: `05-fix-and-rerun`. **Expected:**
```
run #2  workflow: config-check  job: validate  event: pull_request  commit: 1482669
PASS configs/edge-router.cfg
RESULT: PASS (1 file(s) checked)
check config-check / validate: success
required check config-check / validate on 1482669: success
Merge allowed
```
**Why it matters:** checks belong to a commit. A new commit gets a new run, and only its result counts.

## Step 6: after the merge
Script: `06-post-merge`. **Expected:**
```
run #3  workflow: config-check  job: validate  event: push  commit: ce94700
PASS configs/edge-router.cfg
RESULT: PASS (1 file(s) checked)
Config report: VLAN lines
2
check config-check / validate: success
```

## Step 7: verify, then clean up
`07-verify` prints eleven `PASS:` lines and `RESULT: PASS`. `99-cleanup` removes the lab folder.
