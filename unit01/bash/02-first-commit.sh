#!/usr/bin/env bash
# Adds the first files, shows the three states and records the first commit.
source "$(dirname "$0")/lab-env.sh"; need_lab
mkdir -p configs
cp "$FILES/edge-router.cfg" configs/edge-router.cfg
printf '# network-configs\nVersion-controlled device configurations for the lab.\n' > README.md
step "git status (untracked files)"
git status --short
step "git add (stage the files)"
git add README.md configs/edge-router.cfg
git status --short
step "git commit"
git commit -m "Add edge router baseline config"
step "git log --oneline"
git log --oneline --decorate
