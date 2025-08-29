# Release Process

This document describes the improved release process for the Axeptio Flutter SDK.

## Overview

The release process is now **tag-driven** and ensures proper synchronization between GitHub releases and pub.dev publishing.

## Key Improvements

✅ **GitHub Release Tag = Source of Truth**  
✅ **Dynamic pubspec.yaml Update**  
✅ **pub.dev Version Conflict Prevention**  
✅ **Automated Validation**  

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

### 3. Automatic Publishing
The workflow will automatically:
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

**Before:** Manual pubspec.yaml updates, version mismatches possible  
**After:** Tag-driven, automatically synchronized, validated

**Previous issues resolved:**
- ❌ Publishing version 2.0.15 when expecting 2.0.10
- ❌ pubspec.yaml and pub.dev version mismatches
- ❌ Manual version management errors

## Beta Releases (Future)

Beta releases will be handled separately through a dedicated workflow targeting the `develop` branch.