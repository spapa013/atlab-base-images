#!/usr/bin/env bash
# Build locally (no push) for PR validation.
# Inputs (env):
#   DIR         (build context, e.g., images/python/scientific)
#   PLATFORMS   (target platforms, e.g. linux/amd64,linux/arm64; default: linux/amd64)

set -euo pipefail
req() { : "${!1:?missing env var $1}"; }
req DIR
PLATFORMS="${PLATFORMS:-linux/amd64}"

echo "build_for_pr: dir=${DIR} platforms=${PLATFORMS} (no push; PR validation)" >&2

# Use --load so the image loads into the local Docker engine on the runner,
# which provides a stronger validation than --output=type=registry would.
docker buildx build \
  --load \
  --platform "${PLATFORMS}" \
  -f "${DIR}/Dockerfile" \
  "${DIR}"
