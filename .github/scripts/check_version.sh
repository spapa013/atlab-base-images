#!/usr/bin/env bash
# Emits two lines for GHA step outputs:
#   curr_version=<tag-safe version or empty>
#   version_changed=<true|false>
#
# Inputs (via env):
#   MATRIX_DIR   (e.g. images/python/scientific)
#   BASE_SHA     (optional; empty means "no known base")

set -euo pipefail
req() { : "${!1:?missing env var $1}"; }
req MATRIX_DIR
BASE_SHA="${BASE_SHA:-}"

# Current version (from working tree)
curr=""
if [ -f "$MATRIX_DIR/build.json" ]; then
  curr="$(jq -r '.version // empty' "$MATRIX_DIR/build.json" || true)"
fi

# Previous version (from base commit), best-effort
prev=""
if [ -n "$BASE_SHA" ]; then
  git show "$BASE_SHA:$MATRIX_DIR/build.json" >/tmp/_prev.json 2>/dev/null || true
  if [ -s /tmp/_prev.json ]; then
    prev="$(jq -r '.version // empty' /tmp/_prev.json || true)"
  fi
fi

# Tag-safety check (Docker tag charset, <=128 chars)
tag_re='^[A-Za-z0-9_.-]{1,128}$'
valid_curr=false; valid_prev=false
[[ -n "$curr" && "$curr" =~ $tag_re ]] && valid_curr=true || true
[[ -n "$prev" && "$prev" =~ $tag_re ]] && valid_prev=true || true

version_changed=false
if $valid_curr; then
  if ! $valid_prev || [ "$curr" != "$prev" ]; then
    version_changed=true
  fi
fi

# Debug summary
echo "detect_version: curr=${curr:-<none>} prev=${prev:-<none>} changed=$version_changed" >&2

# Outputs for GHA
echo "curr_version=$curr"
echo "version_changed=$version_changed"
