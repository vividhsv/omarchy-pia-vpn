#!/usr/bin/python3
"""Tests for closed-env helpers (no live piactl required)."""

import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import pia_exec  # noqa: E402


class FindPiactlTests(unittest.TestCase):
    def test_rejects_bare_name(self):
        self.assertIsNone(pia_exec.find_piactl("piactl"))

    def test_rejects_relative_path(self):
        self.assertIsNone(pia_exec.find_piactl("./piactl"))

    def test_rejects_unapproved_absolute(self):
        self.assertIsNone(pia_exec.find_piactl("/tmp/piactl"))


class RunTests(unittest.TestCase):
    def test_caps_stdout(self):
        code, stdout, stderr = pia_exec.run(
            ["/usr/bin/python3", "-c", "print('x' * 10000)"],
            timeout=5,
            max_bytes=100,
        )
        self.assertEqual(code, 1)
        self.assertLessEqual(len(stdout.encode()), 100)
        self.assertIn("limit", stderr)

    def test_timeout_kills(self):
        code, _stdout, stderr = pia_exec.run(
            ["/usr/bin/sleep", "8"],
            timeout=0.3,
            max_bytes=64,
        )
        self.assertEqual(code, 1)
        self.assertEqual(stderr, "timeout")

    def test_closed_path_is_system_only(self):
        env = pia_exec.closed_env()
        self.assertEqual(env["PATH"], "/usr/bin:/bin")
        self.assertNotIn("PYTHONPATH", env)


if __name__ == "__main__":
    unittest.main()
