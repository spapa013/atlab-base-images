#!/usr/bin/env bash
set -euo pipefail

# This script determines the "base" commit SHA to use for change detection.
# It is used in CI to decide what to compare against for incremental builds.

if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
  echo "pick_base: event=pull_request base=${PR_BASE_SHA}" >&2
  echo "base=${PR_BASE_SHA}"

elif [ -n "${PUSH_BEFORE:-}" ] && [ "${PUSH_BEFORE}" != "0000000000000000000000000000000000000000" ]; then
  echo "pick_base: event=push base=${PUSH_BEFORE}" >&2
  echo "base=${PUSH_BEFORE}"

else
  echo "pick_base: event=${GITHUB_EVENT_NAME} base=<none> (new branch / first commit / force-push)" >&2
  echo "base="
fi
