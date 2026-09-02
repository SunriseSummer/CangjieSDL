"""Contract tests for the stable development-tool command surface."""

import contextlib
import io
import os
import unittest
from pathlib import Path

import cli


class DevelopmentCliTests(unittest.TestCase):
    def test_help_lists_each_command(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(cli.main(["--help"]), 0)
        for command in ("check docs", "check snippets", "test examples", "test tools"):
            self.assertIn(command, output.getvalue())

    def test_unknown_command_fails_closed(self):
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                cli.main(["unknown"])
        self.assertEqual(raised.exception.code, 2)

    def test_python_cache_is_outside_dev_sources(self):
        cache = Path(os.environ["PYTHONPYCACHEPREFIX"])
        self.assertEqual(cache, (cli.REPOSITORY_ROOT / "target" / "dev" / "pycache").resolve())


if __name__ == "__main__":
    unittest.main()
