# Hands-on guide: Unit 1, branches and merge

Every command below works in **Bash and PowerShell 7** unless a step shows two versions. Git commands are identical in both shells. Only file editing differs, and the scripts in `bash/` and `pwsh/` do that part for you.

Commit IDs in the expected output are examples. Yours will differ.

---

## Step 0: check prerequisites
Script: `bash/00-check-prereqs.sh` or `pwsh/00-check-prereqs.ps1`
```
git --version
```
**Expected:** `git version 2.x.y` with x of 28 or more. The script prints `PASS: Git 2.NN is new enough`.
**Why it matters:** `git init -b` (2.28) and `git switch` (2.23) are used throughout the course.

## Step 1: create the repository
Script: `01-create-lab`
```
git init -b main
git config --local user.name  "Lab Student"
git config --local user.email "student@example.com"
git status
```
**Expected:** `Initialized empty Git repository in …/network-configs/.git/`, then `On branch main`, `No commits yet`.

**What it does:**
- `init` creates the hidden `.git` database, and `-b main` names the first branch.
- `--local` stores the identity only in this repository. On your own machine you would normally set it once with `--global`.

**Why it matters:** every tracked project starts with `init`, or with a `clone`, which is covered in Unit 2.

## Step 2: the three states and the first commit
Script: `02-first-commit`. It copies `files/edge-router.cfg` into `configs/` and writes a two-line `README.md`.
```
git status --short
git add README.md configs/edge-router.cfg
git status --short
git commit -m "Add edge router baseline config"
git log --oneline --decorate
```
**Expected:**
- the first status shows `?? README.md` and `?? configs/` (untracked);
- after `add`, it shows `A  README.md` and `A  configs/edge-router.cfg` (staged);
- the commit prints `[main (root-commit) eee7114] Add edge router baseline config`;
- `git log` prints `eee7114 (HEAD -> main) Add edge router baseline config`.

**Why it matters:** `git status` tells you which of the three places each change is in. Run it often.

## Step 3: two more commits on main
Script: `03-second-commit-and-history`. It adds `ntp server 198.51.100.123` after the first NTP line, copies `files/gitignore-example` to `.gitignore`, and creates a fake `secrets/enable.key`.
```
git diff
git add configs/edge-router.cfg
git commit -m "Add second NTP server"
git status --short
git add .gitignore
git commit -m "Ignore secrets, backups and editor files"
git log --oneline --decorate
```
**Expected:**
- `git diff` shows `+ntp server 198.51.100.123`;
- `git status --short` lists only `?? .gitignore`, and the secret file is not mentioned at all;
- the log shows three commits.

**Note:** the `.gitignore` file keeps the fake secret out of Git. Ignore rules do not remove anything already committed.

## Step 4: branch, commit and fast-forward merge
Script: `04-branch-and-fast-forward`. It appends `vlan 20 / name VOICE` to the config.
```
git switch -c add-vlan-20
git add configs/edge-router.cfg
git commit -m "Add VLAN 20 for voice"
git log --oneline --graph --all --decorate
git switch main
git merge add-vlan-20
git branch -d add-vlan-20
```
**Expected:**
- the graph shows `(HEAD -> add-vlan-20)` on the new commit, and `(main)` one commit behind;
- the merge prints `Updating 09d08f4..02c2e71` and then `Fast-forward`;
- `git branch -d` prints `Deleted branch add-vlan-20 (was 02c2e71)`.

**Why it matters:**
- A commit moves only the branch that HEAD points to.
- A fast forward just slides `main` forward, with no new commit.
- Deleting a branch removes the name, not the commits.

## Step 5: diverge and create a merge commit
Script: `05-diverge-and-merge-commit`. On `update-ntp` it replaces the second NTP server with `203.0.113.123`. On `main` it adds an ownership line to `README.md`.
```
git switch -c update-ntp
git commit -am "Replace second NTP server"
git switch main
git commit -am "Document repository ownership"
git log --oneline --graph --all --decorate
git merge --no-edit update-ntp
git branch -d update-ntp
git log --oneline --graph --all --decorate
```
**Expected:**
- the graph splits into two lines after `Add VLAN 20 for voice`;
- the merge prints `Merge made by the 'ort' strategy.`;
- the final graph shows the two lines joining in `Merge branch 'update-ntp'`.

**Why it matters:**
- When both sides move, Git records a merge commit with two parents.
- The two sides changed different files here, so Git combined them by itself.
- Changes to the same lines would cause a merge conflict, which Unit 3 covers.
- `-a` on `git commit` stages already-tracked files for you.

## Step 6: verify
Script: `06-verify`
**Expected:** eleven `PASS:` lines, then `RESULT: PASS`. The checks are:
- you are on branch main;
- there are 7 commits;
- exactly one of them is a merge commit, and it has two parents;
- VLAN 20 and the new NTP server are both present;
- the secret is ignored and was never committed;
- the working tree is clean;
- main is the only branch;
- no remote is configured.

## Cleanup
Script: `99-cleanup`. It deletes `~/git-course-lab/unit01` only when the marker file `.git-course-unit01` is present. Running it twice is safe.

## Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| `git: command not found`, or `git` is not recognized | Git is not installed or not on PATH | Install Git from git-scm.com, or with your package manager, then open a new terminal. |
| `error: unknown switch 'b'` on `git init` | Git is older than 2.28 | Upgrade Git. |
| `ERROR: … already exists; refusing to overwrite` | A previous lab is still there | Run `99-cleanup`, then start again. |
| PowerShell says running scripts is disabled | Windows execution policy | Run the scripts with `pwsh -ExecutionPolicy Bypass -File .\pwsh\01-create-lab.ps1`. This applies to that one process only. |
| `warning: LF will be replaced by CRLF` | Windows line-ending conversion | Harmless. The lab repository sets `core.autocrlf false` locally. |
