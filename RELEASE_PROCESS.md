# Release Process

The Axeptio Flutter SDK has one release path:

```text
develop → master PR → GitHub Release (tag vX.Y.Z) → publish.yml → pub.dev
```

`publish.yml` runs on `release: published`. It never edits files: the version in
`pubspec.yaml` and the `CHANGELOG.md` entry must already be on `master` at the tag.

## 1. Prepare the release on `develop`

1. Bump `version:` in `pubspec.yaml` to the release version, e.g. `3.1.0`.
2. Add a `## 3.1.0` heading with release notes at the top of `CHANGELOG.md`.
3. Merge through a normal PR into `develop`.

## 2. Promote `develop` → `master`

Open a PR from `develop` to `master`. Merge it once CI is green and approved.

## 3. Create the GitHub Release

1. Go to [GitHub Releases](https://github.com/axeptio/flutter-sdk/releases) → "Draft a new release".
2. Tag: `v3.1.0`, target `master`. The tag must match `pubspec.yaml` exactly.
3. Title `v3.1.0`, add release notes, click "Publish release".

Publishing the release triggers `publish.yml`, which:

- checks out the tag;
- fails if `pubspec.yaml` at the tag differs from the tag version;
- fails if the tagged commit is not on `master`;
- fails if the version already exists on pub.dev;
- fails if `CHANGELOG.md` has no `## 3.1.0` heading;
- runs `flutter analyze`, `flutter test` and `dart pub publish --dry-run`;
- publishes to pub.dev.

`publish.yml` also accepts `workflow_dispatch` with a `release_tag` input. Use it only to
retry an existing tag after a transient failure, such as a pub.dev outage.

## Pre-releases

Pre-release versions follow the same path with a suffixed version:

- `pubspec.yaml`: `version: 3.1.0-beta.1`, `CHANGELOG.md`: `## 3.1.0-beta.1`.
- Tag `v3.1.0-beta.1` and tick "Set as a pre-release" on the GitHub Release.

pub.dev serves pre-releases only to apps that request them, e.g. `axeptio_sdk: 3.1.0-beta.1`.

## Dry run

Run `dry-run-publish.yml` from [GitHub Actions](https://github.com/axeptio/flutter-sdk/actions)
with a `release_tag` before publishing. It runs the same version, `master`, pub.dev and
`CHANGELOG.md` checks, analysis, tests and a pub.dev dry-run, without publishing.

- If the tag exists, it checks out the tag and validates that snapshot.
- If the tag does not exist yet, it validates the selected branch.

## When publish fails

| Failure                                       | Fix                                                                   |
| --------------------------------------------- | --------------------------------------------------------------------- |
| `pubspec.yaml version X does not match tag Y` | Bump `pubspec.yaml` via `develop` → `master`, then release a new tag  |
| Release tag is not on `origin/master`         | Merge `develop` → `master`, then release a new tag targeting `master` |
| Version already exists on pub.dev             | Release a new, higher version                                         |
| No `## X.Y.Z` heading in `CHANGELOG.md`       | Add the entry via `develop` → `master`, then release a new tag        |
| Analysis or tests fail                        | Fix on `develop`, promote to `master`, release a new tag              |
