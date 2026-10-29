#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$ROOT/.github/scripts/check_release_version.sh"
BRANCH_GUARD="$ROOT/.github/scripts/check_release_branch.sh"
CHANGELOG_GUARD="$ROOT/.github/scripts/check_changelog_entry.sh"
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

DRY_RUN="$ROOT/.github/workflows/dry-run-publish.yml"
if grep -q 'sed -i "s/version: ' "$DRY_RUN"; then
  fail "dry-run-publish.yml does not rewrite pubspec.yaml"
else
  pass "dry-run-publish.yml does not rewrite pubspec.yaml"
fi

if grep -q 'check_release_version.sh' "$DRY_RUN"; then
  pass "dry-run-publish.yml runs the version guard"
else
  fail "dry-run-publish.yml runs the version guard"
fi

if grep -qF "git checkout --detach \"refs/tags/\$RELEASE_TAG\"" "$DRY_RUN"; then
  pass "dry-run-publish.yml validates the tag snapshot when the tag exists"
else
  fail "dry-run-publish.yml validates the tag snapshot when the tag exists"
fi

GUARD_LINE="$(grep -n 'check_release_version.sh' "$DRY_RUN" | head -n 1 | cut -d: -f1)"
CHECKOUT_LINE="$(grep -n 'git checkout --detach' "$DRY_RUN" | head -n 1 | cut -d: -f1)"
# test: tags cut before the guard existed have no script, so it must run from the branch first
if [ -n "$GUARD_LINE" ] && [ -n "$CHECKOUT_LINE" ] && [ "$GUARD_LINE" -lt "$CHECKOUT_LINE" ]; then
  pass "dry-run-publish.yml runs the guard before checking out the tag"
else
  fail "dry-run-publish.yml runs the guard before checking out the tag"
fi

# test: steps after the tag checkout run scripts kept from the branch, absent from older tags
if grep -qF "\"\$RUNNER_TEMP/release-scripts/check_changelog_entry.sh\"" "$DRY_RUN"; then
  pass "dry-run-publish.yml runs post-checkout scripts from the branch copy"
else
  fail "dry-run-publish.yml runs post-checkout scripts from the branch copy"
fi

if grep -qi 'changelog will be auto-generated' "$DRY_RUN"; then
  fail "dry-run-publish.yml does not promise a generated changelog"
else
  pass "dry-run-publish.yml does not promise a generated changelog"
fi

for doc in RELEASE_PROCESS.md CLAUDE.md CONTRIBUTING.md AGENTS.md; do
  if grep -qiE 'semantic.release|semver workflow|Semantic Version Release|"Beta Release" workflow|Beta Release workflow' "$ROOT/$doc"; then
    fail "$doc references only the documented release path"
  else
    pass "$doc references only the documented release path"
  fi
done

for needle in 'develop → master' 'publish.yml' 'release: published' 'dry-run-publish.yml' 'pre-release'; do
  if grep -qiF "$needle" "$ROOT/RELEASE_PROCESS.md"; then
    pass "RELEASE_PROCESS.md documents $needle"
  else
    fail "RELEASE_PROCESS.md documents $needle"
  fi
done

for wf in publish.yml dry-run-publish.yml; do
  for script in check_release_branch.sh check_changelog_entry.sh; do
    if grep -q "$script" "$ROOT/.github/workflows/$wf"; then
      pass "$wf runs $script"
    else
      fail "$wf runs $script"
    fi
  done
  if grep -qF "grep -q \"^## \$VERSION\"" "$ROOT/.github/workflows/$wf"; then
    fail "$wf has no prefix-matching CHANGELOG check"
  else
    pass "$wf has no prefix-matching CHANGELOG check"
  fi
done

if grep -q 'git checkout -B' "$ROOT/.github/workflows/publish.yml"; then
  fail "publish.yml keeps the release tag checked out"
else
  pass "publish.yml keeps the release tag checked out"
fi

printf '## 3.1.0-beta.1\n\n- x\n\n## 3.0.0\n' > "$WORK/CHANGELOG.md"
expect_fail "pre-release heading does not satisfy the stable entry" "No '## 3.1.0' heading" \
  "$CHANGELOG_GUARD" 3.1.0 "$WORK/CHANGELOG.md"
expect_pass "exact pre-release heading passes" "$CHANGELOG_GUARD" 3.1.0-beta.1 "$WORK/CHANGELOG.md"
expect_pass "exact stable heading passes" "$CHANGELOG_GUARD" 3.0.0 "$WORK/CHANGELOG.md"
printf '## 3x0x0\n' > "$WORK/CHANGELOG.md"
expect_fail "dots are not wildcards" "No '## 3.0.0' heading" "$CHANGELOG_GUARD" 3.0.0 "$WORK/CHANGELOG.md"
printf '## 3.0.0 - 2026-04-29\n' > "$WORK/CHANGELOG.md"
expect_pass "heading with a trailing date passes" "$CHANGELOG_GUARD" 3.0.0 "$WORK/CHANGELOG.md"
expect_fail "missing version argument fails" "Usage" "$CHANGELOG_GUARD"

pubspec 3.0.0
expect_pass "matching stable version passes" "$GUARD" v3.0.0 "$WORK/pubspec.yaml"

pubspec 3.1.0-beta.1
expect_pass "matching pre-release version passes" "$GUARD" v3.1.0-beta.1 "$WORK/pubspec.yaml"

pubspec '"3.0.0"'
expect_pass "quoted pubspec version passes" "$GUARD" v3.0.0 "$WORK/pubspec.yaml"

pubspec 3.0.0
expect_fail "mismatch tells the operator to create a new tag" "then create a new tag" \
  "$GUARD" v3.0.1 "$WORK/pubspec.yaml"

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

git -C "$REPO" branch -q -M master
git -C "$REPO" update-ref refs/remotes/origin/master master
git -C "$REPO" checkout -q -b develop
git -C "$REPO" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m unmerged
git -C "$REPO" -c tag.gpgsign=false tag v3.3.0
expect_pass "tag reachable from origin/master passes" bash -c "cd '$REPO' && '$BRANCH_GUARD' v3.2.0 master"
expect_fail "tag not on origin/master fails" "is not on origin/master" bash -c "cd '$REPO' && '$BRANCH_GUARD' v3.3.0 master"
expect_fail "missing tag fails the branch guard" "does not exist" bash -c "cd '$REPO' && '$BRANCH_GUARD' v9.0.0 master"
expect_fail "missing branch argument fails" "Usage" "$BRANCH_GUARD" v3.2.0

exit "$FAILED"
