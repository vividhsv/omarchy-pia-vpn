#!/usr/bin/python3
"""Read piactl status as key=value lines for the Omarchy plugin."""

import json
import os
import sys

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from pia_exec import DUMP_MAX_BYTES, find_piactl, run  # noqa: E402


def kv(key, value):
    text = "" if value is None else str(value)
    text = text.replace("\r", " ").replace("\n", " ").strip()
    print(f"{key}={text}")


def get(piactl, kind):
    code, stdout, _stderr = run([piactl, "get", kind], timeout=8, max_bytes=65536)
    return stdout if code == 0 else ""


def dump_json(piactl, kind):
    code, stdout, _stderr = run(
        [piactl, "-u", "dump", kind], timeout=10, max_bytes=DUMP_MAX_BYTES
    )
    if code != 0 or not stdout:
        return None
    try:
        return json.loads(stdout)
    except json.JSONDecodeError:
        return None


def main():
    piactl = find_piactl()
    if not piactl:
        kv("installed", "false")
        return 0

    kv("installed", "true")
    kv("piactl", piactl)

    for kind in (
        "connectionstate",
        "region",
        "vpnip",
        "pubip",
        "protocol",
        "requestportforward",
        "allowlan",
        "portforward",
    ):
        kv(kind, get(piactl, kind))

    account = dump_json(piactl, "daemon-account") or {}
    logged_in = bool(account.get("loggedIn") or account.get("logged_in"))
    username = account.get("username") or account.get("email") or ""
    kv("loggedin", "true" if logged_in else "false")
    kv("username", username)

    settings = dump_json(piactl, "daemon-settings") or {}
    killswitch = settings.get("killswitch")
    if killswitch is None:
        killswitch = settings.get("killSwitch")
    kv("killswitch", "" if killswitch is None else killswitch)

    persist = settings.get("persistDaemon")
    if persist is True:
        kv("background", "true")
    elif persist is False:
        kv("background", "false")
    else:
        kv("background", "")
    return 0


if __name__ == "__main__":
    sys.exit(main())
