"""Contract tests for API coverage, links, and snippet discovery."""

import tempfile
import unittest
from pathlib import Path

from sdl_dev.checks.api_surface import api_surface_failures
from sdl_dev.checks.doc_snippets import verified_snippets
from sdl_dev.checks.docs import broken_links, markdown_files
from sdl_dev.common.paths import REPOSITORY_ROOT


class ApiDocumentationTests(unittest.TestCase):
    def test_example_readmes_are_part_of_documentation_scan(self):
        relative = {path.relative_to(REPOSITORY_ROOT).as_posix() for path in markdown_files()}
        self.assertIn("examples/README.md", relative)
        self.assertIn("examples/calculator/README.md", relative)
        self.assertIn("examples/thunder/README.md", relative)
        self.assertIn("examples/contra/README.md", relative)

    def test_local_markdown_anchor_must_exist(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            (root / "target.md").write_text("# Existing section\n", encoding="utf-8")
            source = root / "source.md"
            source.write_text("[bad](target.md#missing)\n", encoding="utf-8")
            self.assertEqual(len(broken_links(source)), 1)

    def test_surface_check_requires_type_page_and_member(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            source = root / "src"
            api = root / "api"
            source.mkdir()
            api.mkdir()
            (source / "state.cj").write_text(
                "package sdl\npublic class State {\n    public func get(): Int64 { 0 }\n}\n",
                encoding="utf-8",
            )
            (api / "index.md").write_text("# sdl\n", encoding="utf-8")
            failures = api_surface_failures(source, api)
            self.assertTrue(any("missing API page" in item for item in failures))

    def test_surface_check_counts_overloads(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            source = root / "src"
            api = root / "api"
            source.mkdir()
            api.mkdir()
            (source / "state.cj").write_text(
                "package sdl\npublic class State {\n"
                "    public func set(value: Int64): Unit {}\n"
                "    public func set(value: String): Unit {}\n}\n",
                encoding="utf-8",
            )
            (api / "index.md").write_text("# sdl\n\n[State](State.md)\n", encoding="utf-8")
            (api / "State.md").write_text(
                "# State\n\n```cangjie\npublic class State {\n"
                "    public func set(value: Int64): Unit\n}\n```\n",
                encoding="utf-8",
            )
            failures = api_surface_failures(source, api)
            self.assertTrue(any("1/2 overloads" in item for item in failures))

    def test_surface_check_includes_public_extension_members(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            source = root / "src"
            api = root / "api"
            source.mkdir()
            api.mkdir()
            (source / "state.cj").write_text("package sdl\npublic class State {}\n", encoding="utf-8")
            (source / "state_ext.cj").write_text(
                "package sdl\nextend State {\n    public func refresh(): Unit {}\n}\n",
                encoding="utf-8",
            )
            (api / "index.md").write_text("# sdl\n\n[State](State.md)\n", encoding="utf-8")
            (api / "State.md").write_text(
                "# State\n\n```cangjie\npublic class State\n```\n",
                encoding="utf-8",
            )
            failures = api_surface_failures(source, api)
            self.assertTrue(any("State.refresh" in item for item in failures))

    def test_surface_check_rejects_changed_callable_signature(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            source = root / "src"
            api = root / "api"
            source.mkdir()
            api.mkdir()
            (source / "state.cj").write_text(
                "package sdl\npublic class State {\n"
                "    public func set(value: Int64, eager!: Bool = false): Unit {}\n}\n",
                encoding="utf-8",
            )
            (api / "index.md").write_text("# sdl\n\n[State](State.md)\n", encoding="utf-8")
            (api / "State.md").write_text(
                "# State\n\n```cangjie\npublic class State\n"
                "public func set(value: String, eager!: Bool = false): Unit\n```\n",
                encoding="utf-8",
            )
            failures = api_surface_failures(source, api)
            self.assertTrue(any("omits or changes signature" in item for item in failures))

    def test_strict_snippet_must_be_complete(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            (root / "guide.md").write_text("```cangjie\nlet value = 1\n```\n", encoding="utf-8")
            snippets, failures = verified_snippets((root,), strict_roots=(root,), declaration_roots=())
            self.assertEqual(snippets, [])
            self.assertEqual(len(failures), 1)

    def test_verified_snippet_records_source_location(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            page = root / "guide.md"
            page.write_text(
                "# Example\n\n```cangjie verify role=complete\n"
                "package docexample\n\nmain(): Unit {}\n```\n",
                encoding="utf-8",
            )
            snippets, failures = verified_snippets((root,))
            self.assertEqual(failures, [])
            self.assertEqual(snippets[0].line, 4)


if __name__ == "__main__":
    unittest.main()
