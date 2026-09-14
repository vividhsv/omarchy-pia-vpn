#!/usr/bin/bash
# Guided install of the official PIA Linux client. Runs in a visible
# terminal so the user can read every command and enter sudo if asked.
set -euo pipefail

PATH=/usr/bin:/bin
LANG=C.UTF-8
LC_ALL=C.UTF-8
export PATH LANG LC_ALL

OMARCHY=/usr/bin/omarchy
SUDO=/usr/bin/sudo
SYSTEMCTL=/usr/bin/systemctl
TIMEOUT=/usr/bin/timeout
PIACTL_CANDIDATES=(/opt/piavpn/bin/piactl /usr/local/bin/piactl /usr/bin/piactl)

echo "This installs the official Private Internet Access client (AUR: piavpn-bin),"
echo "enables the daemon, and turns on piactl background mode."
echo
echo "This Omarchy plugin does not ship PIA binaries and is not affiliated with PIA."
echo

if [[ ! -x $OMARCHY ]]; then
  echo "omarchy was not found at $OMARCHY" >&2
  exit 1
fi
if [[ ! -x $TIMEOUT || ! -x $SUDO || ! -x $SYSTEMCTL ]]; then
  echo "required system binaries were not found under /usr/bin" >&2
  exit 1
fi

echo "==> Installing piavpn-bin from the AUR"
"$TIMEOUT" --foreground --signal=TERM --kill-after=15 900 "$OMARCHY" pkg aur add piavpn-bin

echo
echo "==> Enabling piavpn.service"
"$TIMEOUT" --foreground --signal=TERM --kill-after=5 60 "$SUDO" "$SYSTEMCTL" enable --now piavpn.service

PIACTL=""
for candidate in "${PIACTL_CANDIDATES[@]}"; do
  if [[ -x $candidate ]]; then
    PIACTL=$candidate
    break
  fi
done
if [[ -z $PIACTL ]]; then
  echo "piactl was not found after install. Open the plugin again after a moment." >&2
  exit 1
fi

echo
echo "==> Enabling background mode (VPN can run without the official GUI)"
"$TIMEOUT" --foreground --signal=TERM --kill-after=5 30 "$PIACTL" background enable

echo
echo "Backend is ready. Close this terminal and sign in from the PIA panel."
