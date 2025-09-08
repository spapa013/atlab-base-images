#!/usr/bin/env bash
# Emits one line for GHA step outputs:
#   image=<fq-image-name>
#
# Inputs (via env):
#   DEFAULT_BRANCH   (e.g. main)
#   REF_NAME         (e.g. main, feature/foo)
#   IMAGE_PREFIX     (e.g. ghcr.io/owner/repo)
#   IMAGE_BASE_NAME  (e.g. python-scientific)

set -euo pipefail
req() { : "${!1:?missing env var $1}"; }
req DEFAULT_BRANCH
req REF_NAME
req IMAGE_PREFIX
req IMAGE_BASE_NAME

sanitize_branch() {
  # lowercase; spaces -> '-', '/' '^' '$' -> '-', allow only [a-z0-9._-]; truncate 100
  echo "$1" \
    | tr '[:upper:] ' '[:lower:]-' \
    | tr '/^$' '---' \
    | tr -cd 'a-z0-9._-\n' \
    | cut -c1-100
}

if [ "$REF_NAME" = "$DEFAULT_BRANCH" ]; then
  image="${IMAGE_PREFIX}/${IMAGE_BASE_NAME}"
  scope="default-branch"
else
  image="${IMAGE_PREFIX}/${IMAGE_BASE_NAME}-br-$(sanitize_branch "$REF_NAME")"
  scope="branch"
fi

# Debug summary
echo "derive_image: scope=$scope ref=$REF_NAME image=$image" >&2

# Output for GHA
echo "image=$image"
