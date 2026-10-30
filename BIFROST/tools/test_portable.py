#!/usr/bin/env python3
"""Run the recovered portable suites; native/device acceptance is separate."""
from pathlib import Path
import shutil
import subprocess
import sys

from build_pwa_icons import png

ROOT = Path(__file__).resolve().parents[1]


def main():
    # Recover missing build products with the established generator. Never
    # overwrite an existing icon or download assets during an offline test run.
    icons = ROOT / "headless" / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    for size in (192, 512):
        path = icons / f"icon-{size}.png"
        if not path.exists():
            with path.open("xb") as output:
                output.write(png(size))
    commands = [[sys.executable, "-B", "-m", "unittest", "discover", "-s", "tests"]]
    node = shutil.which("node")
    if node:
        tests = sorted(set((ROOT / "tests").glob("*.test.mjs")) |
                       set((ROOT / "tests").glob("test*.mjs")))
        commands.append([node, "--test", *[str(p) for p in tests]])
    failed = not node
    if not node:
        print("BLOCKED: Node.js is required for JavaScript verification", file=sys.stderr)
    for command in commands:
        failed |= subprocess.run(command, cwd=ROOT, check=False).returncode != 0
    print("Portable checks only; no native build, device test or LKG promotion.")
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
