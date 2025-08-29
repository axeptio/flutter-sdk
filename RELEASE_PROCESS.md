# Release Process

This document describes the improved release process for the Axeptio Flutter SDK.

## Overview

The release process is now **tag-driven** and ensures proper synchronization between GitHub releases and pub.dev publishing.

## Key Improvements

✅ **GitHub Release Tag = Source of Truth**  
✅ **Manual Workflow Control**  
✅ **Dynamic pubspec.yaml Update**  
✅ **pub.dev Version Conflict Prevention**  
✅ **Pre-publish Validation**  

## Release Steps

### 1. Prepare Release
```bash
# Ensure master branch is ready
git checkout master
git pull origin master

# Verify tests pass
flutter test
flutter analyze
```

### 2. Create GitHub Release
1. Go to [GitHub Releases](https://github.com/axeptio/flutter-sdk/releases)
2. Click "Create a new release"
3. Set tag version: `v2.0.16` (following semver)
4. Set release title: `v2.0.16`
5. Add release notes describing changes
6. Click "Publish release"

### 3. Validate Release (Optional)
Before publishing, validate the release:
1. Go to [GitHub Actions](https://github.com/axeptio/flutter-sdk/actions)
2. Select "Dry-run Publish to pub.dev" workflow
3. Click "Run workflow"
4. Enter the release tag: `v2.0.16`
5. Review validation results

### 4. Manual Publishing
Publish to pub.dev manually:
1. Go to [GitHub Actions](https://github.com/axeptio/flutter-sdk/actions)
2. Select "Publish to pub.dev" workflow
3. Click "Run workflow"
4. Enter the release tag: `v2.0.16`
5. The workflow will:
   - ✅ Extract version from tag (`v2.0.16` → `2.0.16`)
   - ✅ Validate version format
   - ✅ Check if version already exists on pub.dev
   - ✅ Update `pubspec.yaml` with tag version
   - ✅ Run tests and analysis
   - ✅ Publish to pub.dev
   - ✅ Provide summary in workflow output

## Version Format

- **Stable releases**: `v2.0.16`, `v2.1.0`, `v3.0.0`
- **Pre-releases**: `v2.1.0-beta.1`, `v2.1.0-rc.1`

## Validation

The workflow validates:
- ✅ Version format (semantic versioning)
- ✅ Version doesn't exist on pub.dev
- ✅ Flutter analysis passes
- ✅ All tests pass
- ✅ pub publish dry-run succeeds

## Error Handling

**If version already exists on pub.dev:**
- ❌ Workflow fails with clear error
- 🔄 Create new release with incremented version

**If tests fail:**
- ❌ Publishing is blocked
- 🔧 Fix issues and create new release

## Migration from Old Process

**Before:** Manual pubspec.yaml updates, automatic publishing, version mismatches possible  
**After:** Tag-driven, manual workflow control, pre-publish validation, synchronized

**Previous issues resolved:**
- ❌ Publishing version 2.0.15 when expecting 2.0.10
- ❌ pubspec.yaml and pub.dev version mismatches
- ❌ Automatic publishing without validation
- ❌ Manual version management errors

## Beta Releases (Future)

Beta releases will be handled separately through a dedicated workflow targeting the `develop` branch.