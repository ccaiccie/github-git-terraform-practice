# Hands-on guide: Unit 3, pull requests and merge requests

Every command below works in **Bash and PowerShell 7**. Git commands are identical in both shells. The scripts also do the small file edits for you.

The lab has three repositories: `server/network-configs.git` (bare, the stand-in for GitHub or GitLab), `laptop/network-configs` (you) and `colleague/network-configs` (a teammate). Commit IDs in the expected output are examples; yours will differ.

## Step 0 and 1: prerequisites and lab
Scripts: `00-check-prereqs`, `01-setup`. **Expected:** `PASS: Git ...` and one shared commit.

## Step 2: the branch behind a pull request
Script: `02-open-pr-branch`.
```
git switch -c add-vlan-30
# edit, commit twice
git push -u origin add-vlan-30
git log --oneline main..add-vlan-30     # the PR's Commits tab
git diff main...add-vlan-30             # the PR's Files changed tab
```
**Expected:**
```
7c9b2c1 Fix VLAN 30 name
d2b329f Add VLAN 30 for cameras
 ntp server 192.0.2.123
+vlan 30
+ name CAMERAS
+!
```
**Why it matters:** a pull request compares the head branch with the base branch. Two dots list the commits only on the branch. Three dots show the changes since the branch split off, which is what the PR's diff shows.

On GitHub you would now click **Compare & pull request**, or run `gh pr create --base main --head add-vlan-30 --fill` (add `--draft` for a draft). On GitLab, **Create merge request**.

## Step 3: the three merge buttons, locally
Script: `03-merge-buttons`. The colleague first adds a commit to main, so the histories differ. Each button is tried on a throwaway branch.

| GitHub button | Local equivalent | Result on main |
|---|---|---|
| Create a merge commit | `git merge --no-ff add-vlan-30` | all branch commits plus one merge commit |
| Squash and merge | `git merge --squash add-vlan-30` then `git commit` | one new commit with all the changes |
| Rebase and merge | `git rebase main` on the branch, then fast-forward | the branch commits replayed on top, with **new IDs** |

**Expected (rebase):**
```
7c9b2c1 Fix VLAN 30 name
d2b329f Add VLAN 30 for cameras
724479d Fix VLAN 30 name
faf5161 Add VLAN 30 for cameras
```
The script then really merges PR #1 into main with `git merge --no-ff` and pushes.

## Step 4: a real merge conflict
Script: `04-conflict`. You change the NTP server to 192.0.2.200 on branch `change-ntp`; the colleague changes the same line on main to 192.0.2.250.
```
git switch change-ntp
git fetch
git merge origin/main        # bring main into the PR branch
```
**Expected:**
```
Auto-merging configs/edge-router.cfg
CONFLICT (content): Merge conflict in configs/edge-router.cfg
Automatic merge failed; fix conflicts and then commit the result.
UU configs/edge-router.cfg
10:<<<<<<< HEAD
11-ntp server 192.0.2.200
12-=======
13-ntp server 192.0.2.250
14->>>>>>> origin/main
```
Resolve: edit the file, keep the line you want, and delete all three marker lines. Then:
```
git add configs/edge-router.cfg
git commit --no-edit
git push
```
**Why it matters:** this is what GitHub means by "This branch has conflicts that must be resolved". Resolving on the branch and pushing updates the pull request. GitHub's web editor handles simple conflicts too, but resolving locally always works.

## Step 5: after the merge
Script: `05-after-merge`.
```
git push origin --delete add-vlan-30 change-ntp   # the Delete branch button
git switch main
git pull
git branch -d add-vlan-30 change-ntp
git fetch --prune                                 # on other clones
```
**Expected:** `- [deleted]  add-vlan-30`, `Deleted branch change-ntp`, and the colleague's `origin/change-ntp` pruned.

## Step 6: verify, then clean up
`06-verify` prints ten `PASS:` lines and `RESULT: PASS`. `99-cleanup` removes the lab folder.
