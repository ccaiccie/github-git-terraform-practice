#!/usr/bin/env bash
# The scheduled drift check: exit code 0 (no drift). Then someone renames VLAN 20 by hand: exit code 2, an issue is opened.
source "$(dirname "$0")/lab-env.sh"; need_lab
step "Scheduled drift check (06:17)"
wf_drift
step "During an incident, someone renames VLAN 20 on the switch by hand"
printf '10 USERS\n20 VOICE-TEMP\n30 CAMERAS\n' | sw_write; grep -A1 '^vlan 20$' "$SWITCH"
step "Next scheduled drift check"
wf_drift
