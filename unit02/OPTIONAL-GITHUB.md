# OPTIONAL: the same flow with your own throwaway GitHub repository

> **Optional and manual.** No script in this ZIP contacts GitHub. Do this only with a repository you create yourself for practice, and that you can delete afterwards. Never use a work repository.

## Before you start
- You need a GitHub account.
- Create an **empty, private** repository, for example `git-course-sandbox`. Do not add a README.
- Choose how to sign in:
  - **HTTPS:** GitHub asks for a **personal access token**, not your password. A credential manager (Git Credential Manager on Windows and macOS) can store it.
  - **SSH:** create a key pair (`ssh-keygen -t ed25519`), add the **public** key to your GitHub account, and use the `git@github.com:` URL.
- Never put a token or private key in a repository.

## Steps (Bash or PowerShell 7)
```
git clone <your-repo-URL> sandbox          # https://github.com/YOU/git-course-sandbox.git or git@github.com:YOU/git-course-sandbox.git
cd sandbox
git config --local user.name  "Your Name"
git config --local user.email "you@example.com"
git config --local pull.rebase false
# add a file, then:
git add .
git commit -m "First commit"
git push -u origin main
git switch -c add-vlan-30
# edit, commit, then:
git push -u origin add-vlan-30
```
**Expected:** the branch appears on GitHub, and GitHub offers **Compare & pull request**. Unit 3 starts here.

To see a rejected push, edit a file directly on github.com (that commits to main). Then commit a different change locally and run `git push`. Fix it with `git pull`, then `git push`.

## Clean up
Delete the local `sandbox` folder. If you no longer need the repository, delete it on GitHub under **Settings → Danger Zone**.
