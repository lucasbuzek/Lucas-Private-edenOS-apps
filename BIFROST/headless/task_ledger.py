"""BIFROST local Headless task receipts.

A minimal durable ledger for *read-only local observations*. This does not
dispatch to providers, run shells, accept arbitrary commands, or claim remote
execution. Files belong to the local user's private Application Support.
"""
from __future__ import annotations

import json
import os
import pathlib
import re
import secrets
import sqlite3
import time

SCHEMA = "bifrost.local-task.v1"
KIND = "local.status.snapshot"
TASK_PATTERN = re.compile(r"local_[0-9a-f]{32}\Z")
KEY_PATTERN = re.compile(r"[a-zA-Z0-9_-]{8,64}\Z")
MAX_LIST = 50
DATABASE = "local_tasks.sqlite3"


class TaskError(ValueError):
    """Invalid local observation request."""


def _connect(support: pathlib.Path):
    support.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(support, 0o700)
    path = support / DATABASE
    if path.is_symlink():
        raise TaskError("ledger path must not be a symlink")
    db = sqlite3.connect(str(path), timeout=4.0)
    try:
        # A single database file avoids persistent WAL/shm companion files.
        # FULL synchronous commits make a returned receipt durable.
        db.execute("PRAGMA journal_mode=DELETE")
        db.execute("PRAGMA synchronous=FULL")
        db.execute("PRAGMA busy_timeout=4000")
        db.execute("""
            CREATE TABLE IF NOT EXISTS local_tasks (
                task_id TEXT PRIMARY KEY,
                idempotency_key TEXT UNIQUE,
                kind TEXT NOT NULL CHECK (kind = 'local.status.snapshot'),
                state TEXT NOT NULL CHECK (state = 'completed'),
                created_at INTEGER NOT NULL,
                result_json TEXT NOT NULL
            )
        """)
        db.execute("CREATE INDEX IF NOT EXISTS local_tasks_recent ON local_tasks(created_at DESC)")
        os.chmod(path, 0o600)
        return db
    except BaseException:
        db.close()
        raise


def _public(row):
    task_id, key, kind, state, created, value = row
    return {
        "schema": SCHEMA,
        "taskId": task_id,
        "kind": kind,
        "state": state,
        "createdAt": created,
        "idempotencyKey": key,
        "execution": "local-readonly-observation",
        "remoteExecutionVerified": False,
        "result": json.loads(value),
    }


def record(support: pathlib.Path, request, observation):
    """Atomic idempotent recording of a LOCAL observed-state receipt.

    The observation argument is produced by Headless, never supplied by a
    browser. Idempotency keys are opaque client-generated handles, not actions.
    """
    if not isinstance(request, dict) or set(request) - {"kind", "idempotencyKey"}:
        raise TaskError("unexpected local task parameters")
    if request.get("kind") != KIND:
        raise TaskError("unsupported local task kind")
    key = request.get("idempotencyKey")
    if key is not None and (not isinstance(key, str) or not KEY_PATTERN.fullmatch(key)):
        raise TaskError("invalid idempotency key")
    if not isinstance(observation, dict) or type(observation.get("caffeinateActive")) is not bool:
        raise TaskError("invalid local observation")
    # Only Headless status is stored. Never store credentials, arbitrary user
    # prompts, local paths, machine identifiers or third-party provider state.
    result = {
        "schema": "bifrost.local-observation.v1",
        "headless": "running",
        "caffeinateActive": observation["caffeinateActive"],
        "scope": "local-only",
        "remoteTaskId": None,
    }
    timestamp = int(time.time() * 1000)
    db = _connect(support)
    try:
        db.execute("BEGIN IMMEDIATE")
        if key is not None:
            row = db.execute(
                "SELECT task_id,idempotency_key,kind,state,created_at,result_json "
                "FROM local_tasks WHERE idempotency_key=?", (key,)
            ).fetchone()
            if row:
                db.commit()
                return _public(row), False
        task_id = "local_" + secrets.token_hex(16)
        db.execute(
            "INSERT INTO local_tasks(task_id,idempotency_key,kind,state,created_at,result_json) "
            "VALUES(?,?,?,?,?,?)",
            (task_id, key, KIND, "completed", timestamp,
             json.dumps(result, sort_keys=True, separators=(",", ":"))),
        )
        row = db.execute(
            "SELECT task_id,idempotency_key,kind,state,created_at,result_json "
            "FROM local_tasks WHERE task_id=?", (task_id,)
        ).fetchone()
        db.commit()
        return _public(row), True
    except BaseException:
        db.rollback()
        raise
    finally:
        db.close()


def get(support: pathlib.Path, task_id):
    if not isinstance(task_id, str) or not TASK_PATTERN.fullmatch(task_id):
        raise TaskError("invalid task id")
    db = _connect(support)
    try:
        row = db.execute(
            "SELECT task_id,idempotency_key,kind,state,created_at,result_json "
            "FROM local_tasks WHERE task_id=?", (task_id,)
        ).fetchone()
        return _public(row) if row else None
    finally:
        db.close()


def recent(support: pathlib.Path, limit=20):
    if type(limit) is not int or not 1 <= limit <= MAX_LIST:
        raise TaskError("invalid list limit")
    db = _connect(support)
    try:
        rows = db.execute(
            "SELECT task_id,idempotency_key,kind,state,created_at,result_json "
            "FROM local_tasks ORDER BY created_at DESC, task_id DESC LIMIT ?",
            (limit,),
        ).fetchall()
        return {"schema": "bifrost.local-task-list.v1",
                "tasks": [_public(row) for row in rows],
                "count": len(rows),
                "remoteExecutionVerified": False}
    finally:
        db.close()
