"""Tests for public example discovery."""

import tempfile
import unittest
import contextlib
import io
from pathlib import Path
from unittest.mock import patch

from sdl_dev.e2e.examples import discover_examples
from sdl_dev.e2e import examples


class ExampleDiscoveryTests(unittest.TestCase):
    def test_discovery_ignores_hidden_directories_and_sorts_results(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            for name in ("zeta", ".fixture", "alpha"):
                directory = root / name
                directory.mkdir()
                (directory / "cjpm.toml").write_text("[package]\n", encoding="utf-8")
            self.assertEqual([item.name for item in discover_examples(root)], ["alpha", "zeta"])

    def test_all_builds_before_running_bounded_native_tests(self):
        example = examples.REPOSITORY_ROOT / "examples" / "calculator"
        with patch.object(examples, "discover_examples", return_value=[example]), \
                patch.object(examples, "run_command", return_value=(0, "", "", False)) as run, \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(examples.main(["--action", "all", "--timeout", "30"]), 0)
            self.assertEqual([call.args[0] for call in run.call_args_list], [
                ["cjpm", "build"], ["cjpm", "test", "--no-progress", "--timeout-each", "60s"]])
            self.assertTrue(all(call.args[2] == 30 for call in run.call_args_list))

    def test_failed_build_does_not_run_a_stale_test_binary(self):
        example = examples.REPOSITORY_ROOT / "examples" / "calculator"
        with patch.object(examples, "discover_examples", return_value=[example]), \
                patch.object(examples, "run_command", return_value=(1, "failed", "", False)) as run, \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(examples.main(["--action", "all"]), 1)
            self.assertEqual(run.call_count, 1)


if __name__ == "__main__":
    unittest.main()
