#!/usr/bin/env bash
# Read username and password from stdin (two lines), write a 0600 temp file,
# call piactl login, then shred the file. Never put the password on argv.
set -euo pipefail

PIACTL="${1:-}"
if [[ -z $PIACTL || ! -x $PIACTL ]]; then
  echo "piactl binary not found" >&2
  exit 1
fi

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
FILE="$(mktemp "$RUNTIME/pia-omarchy-login.XXXXXX")"

cleanup() {
  if [[ -f $FILE ]]; then
    if command -v shred >/dev/null 2>&1; then
      shred -u "$FILE" >/dev/null 2>&1 || rm -f "$FILE"
    else
      rm -f "$FILE"
    fi
  fi
}
trap cleanup EXIT

chmod 600 "$FILE"
IFS= read -r user || true
IFS= read -r pass || true
if [[ -z $user || -z $pass ]]; then
  echo "username and password are required" >&2
  exit 1
fi
printf '%s\n%s\n' "$user" "$pass" >"$FILE"
"$PIACTL" login "$FILE"
