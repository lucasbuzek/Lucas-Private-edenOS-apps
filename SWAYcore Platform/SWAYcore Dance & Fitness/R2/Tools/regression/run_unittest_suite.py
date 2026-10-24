#!/usr/bin/env python3
"""Run a unittest discovery gate and reject an accidentally empty suite."""

from __future__ import annotations

import argparse
import sys
import unittest


def count_cases(suite: unittest.TestSuite) -> int:
    return suite.countTestCases()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--start-directory", "-s", required=True)
    parser.add_argument("--pattern", "-p", default="test*.py")
    parser.add_argument("--top-level-directory", "-t")
    args = parser.parse_args()

    suite = unittest.defaultTestLoader.discover(
        start_dir=args.start_directory,
        pattern=args.pattern,
        top_level_dir=args.top_level_directory,
    )
    discovered = count_cases(suite)
    print(f"Discovered {discovered} test(s) in {args.start_directory!r} matching {args.pattern!r}")
    if discovered == 0:
        print("FAIL: zero-test discovery is never a passing gate", file=sys.stderr)
        return 3
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
