"""Build public examples and optionally run their native startup regressions."""

import argparse
from pathlib import Path

from sdl_dev.common.paths import REPOSITORY_ROOT
from sdl_dev.common.process import run_command


EXAMPLES_ROOT = REPOSITORY_ROOT / "examples"


def discover_examples(root: Path = EXAMPLES_ROOT) -> list[Path]:
    return sorted(path.parent for path in root.glob("*/cjpm.toml") if not path.parent.name.startswith("."))


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--action", choices=("build", "test", "all"), default="build",
                        help="test/all requires a graphical desktop; default build remains headless-safe")
    arguments = parser.parse_args(argv)
    if arguments.timeout <= 0:
        parser.error("--timeout must be positive")
    examples = discover_examples()
    if not examples:
        print("No public example projects found.")
        return 1
    failed = False
    for example in examples:
        actions = ("build", "test") if arguments.action == "all" else (arguments.action,)
        for action in actions:
            command = ["cjpm", action]
            if action == "test":
                command += ["--no-progress", "--timeout-each", "60s"]
            code, stdout, stderr, timed_out = run_command(command, example, arguments.timeout)
            if code == 0 and not timed_out:
                print(f"[PASS] {example.relative_to(REPOSITORY_ROOT)} {action}", flush=True)
            else:
                failed = True
                reason = "timed out" if timed_out else f"exited with {code}"
                print(f"[FAIL] {example.relative_to(REPOSITORY_ROOT)} {action}: {reason}", flush=True)
                print((stdout + stderr).rstrip())
                break
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
