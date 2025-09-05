#!/usr/bin/env bash
# Usage: changed.sh <policy:project|file> <dir> <base_sha_or_empty>
set -euo pipefail

# Arguments:
#   $1 - policy: "project" (check all files in dir) or "file" (check only Dockerfile)
#   $2 - dir: directory containing the Dockerfile
#   $3 - base: base git SHA to compare against (can be empty)

policy="$1"
dir="$2"
base="${3:-}"

# If no base SHA is provided, always trigger a rebuild (e.g., new branch or first commit)
if [ -z "$base" ]; then
  echo "true"
  exit 0
fi

if [ "$policy" = "file" ]; then
  # Only check if the Dockerfile itself changed
  path="$dir/Dockerfile"
  if git diff --name-only "$base"...HEAD -- "$path" | grep . >/dev/null; then
    echo "true"
  else
    echo "false"
  fi
else
  # Check if any file in the directory changed
  if git diff --name-only "$base"...HEAD -- "$dir" | grep . >/dev/null; then
    echo "true"
  else
    echo "false"
  fi