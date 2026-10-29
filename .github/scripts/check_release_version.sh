#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
PUBSPEC="${2:-}"

if [ -z "$TAG" ]; then
  echo "Usage: $0 <tag> [pubspec.yaml]" >&2
  exit 2
fi

VERSION="${TAG#v}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.\-]+)?$ ]]; then
  echo "❌ Invalid version format: $VERSION (expected X.Y.Z or X.Y.Z-suffix)" >&2
  exit 1
fi

if [ -n "$PUBSPEC" ]; then
  CONTENT="$(cat "$PUBSPEC")"
  SOURCE="$PUBSPEC"
else
  if ! git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "❌ Release tag $TAG does not exist" >&2
    exit 1
  fi
  CONTENT="$(git show "refs/tags/$TAG:pubspec.yaml")"
  SOURCE="pubspec.yaml at $TAG"
fi

PUBSPEC_VERSION="$(printf '%s\n' "$CONTENT" | sed -n -E "s/^version:[[:space:]]*[\"']?([^\"'[:space:]]+)[\"']?[[:space:]]*$/\1/p" | head -n 1)"
if [ -z "$PUBSPEC_VERSION" ]; then
  echo "❌ No version found in $SOURCE" >&2
  exit 1
fi

if [ "$PUBSPEC_VERSION" != "$VERSION" ]; then
  echo "❌ pubspec.yaml version $PUBSPEC_VERSION does not match tag $TAG ($SOURCE)" >&2
  echo "Bump the version in pubspec.yaml on develop, merge to master, then create a new tag." >&2
  exit 1
fi

echo "✅ pubspec.yaml version $PUBSPEC_VERSION matches tag $TAG"
