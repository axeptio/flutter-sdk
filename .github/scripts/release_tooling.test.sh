#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAILED=0

pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; FAILED=1; }

for f in .github/workflows/semver-release.yml .github/workflows/beta-release.yml \
         .releaserc.json .releaserc-beta.json package.json package-lock.json; do
  if [ -e "$ROOT/$f" ]; then fail "dead release tooling removed: $f"; else pass "dead release tooling removed: $f"; fi
done

if grep -rqiE 'semantic-release|releaserc' "$ROOT/.github/workflows"; then
  fail "no workflow references semantic-release"
else
  pass "no workflow references semantic-release"
fi

exit "$FAILED"
