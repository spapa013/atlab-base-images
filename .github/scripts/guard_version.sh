#!/usr/bin/env bash
# Guard against overwriting immutable version tags.
# Inputs (env):
#   IMAGE           (e.g., ghcr.io/org/repo/python-scientific[-br-branch])
#   CURR_VERSION    (tag-safe version or empty)
#   VERSION_CHANGED ("true" | "false")

set -euo pipefail
req() { : "${!1:?missing env var $1}"; }
req IMAGE
req VERSION_CHANGED
CURR_VERSION="${CURR_VERSION:-}"

if [ "$VERSION_CHANGED" != "true" ] || [ -z "$CURR_VERSION" ]; then
  echo "guard_version: skip (version_changed=$VERSION_CHANGED, version='${CURR_VERSION:-<none>}')" >&2
  exit 0
fi

if docker manifest inspect "${IMAGE}:${CURR_VERSION}" >/dev/null 2>&1; then
  echo "ERROR: ${IMAGE}:${CURR_VERSION} already exists. Version tags are immutable. Bump the version." >&2
  exit 1
fi

echo "guard_version: ok (no existing ${IMAGE}:${CURR_VERSION})" >&2
