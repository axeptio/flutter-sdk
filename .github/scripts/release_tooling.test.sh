#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$ROOT/.github/scripts/check_release_version.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILED=0

pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; FAILED=1; }

pubspec() {
  printf 'name: axeptio_sdk\ndescription: x\nversion: %s\n\nenvironment:\n  sdk: ">=3.3.1 <4.0.0"\n' "$1" > "$WORK/pubspec.yaml"
}

expect_pass() {
  local label="$1"; shift
  if out="$("$@" 2>&1)"; then pass "$label"; else fail "$label: $out"; fi
}

expect_fail() {
  local label="$1" needle="$2"; shift 2
  if out="$("$@" 2>&1)"; then
    fail "$label: exited 0"
  elif [[ "$out" != *"$needle"* ]]; then
    fail "$label: missing '$needle' in: $out"
  else
    pass "$label"
  fi
}

for f in .github/workflows/semver-release.yml .github/workflows/beta-release.yml \
         .releaserc.json .releaserc-beta.json package.json package-lock.json; do
  if [ -e "$ROOT/$f" ]; then fail "dead release tooling removed: $f"; else pass "dead release tooling removed: $f"; fi
done

if grep -rqiE 'semantic-release|releaserc' "$ROOT/.github/workflows"; then
  fail "no workflow references semantic-release"
else
  pass "no workflow references semantic-release"
fi

if grep -q 'sed -i "s/version: ' "$ROOT/.github/workflows/publish.yml"; then
  fail "publish.yml does not rewrite pubspec.yaml"
else
  pass "publish.yml does not rewrite pubspec.yaml"
fi

if grep -q 'check_release_version.sh' "$ROOT/.github/workflows/publish.yml"; then
  pass "publish.yml runs the version guard"
else
  fail "publish.yml runs the version guard"
fi

if grep -qF "ref: \${{ github.event.release.tag_name || inputs.release_tag }}" "$ROOT/.github/workflows/publish.yml"; then
  pass "publish.yml checks out the release tag"
else
  fail "publish.yml checks out the release tag"
fi

pubspec 3.0.0
expect_pass "matching stable version passes" "$GUARD" v3.0.0 "$WORK/pubspec.yaml"

pubspec 3.1.0-beta.1
expect_pass "matching pre-release version passes" "$GUARD" v3.1.0-beta.1 "$WORK/pubspec.yaml"

pubspec '"3.0.0"'
expect_pass "quoted pubspec version passes" "$GUARD" v3.0.0 "$WORK/pubspec.yaml"

pubspec 3.0.0
expect_fail "mismatch fails naming both versions" "pubspec.yaml version 3.0.0 does not match tag v3.0.1" \
  "$GUARD" v3.0.1 "$WORK/pubspec.yaml"

pubspec 3.0.0+1
expect_fail "build metadata is not stripped" "3.0.0+1" "$GUARD" v3.0.0 "$WORK/pubspec.yaml"

pubspec 3.0.0
expect_fail "invalid tag format fails" "Invalid version format" "$GUARD" release-3 "$WORK/pubspec.yaml"

printf 'name: axeptio_sdk\n' > "$WORK/pubspec.yaml"
expect_fail "missing version fails" "No version" "$GUARD" v3.0.0 "$WORK/pubspec.yaml"

expect_fail "missing tag argument fails" "Usage" "$GUARD"

REPO="$WORK/repo"
git init -q "$REPO"
git -C "$REPO" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m init
pubspec 3.2.0 && cp "$WORK/pubspec.yaml" "$REPO/pubspec.yaml"
git -C "$REPO" add pubspec.yaml
git -C "$REPO" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q -m release
git -C "$REPO" -c tag.gpgsign=false tag v3.2.0
pubspec 9.9.9 && cp "$WORK/pubspec.yaml" "$REPO/pubspec.yaml"
# test: the working tree diverges from the tag; the guard must read the tagged pubspec.yaml
expect_pass "reads pubspec.yaml at the tag, not the working tree" bash -c "cd '$REPO' && '$GUARD' v3.2.0"
expect_fail "missing tag fails" "does not exist" bash -c "cd '$REPO' && '$GUARD' v3.3.0"

exit "$FAILED"
