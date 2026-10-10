"""BIFROST Headless read-only adapter to the portable DP0.1 kernel.

The shared SQLite database is indexed only by explicit CLI/native user action.
This module does not scan the machine on startup and never exposes absolute paths.
"""
import importlib.util
import pathlib
import sqlite3

PATH = pathlib.Path(__file__).resolve().parent
PORTABLE = PATH / "portable_kernel.py"
if not PORTABLE.is_file():
    PORTABLE = PATH.parent / "core" / "portable_kernel.py"


def load_kernel():
    if not PORTABLE.is_file():
        raise RuntimeError("BIFROST portable kernel is not packaged")
    specification = importlib.util.spec_from_file_location("bifrost_portable_kernel", str(PORTABLE))
    kernel = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(kernel)
    return kernel


def storage_path(support):
    return pathlib.Path(support) / "kernel" / "index.sqlite"


def status(support):
    db = storage_path(support)
    if not db.exists():
        return {"schema": "bifrost.dp0.1", "state": "NOT_INDEXED",
                "source_count": 0, "object_count": 0, "scan": "explicit-only"}
    try:
        portable = load_kernel()
        with portable.Kernel(db) as instance:
            state = instance.status()
        return {
            "schema": state["schema"],
            "state": "INDEX_AVAILABLE",
            "source_count": state["sources"],
            "object_count": state["objects"],
            "location_count": state["locations"],
            "relationship_count": state["relationships"],
            "provenance_count": state["provenance"],
            "last_run": state["last_run"],
            "scan": "explicit-only",
        }
    except (OSError, RuntimeError, ValueError, sqlite3.Error):
        return {"schema": "bifrost.dp0.1", "state": "INDEX_ERROR",
                "scan": "explicit-only"}


def search(support, term, limit=25):
    if not isinstance(term, str) or not 1 <= len(term.strip()) <= 128:
        raise ValueError("query must be 1–128 characters")
    if not isinstance(limit, int) or not 1 <= limit <= 50:
        raise ValueError("limit must be 1–50")
    db = storage_path(support)
    if not db.is_file():
        return {"state": "NOT_INDEXED", "matches": []}
    portable = load_kernel()
    with portable.Kernel(db) as instance:
        result = instance.search(term, limit)
    return {"state": "INDEX_AVAILABLE", "matches": result}
