#!/usr/bin/env bash
set -euo pipefail

# This script determines the "base" commit SHA to use for change detection.
# It is used in CI to decide what to compare against for incremental builds.

# If running in a pull request, use the PR's base SHA (the commit the PR is based on).
if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
  echo "base=${PR_BASE_SHA}"

# If this is a push event and we have a valid previous commit SHA, use it.
elif [ -n "${PUSH_BEFORE:-}" ] && [ "${PUSH_BEFORE}" != "0000000000000000000000000000000000000000" ]; then
  echo "base=${PUSH_BEFORE}"

# Otherwise, we don't have a known base (e.g., new branch, first commit, or force-push).
# Signal to downstream logic that everything should be built.
else
  # Unknown base (new branch / first commit / force-push) → signal "build anyway"
  echo "base="
fi