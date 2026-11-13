#!/usr/bin/env bash
# Deletes only the Unit 4 lab folder, and only if it carries the lab marker file.
source "$(dirname "$0")/lab-env.sh"
if [[ ! -e "$LAB" ]]; then echo "Nothing to clean: $LAB does not exist."; exit 0; fi
if [[ ! -f "$MARKER" ]] || [[ "$(cat "$MARKER")" != "$MARKER_TEXT" ]]; then
  echo "ERROR: $LAB exists but has no Unit 4 marker; refusing to delete it." >&2; exit 1; fi
rm -rf -- "$LAB"
rmdir -- "$LAB_ROOT" 2>/dev/null || true
echo "Removed $LAB"
