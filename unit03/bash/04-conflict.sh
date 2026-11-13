#!/usr/bin/env bash
# Two people change the same line. The PR now has a conflict. Resolve it locally on the branch, push, then merge.
source "$(dirname "$0")/lab-env.sh"; need_lab
cd "$LAPTOP"
git switch -q -c change-ntp main
replace_line configs/edge-router.cfg "ntp server 192.0.2.123" "ntp server 192.0.2.200"
git commit -q -am "Move NTP to 192.0.2.200"
git push -q -u origin change-ntp 2>&1
cd "$COLLEAGUE"
git pull -q 2>&1
replace_line configs/edge-router.cfg "ntp server 192.0.2.123" "ntp server 192.0.2.250"
git commit -q -am "Move NTP to 192.0.2.250"
git push -q 2>&1
cd "$LAPTOP"
git fetch -q
step "git merge origin/main  (on the PR branch; expected conflict)"
if git merge origin/main 2>&1; then echo "UNEXPECTED: no conflict" >&2; exit 1; fi
step "git status --short"
git status --short
step "The conflicted lines in configs/edge-router.cfg"
grep -n -A4 '^<<<<<<<' configs/edge-router.cfg
step "Resolve: keep 192.0.2.200, remove the markers, add, commit"
awk '/^<<<<<<< /{skip=0; inours=1; next} /^=======/{inours=0; skip=1; next} /^>>>>>>> /{skip=0; next} { if (!skip) print }' configs/edge-router.cfg > cfg.tmp && mv cfg.tmp configs/edge-router.cfg
grep -n '^ntp server' configs/edge-router.cfg
git add configs/edge-router.cfg
git commit -q --no-edit
git push 2>&1
step "Merge PR #2 into main"
git switch -q main
git pull -q 2>&1
git merge -q --no-ff change-ntp -m "Merge pull request #2 from change-ntp"
git push 2>&1
git log --oneline --graph -6
