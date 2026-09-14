#!/usr/bin/python3
"""Run plugin helpers with fixed binaries, a closed env, and process-group limits."""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import threading

PIACTL_CANDIDATES = (
    "/opt/piavpn/bin/piactl",
    "/usr/local/bin/piactl",
    "/usr/bin/piactl",
)
SYSTEM_PATH = "/usr/bin:/bin"
KEEP_ENV = (
    "HOME",
    "USER",
    "LOGNAME",
    "XDG_RUNTIME_DIR",
    "XDG_CONFIG_HOME",
    "XDG_STATE_HOME",
    "XDG_DATA_HOME",
    "XDG_CACHE_HOME",
)
TERM_GRACE_SEC = 2
DEFAULT_TIMEOUT_SEC = 20
DEFAULT_MAX_BYTES = 65536
DUMP_MAX_BYTES = 2 * 1024 * 1024

_active_pgid = None


def closed_env() -> dict[str, str]:
    env = {key: os.environ[key] for key in KEEP_ENV if key in os.environ}
    env["PATH"] = SYSTEM_PATH
    env["LANG"] = "C.UTF-8"
    env["LC_ALL"] = "C.UTF-8"
    return env


def _usable(path: str) -> bool:
    return bool(path) and os.path.isfile(path) and os.access(path, os.X_OK)


def _approved(path: str) -> bool:
    if not path or os.path.basename(path) != "piactl":
        return False
    real = os.path.realpath(path)
    approved = {os.path.realpath(candidate) for candidate in PIACTL_CANDIDATES}
    return real in approved


def find_piactl(explicit: str | None = None) -> str | None:
    if explicit:
        return explicit if _usable(explicit) and _approved(explicit) else None
    for candidate in PIACTL_CANDIDATES:
        if _usable(candidate):
            return candidate
    return None


def _kill_group(pgid: int, sig: int) -> None:
    try:
        os.killpg(pgid, sig)
    except ProcessLookupError:
        return


def _reap(proc: subprocess.Popen[bytes], seconds: float) -> None:
    try:
        proc.wait(timeout=seconds)
    except subprocess.TimeoutExpired:
        pass


def terminate_group(proc: subprocess.Popen[bytes]) -> None:
    if proc.poll() is not None:
        return
    pgid = proc.pid
    _kill_group(pgid, signal.SIGTERM)
    _reap(proc, TERM_GRACE_SEC)
    if proc.poll() is None:
        _kill_group(pgid, signal.SIGKILL)
        _reap(proc, TERM_GRACE_SEC)


def _read_capped(stream, limit: int, chunks: list[bytes], exceeded: list[bool]) -> None:
    total = 0
    while True:
        buf = stream.read(4096)
        if not buf:
            return
        if total >= limit:
            exceeded[0] = True
            return
        room = limit - total
        if len(buf) > room:
            chunks.append(buf[:room])
            exceeded[0] = True
            return
        chunks.append(buf)
        total += len(buf)


def run(argv: list[str], timeout: float = DEFAULT_TIMEOUT_SEC, max_bytes: int = DEFAULT_MAX_BYTES):
    if not argv or not _usable(argv[0]):
        return 1, "", "executable is not an approved path"

    global _active_pgid
    stdout_chunks: list[bytes] = []
    stderr_chunks: list[bytes] = []
    stdout_hit = [False]
    stderr_hit = [False]
    proc = subprocess.Popen(
        argv,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=closed_env(),
        start_new_session=True,
    )
    _active_pgid = proc.pid
    threads = [
        threading.Thread(
            target=_read_capped,
            args=(proc.stdout, max_bytes, stdout_chunks, stdout_hit),
            daemon=True,
        ),
        threading.Thread(
            target=_read_capped,
            args=(proc.stderr, max_bytes, stderr_chunks, stderr_hit),
            daemon=True,
        ),
    ]
    for thread in threads:
        thread.start()

    timed_out = False
    try:
        proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        terminate_group(proc)

    for thread in threads:
        thread.join(timeout=1)
    if stdout_hit[0] or stderr_hit[0]:
        terminate_group(proc)

    if proc.stdout:
        proc.stdout.close()
    if proc.stderr:
        proc.stderr.close()
    _active_pgid = None
    stdout = b"".join(stdout_chunks).decode("utf-8", "replace").strip()
    stderr = b"".join(stderr_chunks).decode("utf-8", "replace").strip()
    if timed_out:
        return 1, stdout, stderr or "timeout"
    if stdout_hit[0] or stderr_hit[0]:
        return 1, stdout, stderr or "output limit exceeded"
    return proc.returncode if proc.returncode is not None else 1, stdout, stderr


def _handle_signal(signum, _frame) -> None:
    if _active_pgid is not None:
        _kill_group(_active_pgid, signal.SIGTERM)
        _kill_group(_active_pgid, signal.SIGKILL)
    raise SystemExit(128 + signum)


def _parse_cli(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run an approved command with limits.")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT_SEC)
    parser.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    command = list(args.command)
    if command and command[0] == "--":
        command = command[1:]
    args.command = command
    return args


def main(argv: list[str] | None = None) -> int:
    signal.signal(signal.SIGTERM, _handle_signal)
    signal.signal(signal.SIGINT, _handle_signal)
    args = _parse_cli(sys.argv[1:] if argv is None else argv)
    if not args.command:
        print("command is required", file=sys.stderr)
        return 2
    code, stdout, stderr = run(args.command, timeout=args.timeout, max_bytes=args.max_bytes)
    if stdout:
        sys.stdout.write(stdout)
        sys.stdout.write("\n")
    if stderr:
        sys.stderr.write(stderr)
        sys.stderr.write("\n")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
