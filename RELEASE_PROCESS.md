# Release Process

This document describes the improved release process for the Axeptio Flutter SDK.

## Overview

The release process is now **manual and controlled** with proper validation gates between release creation and publishing to pub.dev.

## Key Improvements

✅ **Manual Control** - No accidental publishing  
✅ **Validation Gates** - Test before publish  
✅ **GitHub Release Tag = Source of Truth**  
✅ **Consistent Logic** - Both workflows use same version extraction  
✅ **pub.dev Version Conflict Prevention**  

## Release Steps

### 1. Prepare Release
```bash
# Ensure master branch is ready
git checkout master
git pull origin master

# Verify tests pass locally
flutter test
flutter analyze
```

### 2. Create GitHub Release
1. Go to [GitHub Releases](https://github.com/axeptio/flutter-sdk/releases)
2. Click "Create a new release"
3. Set tag version: `v2.0.16` (following semver)
4. Set release title: `v2.0.16`
5. Add release notes describing changes
6. **Important**: Mark as draft or pre-release initially
7. Click "Publish release"

### 3. Validate with Dry-Run (Required)
Run the dry-run workflow to validate everything works:

```bash
# Option 1: Validate specific release tag
gh workflow run dry-run-publish.yml --field release_tag=v2.0.16

# Option 2: Validate latest release (auto-detects)
gh workflow run dry-run-publish.yml
```

**What the dry-run validates:**
- ✅ Release exists and is accessible
- ✅ Version format is valid
- ✅ Version doesn't already exist on pub.dev
- ✅ pubspec.yaml updates correctly from tag
- ✅ Flutter tests and analysis pass
- ✅ Package structure is valid for publishing

### 4. Publish to pub.dev (Manual)
Only after dry-run validation passes:

```bash
# Manually trigger the publish workflow
gh workflow run publish.yml --field release_tag=v2.0.16
```

**What the publish workflow does:**
- ✅ Same validation as dry-run
- ✅ Actually publishes to pub.dev
- ✅ Provides detailed success summary

## Version Format

- **Stable releases**: `v2.0.16`, `v2.1.0`, `v3.0.0`
- **Pre-releases**: `v2.1.0-beta.1`, `v2.1.0-rc.1`

### 5. Finalize Release
After successful publishing:

1. **Update release status** (if created as draft/pre-release)
   - Edit the GitHub release
   - Remove draft or pre-release flags
   - Make it the "Latest release"

2. **Verify publication**
   - Check [pub.dev/packages/axeptio_sdk](https://pub.dev/packages/axeptio_sdk)
   - Confirm new version is available

3. **Announce release**
   - Notify development teams
   - Update any integration guides if needed

## Validation & Safety

Both workflows validate:
- ✅ Release exists and is accessible
- ✅ Version format (semantic versioning)
- ✅ Version doesn't already exist on pub.dev
- ✅ pubspec.yaml updates correctly from tag
- ✅ Flutter analysis passes
- ✅ All tests pass
- ✅ Package structure is valid

## Error Handling

**If release doesn't exist:**
- ❌ Workflow fails immediately
- 🔄 Create the release first

**If version already exists on pub.dev:**
- ❌ Workflow fails with clear error
- 🔄 Create new release with incremented version

**If dry-run fails:**
- ❌ Don't run publish workflow
- 🔧 Fix issues and re-run dry-run

**If tests fail:**
- ❌ Publishing is blocked
- 🔧 Fix issues in code and create new release

## Workflow Commands Reference

```bash
# List recent releases
gh release list --limit 5

# View specific release  
gh release view v2.0.16

# Run dry-run validation
gh workflow run dry-run-publish.yml --field release_tag=v2.0.16

# Run actual publish (only after dry-run passes)
gh workflow run publish.yml --field release_tag=v2.0.16

# Check workflow status
gh workflow list
gh run list --workflow=publish.yml
```

## Migration Benefits

**Previous issues resolved:**
- ❌ Accidental publishing (now requires manual trigger)
- ❌ Publishing version 2.0.15 when expecting 2.0.10 (validation prevents this)  
- ❌ pubspec.yaml and pub.dev version mismatches (consistent tag-driven logic)
- ❌ No validation before publishing (dry-run required)

**New process advantages:**
- ✅ Manual control with validation gates
- ✅ Consistent logic between dry-run and publish
- ✅ Clear error messages and guidance
- ✅ Safe to test releases before publishing