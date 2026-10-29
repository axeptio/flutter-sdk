#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
CHANGELOG="${2:-CHANGELOG.md}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version> [CHANGELOG.md]" >&2
  exit 2
fi

if awk -v h="## $VERSION" '$0 == h || index($0, h " ") == 1 { found = 1 } END { exit !found }' "$CHANGELOG"; then
  echo "✅ '## $VERSION' heading found in $CHANGELOG"
else
  echo "❌ No '## $VERSION' heading in $CHANGELOG" >&2
  echo "Add the entry on develop, merge to master, then create a new tag." >&2
  exit 1
fi
