"""Tests for public example discovery."""

import tempfile
import unittest
from pathlib import Path

from sdl_dev.e2e.examples import discover_examples


class ExampleDiscoveryTests(unittest.TestCase):
    def test_discovery_ignores_hidden_directories_and_sorts_results(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            for name in ("zeta", ".fixture", "alpha"):
                directory = root / name
                directory.mkdir()
                (directory / "cjpm.toml").write_text("[package]\n", encoding="utf-8")
            self.assertEqual([item.name for item in discover_examples(root)], ["alpha", "zeta"])


if __name__ == "__main__":
    unittest.main()
