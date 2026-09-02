"""Cross-platform subprocess capture with process-tree timeout cleanup."""

import locale
import os
import signal
import subprocess


def _terminate_process_tree(process: subprocess.Popen) -> None:
    try:
        if os.name == "nt":
            killed = subprocess.run(
                ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                capture_output=True,
                timeout=10,
            )
            if killed.returncode != 0:
                process.kill()
        else:
            os.killpg(process.pid, signal.SIGKILL)
    except (OSError, subprocess.SubprocessError):
        try:
            process.kill()
        except OSError:
            pass


def decode_output(data: bytes | str | None, fallback_encoding: str | None = None) -> str:
    if not data:
        return ""
    if isinstance(data, str):
        return data
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        fallback = fallback_encoding or locale.getpreferredencoding(False)
        if fallback.lower().replace("_", "-") not in {"utf-8", "utf8"}:
            try:
                return data.decode(fallback)
            except (LookupError, UnicodeDecodeError):
                pass
        return data.decode("utf-8", errors="replace")


def run_command(command: list[str], cwd, timeout: int) -> tuple[int, str, str, bool]:
    options = {
        "cwd": cwd,
        "stdout": subprocess.PIPE,
        "stderr": subprocess.PIPE,
    }
    if os.name == "nt":
        options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        options["start_new_session"] = True
    try:
        process = subprocess.Popen(command, **options)
    except OSError as error:
        return 127, "", str(error), False
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        return process.returncode, decode_output(stdout), decode_output(stderr), False
    except subprocess.TimeoutExpired:
        _terminate_process_tree(process)
        stdout, stderr = process.communicate()
        return 124, decode_output(stdout), decode_output(stderr), True
