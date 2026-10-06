#!/usr/bin/env python3
"""
IRIS Batch Runner
Sequential, resumable, one-self-contained-call-per-image orchestration.

Usage:
  python iris_batch.py manifest.json
  python iris_batch.py manifest.json --dry-run
  python iris_batch.py manifest.json --force
"""

from __future__ import annotations
import argparse
import json
import re
import sys
import traceback
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict

import importlib.util
_ADAPTER = Path(__file__).resolve().parent / "IRIS_v1.8_PROVIDER_ADAPTER.py"
_spec = importlib.util.spec_from_file_location("iris_provider_adapter", _ADAPTER)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
generate_image = _mod.generate_image


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def slug(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9._-]+", "_", s)
    return re.sub(r"_+", "_", s).strip("_") or "item"


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    tmp.replace(path)


def compose_prompt(manifest: Dict[str, Any], item: Dict[str, Any], index: int) -> str:
    parts = [
        "IRIS BATCH JOB — SELF-CONTAINED GENERATION SPECIFICATION",
        f"BATCH: {manifest['batch_id']}",
        f"INDEX: {index:03d}",
        f"ASSET ID: {item['asset_id']}",
        f"VIEW: {item['view']}",
        "",
        "GLOBAL DIRECTIVE:",
        manifest.get("global_prompt", "").strip(),
        "",
        "ASSET / CONTINUITY LOCK:",
        manifest.get("asset_lock", "").strip(),
        "",
        "THIS IMAGE:",
        item.get("prompt", "").strip(),
    ]

    neg = item.get("negative_prompt", "").strip()
    if neg:
        parts += ["", "AVOID / NEGATIVE CONSTRAINTS:", neg]

    qa = manifest.get("qa_prompt", "").strip()
    if qa:
        parts += ["", "POST-GENERATION QA DIRECTIVE:", qa]

    parts += [
        "",
        "AUTONOMY:",
        "Resolve routine visual, technical, material, camera and lighting choices autonomously.",
        "Ask for user input only if a material user-owned ambiguity cannot be reasonably inferred.",
        "Preserve successful locked features during any retry or correction."
    ]
    return "\n".join(parts).strip() + "\n"


def initial_state(manifest: Dict[str, Any]) -> Dict[str, Any]:
    state = deepcopy(manifest)
    state["created_at"] = utc_now()
    state["updated_at"] = utc_now()
    state["jobs"] = []
    for i, item in enumerate(manifest["items"], 1):
        state["jobs"].append({
            "index": i,
            "asset_id": item["asset_id"],
            "view": item["view"],
            "status": "pending",
            "attempts": 0,
            "output": None,
            "last_error": None,
            "qa": None,
            "started_at": None,
            "completed_at": None,
        })
    return state


def sync_state(manifest: Dict[str, Any], state: Dict[str, Any]) -> None:
    # Preserve existing job status by index but add any newly appended jobs.
    existing = {j["index"]: j for j in state.get("jobs", [])}
    new_jobs = []
    for i, item in enumerate(manifest["items"], 1):
        j = existing.get(i) or {
            "index": i,
            "status": "pending",
            "attempts": 0,
            "output": None,
            "last_error": None,
            "qa": None,
            "started_at": None,
            "completed_at": None,
        }
        j["asset_id"] = item["asset_id"]
        j["view"] = item["view"]
        new_jobs.append(j)
    state["jobs"] = new_jobs
    state["updated_at"] = utc_now()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest", type=Path)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--force", action="store_true", help="Regenerate completed items")
    args = ap.parse_args()

    manifest = load_json(args.manifest)

    if manifest.get("sequential", True) is not True:
        raise ValueError("IRIS v1.0 batch runner requires sequential=true.")

    out_dir = Path(manifest.get("output_dir", "outputs"))
    out_dir.mkdir(parents=True, exist_ok=True)

    state_path = out_dir / f"{slug(manifest['batch_id'])}_state.json"
    if state_path.exists():
        state = load_json(state_path)
        sync_state(manifest, state)
    else:
        state = initial_state(manifest)

    save_json(state_path, state)

    max_retries = int(manifest.get("max_retries", 2))

    for i, item in enumerate(manifest["items"], 1):
        job = state["jobs"][i - 1]

        if job["status"] == "completed" and not args.force:
            print(f"[{i:03d}] SKIP completed: {item['asset_id']} / {item['view']}")
            continue

        prompt = compose_prompt(manifest, item, i)
        prompt_path = out_dir / f"{slug(manifest['batch_id'])}_{i:03d}_{slug(item['asset_id'])}_{slug(item['view'])}_prompt.txt"
        prompt_path.write_text(prompt, encoding="utf-8")

        stem = f"{slug(manifest['batch_id'])}_{i:03d}_{slug(item['asset_id'])}_{slug(item['view'])}_r1"
        output_path = out_dir / f"{stem}.png"

        if args.dry_run:
            print(f"[{i:03d}] DRY RUN -> {prompt_path}")
            continue

        while job["attempts"] <= max_retries:
            job["status"] = "running"
            job["started_at"] = job["started_at"] or utc_now()
            job["attempts"] += 1
            state["updated_at"] = utc_now()
            save_json(state_path, state)

            try:
                attempt = job["attempts"]
                output_path = out_dir / (
                    f"{slug(manifest['batch_id'])}_{i:03d}_"
                    f"{slug(item['asset_id'])}_{slug(item['view'])}_r{attempt}.png"
                )
                print(f"[{i:03d}] GENERATE attempt {attempt}: {item['asset_id']} / {item['view']}")

                result = generate_image(
                    prompt=prompt,
                    output_path=output_path,
                    reference_images=item.get("reference_images", []),
                    metadata=item.get("metadata", {}),
                )

                job["status"] = "completed"
                job["output"] = str(result)
                job["completed_at"] = utc_now()
                job["last_error"] = None
                state["updated_at"] = utc_now()
                save_json(state_path, state)
                print(f"[{i:03d}] DONE -> {result}")
                break

            except Exception as e:
                job["last_error"] = f"{type(e).__name__}: {e}"
                job["status"] = "failed"
                state["updated_at"] = utc_now()
                save_json(state_path, state)
                print(f"[{i:03d}] ERROR attempt {job['attempts']}: {job['last_error']}", file=sys.stderr)

                if job["attempts"] > max_retries:
                    print(f"[{i:03d}] FAILED after retries; order preserved. Continuing to next item.", file=sys.stderr)
                    break

    state["updated_at"] = utc_now()
    save_json(state_path, state)

    completed = sum(j["status"] == "completed" for j in state["jobs"])
    failed = sum(j["status"] == "failed" for j in state["jobs"])
    pending = sum(j["status"] == "pending" for j in state["jobs"])
    print(f"IRIS batch complete: completed={completed}, failed={failed}, pending={pending}")
    print(f"State: {state_path}")
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
