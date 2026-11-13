# OPTIONAL: the workflow and a required check on your own throwaway GitHub repository

> **Optional and manual.** No script in this ZIP contacts GitHub. Use only a repository you create for practice and can delete afterwards. Never use a work repository.

## Before you start
- A GitHub account and a practice repository (for example `git-course-sandbox`), cloned locally (see Unit 2's `OPTIONAL-GITHUB.md`).
- Branch protection is available on **public** repositories with GitHub Free, and on public and private repositories with GitHub Pro, Team and Enterprise. A **public** throwaway repository works on a free account; it contains only the sample configs.
- Never put tokens, passwords or real device configs in the repository.

## 1. Add the files
Copy everything from `files/repo/` (including the hidden `.github` folder) into your clone, then:
```
git add -A
git commit -m "Add configs, check script and workflow"
git push
```
Open the **Actions** tab: the `config-check` workflow runs for the push to main.

## 2. Require the check
**Settings → Branches → Add branch protection rule** (or **Settings → Rules → Rulesets**) for `main`:
- tick **Require a pull request before merging**;
- tick **Require status checks to pass before merging**, then search for and add `validate` (the job name; the check has run once already, so it appears in the list).

## 3. Open a pull request with a mistake
```
git switch -c add-vlan-40
# append to configs/edge-router.cfg:  vlan 10 / name GUEST / !
git commit -am "Add guest VLAN"
git push -u origin add-vlan-40
```
Open the pull request. **Expected:** the `config-check / validate` check fails and merging is blocked. Click **Details** to read the log line `duplicate VLAN 10`.

## 4. Fix, push, merge
Change the new VLAN to 40, commit, push to the same branch. The check runs again and turns green. Merge, delete the branch, then watch the run on main in the **Actions** tab.

When finished, delete the practice repository under **Settings → Danger Zone** if you no longer need it.
