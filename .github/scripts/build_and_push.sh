#!/usr/bin/env bash
# Build & push with the appropriate tags.
# Inputs (env):
#   DIR              (context dir, e.g., images/python/scientific)
#   IMAGE            (fq name)
#   PLATFORMS        (e.g., "linux/amd64" or "linux/amd64,linux/arm64")
#   CURR_VERSION     (tag-safe version or empty)
#   VERSION_CHANGED  ("true" | "false")

set -euo pipefail
req() { : "${!1:?missing env var $1}"; }
req DIR
req IMAGE
req PLATFORMS
req VERSION_CHANGED
CURR_VERSION="${CURR_VERSION:-}"

sha_tag="sha-$(git rev-parse --short=7 HEAD)"

# Assemble tags
TAGS=(-t "${IMAGE}:${sha_tag}" -t "${IMAGE}:edge")
if [ "$VERSION_CHANGED" = "true" ] && [ -n "$CURR_VERSION" ]; then
  TAGS+=(-t "${IMAGE}:${CURR_VERSION}" -t "${IMAGE}:latest")
fi

echo "build_and_push: image=${IMAGE} plats=${PLATFORMS} tags=${TAGS[*]#-t }" >&2

# Single buildx invocation
docker buildx build \
  --push \
  --platform "${PLATFORMS}" \
  -f "${DIR}/Dockerfile" \
  "${TAGS[@]}" \
  --cache-from type=gha \
  --cache-to   type=gha,mode=max \
  "${DIR}"
