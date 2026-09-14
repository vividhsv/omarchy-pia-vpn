#!/usr/bin/python3
"""Read username and password from stdin, then piactl login via a 0600 tempfile."""

from __future__ import annotations

import os
import sys
import tempfile

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from pia_exec import find_piactl, run  # noqa: E402

SHRED = "/usr/bin/shred"


def _wipe(path: str) -> None:
    if not path or not os.path.isfile(path):
        return
    if os.path.isfile(SHRED) and os.access(SHRED, os.X_OK):
        run([SHRED, "-u", path], timeout=5, max_bytes=4096)
        if not os.path.isfile(path):
            return
    try:
        size = os.path.getsize(path)
        with open(path, "wb") as handle:
            handle.write(b"\0" * size)
            handle.flush()
            os.fsync(handle.fileno())
    except OSError:
        pass
    try:
        os.remove(path)
    except OSError:
        pass


def main() -> int:
    piactl = find_piactl(sys.argv[1] if len(sys.argv) > 1 else None)
    if not piactl:
        print("piactl binary not found", file=sys.stderr)
        return 1

    user = sys.stdin.readline()
    password = sys.stdin.readline()
    if user.endswith("\n"):
        user = user[:-1]
    if password.endswith("\n"):
        password = password[:-1]
    if not user or not password:
        print("username and password are required", file=sys.stderr)
        return 1

    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime or not os.path.isdir(runtime):
        runtime = "/tmp"
    fd = None
    path = ""
    try:
        fd, path = tempfile.mkstemp(prefix="pia-omarchy-login.", dir=runtime)
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            fd = None
            handle.write(f"{user}\n{password}\n")
            handle.flush()
            os.fsync(handle.fileno())
        code, stdout, stderr = run([piactl, "login", path], timeout=20, max_bytes=8192)
        if stdout:
            print(stdout)
        if stderr:
            print(stderr, file=sys.stderr)
        return code
    finally:
        if fd is not None:
            try:
                os.close(fd)
            except OSError:
                pass
        _wipe(path)


if __name__ == "__main__":
    raise SystemExit(main())
