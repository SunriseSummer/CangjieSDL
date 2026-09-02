"""Build each public example as an independent API consumer."""

import argparse
from pathlib import Path

from sdl_dev.common.paths import REPOSITORY_ROOT
from sdl_dev.common.process import run_command


EXAMPLES_ROOT = REPOSITORY_ROOT / "examples"


def discover_examples(root: Path = EXAMPLES_ROOT) -> list[Path]:
    return sorted(path.parent for path in root.glob("*/cjpm.toml") if not path.parent.name.startswith("."))


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="build public CangjieSDL examples")
    parser.add_argument("--timeout", type=int, default=300)
    arguments = parser.parse_args(argv)
    examples = discover_examples()
    if not examples:
        print("No public example projects found.")
        return 1
    failed = False
    for example in examples:
        code, stdout, stderr, timed_out = run_command(["cjpm", "build"], example, arguments.timeout)
        if code == 0:
            print(f"[PASS] {example.relative_to(REPOSITORY_ROOT)}")
        else:
            failed = True
            reason = "timed out" if timed_out else f"exited with {code}"
            print(f"[FAIL] {example.relative_to(REPOSITORY_ROOT)}: {reason}")
            print((stdout + stderr).rstrip())
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
