# OPTIONAL: a real merge request in your own throwaway GitLab project

> **Optional and manual.** No script in this ZIP contacts GitLab. Use only a private project you create for practice and can delete afterwards. Never use a work project.

## Before you start
- A GitLab account and a **blank, private** project (for example `git-course-sandbox`), cloned with one commit on main.
- Sign in with HTTPS (personal access token) or SSH (your public key added to GitLab). Never commit a token or private key.

## 1. Open a merge request
```
git switch -c add-vlan-30
# edit configs/edge-router.cfg, then
git commit -am "Add VLAN 30 for cameras"
git push -u origin add-vlan-30
```
Git prints a link to create a merge request, or use **Create merge request** in the project. Check: **source branch** = `add-vlan-30`, **target branch** = `main`. To make it a draft, start the title with `Draft:` or tick **Mark as draft**. Optionally tick **Delete source branch when merge request is accepted** and **Squash commits when merge request is accepted**.

## 2. Review
Comment on lines in the **Changes** tab, then **Approve**. On GitLab Free, approvals are optional and do not block merging. Required approval rules need GitLab Premium or Ultimate.

## 3. Pipelines on the merge request
If the project has a `.gitlab-ci.yml`, the pipeline result appears in the merge request. Unit 4 covers checks and pipelines with GitHub Actions; Unit 5 compares GitLab CI.

## 4. Conflict, merge, clean up
A conflict is resolved exactly as on GitHub: `git fetch`, `git merge origin/main`, fix, `git add`, `git commit --no-edit`, `git push`. Then click **Merge**. Locally:
```
git switch main
git pull
git branch -d add-vlan-30
git fetch --prune
```
When finished, delete the practice project under **Settings → General → Advanced** if you no longer need it.
