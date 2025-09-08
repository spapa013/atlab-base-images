#!/usr/bin/env bash
# Emits one line (stdout) for GHA step output:
#   changed=<true|false>
#
# Inputs (via env):
#   POLICY      ("project" or "file")
#   MATRIX_DIR  (e.g., images/python/scientific)
#   BASE_SHA    (optional; empty means "no known base")

set -euo pipefail

req() { : "${!1:?missing env var $1}"; }
req POLICY
req MATRIX_DIR
BASE_SHA="${BASE_SHA:-}"

# check that matrix dir exists
[ -d "$MATRIX_DIR" ] || { echo "bad MATRIX_DIR: $MATRIX_DIR" >&2; echo "changed=false"; exit 0; }

# If no base SHA is provided, always trigger a rebuild (new branch / first commit)
if [ -z "$BASE_SHA" ]; then
  echo "check_for_changes: policy=$POLICY dir=$MATRIX_DIR base=<none> -> true (new branch/first commit)" >&2
  echo "changed=true"
  exit 0
fi

if [ "$POLICY" = "file" ]; then
  path="$MATRIX_DIR/Dockerfile"
  if git diff --name-only "$BASE_SHA"...HEAD -- "$path" | grep . >/dev/null; then
    echo "check_for_changes: policy=file dir=$MATRIX_DIR base=$BASE_SHA -> true (Dockerfile changed)" >&2
    echo "changed=true"
  else
    echo "check_for_changes: policy=file dir=$MATRIX_DIR base=$BASE_SHA -> false (Dockerfile unchanged)" >&2
    echo "changed=false"
  fi
else
  if git diff --name-only "$BASE_SHA"...HEAD -- "$MATRIX_DIR" | grep . >/dev/null; then
    echo "check_for_changes: policy=project dir=$MATRIX_DIR base=$BASE_SHA -> true (some file changed)" >&2
    echo "changed=true"
  else
    echo "check_for_changes: policy=project dir=$MATRIX_DIR base=$BASE_SHA -> false (no files changed)" >&2
    echo "changed=false"
  fi
fi
