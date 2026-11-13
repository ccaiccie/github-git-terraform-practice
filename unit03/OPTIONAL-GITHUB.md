# OPTIONAL: a real pull request in your own throwaway GitHub repository

> **Optional and manual.** No script in this ZIP contacts GitHub. Use only a private repository you create for practice and can delete afterwards. Never use a work repository.

## Before you start
- A GitHub account and an **empty, private** practice repository (for example `git-course-sandbox`), cloned and with one commit on main (see Unit 2's `OPTIONAL-GITHUB.md`).
- Sign in with HTTPS (personal access token, never your password) or SSH (your public key added to GitHub). Never commit a token or private key.

## 1. Open a pull request
```
git switch -c add-vlan-30
# edit configs/edge-router.cfg, then
git commit -am "Add VLAN 30 for cameras"
git push -u origin add-vlan-30
```
On github.com click **Compare & pull request**. Check: **base** = `main`, **compare** = `add-vlan-30`. Add a title, then **Create pull request** (or the arrow, **Create draft pull request**).
With the GitHub CLI (optional, after `gh auth login`): `gh pr create --base main --fill` (add `--draft` for a draft).

## 2. Review
Open **Files changed**, comment on a line, then **Review changes** and pick **Comment**, **Approve** or **Request changes**. (GitHub does not let you approve your own pull request; a second account or a colleague can.)

## 3. Make a conflict and resolve it
1. On github.com, edit `configs/edge-router.cfg` on **main** and change the `ntp server` line. Commit to main.
2. Locally, on `add-vlan-30`, change the **same** line differently, commit and push.
3. The pull request shows **This branch has conflicts that must be resolved**. Simple conflicts can use **Resolve conflicts** in the browser. Locally:
```
git fetch
git merge origin/main      # fix the file, remove the markers
git add configs/edge-router.cfg
git commit --no-edit
git push
```

## 4. Merge and clean up
Pick **Create a merge commit**, **Squash and merge** or **Rebase and merge** (repository settings decide which appear). Click **Delete branch**. Then locally:
```
git switch main
git pull
git branch -d add-vlan-30
git fetch --prune
```
When finished, delete the practice repository under **Settings → Danger Zone** if you no longer need it.
