#!/usr/bin/env python3
"""Fail if agent-control files would ship in the plugin checkout."""

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
    ".claude/",
    ".codex/",
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


def tracked_files(root: str) -> list[str]:
    listed = subprocess.check_output(
        ["git", "-C", root, "ls-files", "-z"],
        stderr=subprocess.STDOUT,
    )
    return [path.decode() for path in listed.split(b"\0") if path]


def main() -> int:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    try:
        files = tracked_files(root)
    except subprocess.CalledProcessError as exc:
        print(exc.output.decode(), file=sys.stderr)
        return 2

    hits = [path for path in files if is_banned(path)]
    if hits:
        print(
            "agent-control files must not ship in the plugin tree:",
            file=sys.stderr,
        )
        for path in hits:
            print(f"  {path}", file=sys.stderr)
        return 1

    print(f"ok: {len(files)} tracked files, no agent-control paths")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
