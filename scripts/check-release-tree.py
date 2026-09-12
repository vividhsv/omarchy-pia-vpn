#!/usr/bin/env python3
"""Fail if agent-control files would ship in the plugin checkout.

Walks the git-tracked tree recursively and also scans the working tree for
unignored banned paths, so AGENTS.md and equivalents cannot return unnoticed.
"""

from __future__ import annotations

import os
import subprocess
import sys

BANNED_NAMES = {
    "agents.md",
    "claude.md",
    "gemini.md",
    "copilot.md",
    "agent.md",
    ".cursorrules",
    ".windsurfrules",
    ".clinerules",
    "copilot-instructions.md",
}

BANNED_PREFIXES = (
    ".cursor/rules/",
    ".cursor/commands/",
    ".claude/",
    ".codex/",
    ".agent/",
    ".github/agents/",
    ".github/instructions/",
)


def is_banned(path: str) -> bool:
    normalized = path.replace("\\", "/").lower().lstrip("./")
    name = normalized.rsplit("/", 1)[-1]
    if name in BANNED_NAMES:
        return True
    return any(
        normalized == prefix.rstrip("/") or normalized.startswith(prefix)
        for prefix in BANNED_PREFIXES
    )


def git(root: str, *args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        ["git", "-C", root, *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=check,
    )


def tracked_files(root: str) -> list[str]:
    listed = git(root, "ls-files", "-z").stdout
    return [path.decode() for path in listed.split(b"\0") if path]


def is_ignored(root: str, path: str) -> bool:
    result = git(root, "check-ignore", "-q", "--", path, check=False)
    return result.returncode == 0


def working_tree_files(root: str) -> list[str]:
    found: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name != ".git"]
        for name in filenames:
            full = os.path.join(dirpath, name)
            relative = os.path.relpath(full, root).replace("\\", "/")
            found.append(relative)
    return found


def main() -> int:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    try:
        tracked = tracked_files(root)
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.output.decode())
        return 2

    hits = sorted({path for path in tracked if is_banned(path)})
    for path in working_tree_files(root):
        if not is_banned(path) or is_ignored(root, path):
            continue
        if path not in hits:
            hits.append(path)

    if hits:
        print(
            "agent-control files must not ship in the plugin tree:",
            file=sys.stderr,
        )
        for path in hits:
            print(f"  {path}", file=sys.stderr)
        return 1

    print(f"ok: {len(tracked)} tracked files, no agent-control paths")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
