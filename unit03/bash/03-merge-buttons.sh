#!/usr/bin/env bash
# Mirrors GitHub's three merge buttons locally on throwaway branches, then really merges the PR with a merge commit.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$COLLEAGUE"
git pull -q 2>&1
printf 'Owner: network team (netops@example.com)\n' >> README.md
git commit -q -am "Document repository ownership"
git push -q 2>&1
cd "$LAPTOP"
git fetch -q
step "Button 1, Create a merge commit:  git merge --no-ff"
say 'git switch -c try-merge origin/main'; git switch -c try-merge origin/main 2>&1
say 'git merge --no-ff add-vlan-30 -m "Merge pull request #1 from add-vlan-30"'; git merge --no-ff add-vlan-30 -m "Merge pull request #1 from add-vlan-30"
say 'git log --oneline --graph -5'; git log --oneline --graph -5
step "Button 2, Squash and merge:  git merge --squash, then one commit"
say 'git switch -c try-squash origin/main'; git switch -c try-squash origin/main 2>&1
say 'git merge --squash add-vlan-30'; git merge --squash add-vlan-30 2>&1
say 'git commit -m "Add VLAN 30 for cameras (#1)"'; git commit -m "Add VLAN 30 for cameras (#1)"
say 'git log --oneline --graph -3'; git log --oneline --graph -3
step "Button 3, Rebase and merge:  git rebase, then fast-forward"
say 'git switch -c try-rebase add-vlan-30'; git switch -c try-rebase add-vlan-30 2>&1
say 'git rebase origin/main'; git rebase origin/main 2>&1
say 'git log --oneline --graph -4'; git log --oneline --graph -4
step "Same changes, different history: the rebased commits have new IDs"
say 'git log --oneline -2 add-vlan-30'; git log --oneline -2 add-vlan-30
say 'git log --oneline -2 try-rebase'; git log --oneline -2 try-rebase
step "Really merge PR #1 into main with a merge commit, then push"
git switch -q main
git pull -q 2>&1
git merge -q --no-ff add-vlan-30 -m "Merge pull request #1 from add-vlan-30"
git push 2>&1
git branch -q -D try-merge try-squash try-rebase
git log --oneline --graph -5
