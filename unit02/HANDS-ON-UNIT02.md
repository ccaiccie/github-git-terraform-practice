# Hands-on guide: Unit 2, push, fetch and pull

Every command below works in **Bash and PowerShell 7**. Git commands are identical in both shells. The scripts in `bash/` and `pwsh/` also do the small file edits for you.

The lab has three repositories:
- `server/network-configs.git` is a bare repository, the stand-in for GitHub or GitLab;
- `laptop/network-configs` is you;
- `colleague/network-configs` is a teammate.

Commit IDs and paths in the expected output are examples. Yours will differ.

## Step 0: check prerequisites
Script: `00-check-prereqs`. **Expected:** `PASS: Git 2.NN is new enough`.

## Step 1: create the stand-in server, add origin, first push
Script: `01-create-remote-and-push`.
```
git init --bare -b main <lab>/server/network-configs.git
git remote add origin <lab>/server/network-configs.git
git remote -v
git push -u origin main
git branch -vv
```
**Expected:**
```
To ~/git-course-lab/unit02/server/network-configs.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
* main e662814 [origin/main] Add edge router baseline config
```
**Why it matters:** `-u` sets the upstream, so a plain `git push`, `git pull` and `git status` know which remote branch belongs to your main.

## Step 2: clone as a colleague
Script: `02-clone`. Run `git clone <lab>/server/network-configs.git <lab>/colleague/network-configs`.
**Expected:** `origin` already exists, and `main` already tracks `origin/main`.
**Why it matters:** a clone is connected and ready immediately.

## Step 3: fetch, look, then pull
Script: `03-fetch-and-pull`. The colleague pushes "Add VLAN 20 for voice". Then, on your laptop:
```
git fetch
git status
git log --oneline --graph --decorate --all
git pull
```
**Expected:** after the fetch,
```
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```
Then the pull prints `Fast-forward`, and status says `up to date with 'origin/main'`.
**Why it matters:** fetch moves only `origin/main`, never your branch or files. Pull is fetch plus merge.

## Step 4: the rejected push, and the fix
Script: `04-rejected-push`. You commit an ownership note, and `git status` shows `ahead of 'origin/main' by 1 commit`. The colleague pushes a second NTP server first. Your `git push` is then rejected:
```
To ~/git-course-lab/unit02/server/network-configs.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '~/git-course-lab/unit02/server/network-configs.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```
Fix it with:
```
git pull --no-edit
git push
```
**Expected:** `Merge made by the 'ort' strategy.`, then an accepted push.
**Why it matters:** a rejection is safe, because nothing was overwritten. Never use `git push --force` on a shared branch.
The lab sets `pull.rebase false` (merge). Recent Git versions refuse a pull from diverged branches until you choose merge or rebase.

## Step 5: push a new branch
Script: `05-push-a-branch`.
```
git switch -c add-vlan-30
git commit -am "Add VLAN 30 for cameras"
git push -u origin add-vlan-30
git branch -r
```
**Expected:** `* [new branch] add-vlan-30 -> add-vlan-30`, and `origin/add-vlan-30` appears in `git branch -r`.
**Why it matters:** Unit 3 opens a pull request from a pushed branch like this one.

## Step 6: verify
Script: `06-verify`. **Expected:** thirteen `PASS:` lines, then `RESULT: PASS`. It checks that:
- both clones match the server;
- upstreams are set;
- the server has 5 commits on main, exactly 1 of them a merge commit;
- the new branch is on the server;
- every origin URL is a local path.

## Cleanup
Run `99-cleanup` (Bash or PowerShell). It deletes only `~/git-course-lab/unit02`, and only if the marker file is present.

## Troubleshooting
| Symptom | Cause and fix |
|---|---|
| `ERROR: … already exists; refusing to overwrite` | An old lab is present. Run `99-cleanup` first. |
| `fatal: Need to specify how to reconcile divergent branches` | `pull.rebase` is not set. The lab sets it. Outside the lab, run `git config pull.rebase false` (merge) once. |
| `! [rejected] … (fetch first)` outside Step 4 | Someone pushed first. Run `git pull`, then `git push`. |
| `unknown switch 'b'` | Git is older than 2.28. Upgrade Git. |
