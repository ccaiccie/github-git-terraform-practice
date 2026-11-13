#!/usr/bin/env bash
# Checks router configs: VLAN IDs 1-4094, no duplicate VLAN IDs, every VLAN named, at least one NTP server.
# Exit code 0 = all files pass (a green check). Exit code 1 = at least one problem (a red check).
set -uo pipefail
dir="${1:-configs}"; fail=0; n=0
shopt -s nullglob
for f in "$dir"/*.cfg; do
  n=$((n + 1))
  out="$(awk -v F="$f" '
    /^vlan [0-9]+$/ { id = $2 + 0
      if (id < 1 || id > 4094) print "FAIL " F ":" NR ": VLAN " id " is outside 1-4094"
      if (id in seen) print "FAIL " F ":" NR ": duplicate VLAN " id " (first defined on line " seen[id] ")"; else seen[id] = NR
      cur = id; curline = NR; named = 0; next }
    cur != "" && /^ name [^ ]/ { named = 1; next }
    /^!$/ { if (cur != "" && !named) print "FAIL " F ":" curline ": VLAN " cur " has no name"; cur = ""; next }
    /^ntp server / { ntp = 1 }
    END { if (cur != "" && !named) print "FAIL " F ":" curline ": VLAN " cur " has no name"
          if (!ntp) print "FAIL " F ": no ntp server line" }' "$f")"
  if [[ -n "$out" ]]; then echo "$out"; fail=1; else echo "PASS $f"; fi
done
if (( n == 0 )); then echo "FAIL: no .cfg files in $dir"; exit 1; fi
if (( fail )); then echo "RESULT: FAIL ($n file(s) checked)"; exit 1; fi
echo "RESULT: PASS ($n file(s) checked)"
