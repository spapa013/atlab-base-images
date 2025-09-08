#!/usr/bin/env python3
import json, re, sys
from pathlib import Path
from typing import Any, Dict

root = Path(".")
dpath = root / "build-defaults.json"
if not dpath.exists():
    raise FileNotFoundError(f"Could not find {dpath}")

# Load repo-wide defaults
file_defaults: Dict[str, Any] = json.loads(dpath.read_text()) or {}

def to_csv_platforms(v: Any) -> str:
    if isinstance(v, list):
        return ",".join(v)
    if isinstance(v, str):
        return v
    raise ValueError(f"Invalid 'platforms' (expected list or string), got: {type(v).__name__}")

def sanitize_name(s: str) -> str:
    s = s.strip().lower().replace(" ", "-")
    return re.sub(r"[^a-z0-9._-]", "-", s)

def validate_cfg(cfg: Dict[str, Any], where: str):
    required = ["platforms", "rebuild_policy", "hidden"]
    for k in required:
        if k not in cfg or cfg[k] is None:
            raise ValueError(f"Missing required key '{k}' in {where}")
    if cfg["rebuild_policy"] not in ("project", "file"):
        raise ValueError(f"Invalid 'rebuild_policy' in {where}: {cfg['rebuild_policy']} (expected 'project' or 'file')")
    if not isinstance(cfg["hidden"], bool):
        raise ValueError(f"Invalid 'hidden' in {where}: expected boolean, got {type(cfg['hidden']).__name__}")

# Validate defaults
validate_cfg(file_defaults, str(dpath))

rows = []
dockerfiles = sorted(root.glob("images/**/Dockerfile"), key=lambda p: p.as_posix())

for dockerfile in dockerfiles:
    d = dockerfile.parent
    rel = d.as_posix().removeprefix("images/")
    if not rel:
        print(f"WARNING: Skipping Dockerfile at repo root scope: {dockerfile}", file=sys.stderr, flush=True)
        continue

    inferred = sanitize_name(rel.replace("/", "-"))
    cfg = dict(file_defaults)

    ovr_path = d / "build.json"
    if ovr_path.exists():
        try:
            override = json.loads(ovr_path.read_text()) or {}
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in {ovr_path}: {e}")
        cfg.update(override)
        # validate after applying overrides
        validate_cfg(cfg, str(ovr_path))

    name = sanitize_name(cfg.get("image_name") or inferred)
    platforms_csv = to_csv_platforms(cfg["platforms"])
    rows.append({
        "dir": d.as_posix(),
        "name": name,
        "platforms": platforms_csv,
        "rebuild_policy": cfg["rebuild_policy"],
        "hidden": cfg["hidden"],
        "version": (cfg.get("version") or None),
    })

# Debug summary to logs (stderr)
print("=== DISCOVERED MATRIX ===", file=sys.stderr, flush=True)
print(json.dumps({"include": rows}, indent=2), file=sys.stderr, flush=True)

# Single-line compact JSON to stdout (for GHA step output)
print(json.dumps({"include": rows}, separators=(',', ':')))
