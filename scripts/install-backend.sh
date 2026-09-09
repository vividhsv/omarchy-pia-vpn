#!/usr/bin/env bash
# Guided install of the official PIA Linux client. Runs in a visible
# terminal so the user can read every command and enter sudo if asked.
set -euo pipefail

echo "This installs the official Private Internet Access client (AUR: piavpn-bin),"
echo "enables the daemon, and turns on piactl background mode."
echo
echo "This Omarchy plugin does not ship PIA binaries and is not affiliated with PIA."
echo

if ! command -v omarchy >/dev/null 2>&1; then
  echo "omarchy is not on PATH. Install Omarchy first." >&2
  exit 1
fi

echo "==> Installing piavpn-bin from the AUR"
omarchy pkg aur add piavpn-bin

echo
echo "==> Enabling piavpn.service"
sudo systemctl enable --now piavpn.service

PIACTL="$(command -v piactl || true)"
if [[ -z $PIACTL && -x /opt/piavpn/bin/piactl ]]; then
  PIACTL=/opt/piavpn/bin/piactl
fi
if [[ -z $PIACTL && -x /usr/local/bin/piactl ]]; then
  PIACTL=/usr/local/bin/piactl
fi
if [[ -z $PIACTL ]]; then
  echo "piactl was not found after install. Open the plugin again after a moment." >&2
  exit 1
fi

echo
echo "==> Enabling background mode (VPN can run without the official GUI)"
"$PIACTL" background enable

echo
echo "Backend is ready. Close this terminal and sign in from the PIA panel."
