#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
BRANCH="${2:-}"

if [ -z "$TAG" ] || [ -z "$BRANCH" ]; then
  echo "Usage: $0 <tag> <branch>" >&2
  exit 2
fi

if ! git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
  echo "❌ Release tag $TAG does not exist" >&2
  exit 1
fi

if ! git merge-base --is-ancestor "refs/tags/$TAG" "refs/remotes/origin/$BRANCH"; then
  echo "❌ Release tag $TAG is not on origin/$BRANCH" >&2
  echo "Create the GitHub Release with target $BRANCH after merging develop into $BRANCH." >&2
  exit 1
fi

echo "✅ Release tag $TAG is on origin/$BRANCH"
