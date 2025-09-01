# [3.0.0](https://github.com/axeptio/flutter-sdk/compare/2.0.17...3.0.0) (2025-09-01)


### Bug Fixes

* add native vendor API method channel handlers for iOS and Android ([4c4f84b](https://github.com/axeptio/flutter-sdk/commit/4c4f84b6de869416421b1c408fd72167ace445d3))
* address all critical Cubic AI review issues ([2ee959c](https://github.com/axeptio/flutter-sdk/commit/2ee959c1294405e360662b0fee0cf705edf92984))
* address critical Cubic AI review issues ([9182cb9](https://github.com/axeptio/flutter-sdk/commit/9182cb94778d6487da450f64843580ee32f44e7e))
* align dry-run workflow with new version management approach ([9e67385](https://github.com/axeptio/flutter-sdk/commit/9e67385de953d637faa5886dcea44a78c669257c))
* **ci:** add missing @semantic-release/exec dependency ([f15b2b5](https://github.com/axeptio/flutter-sdk/commit/f15b2b5476608068ed2a0b3a600637bb2ae78932))
* **ci:** configure TriPSs action for Flutter without v prefix and restore changelog ([93e9574](https://github.com/axeptio/flutter-sdk/commit/93e95748c81598781507270caf29643f87f9f6d9))
* **ci:** correct actionlint module path and execution ([b5814a5](https://github.com/axeptio/flutter-sdk/commit/b5814a5ee70397b61c81e9d675a018eff1fc73ca))
* **ci:** correct Codecov action parameter from 'file' to 'files' ([9f5b4b7](https://github.com/axeptio/flutter-sdk/commit/9f5b4b7f154b97099c95f2187560ec7dedea6e6f))
* **ci:** ensure proper branch tracking for TriPSs/conventional-changelog-action ([e5f7122](https://github.com/axeptio/flutter-sdk/commit/e5f7122437bfcc6ddeb82557c7aa47550471c913))
* **ci:** handle non-existent release tags in dry-run workflow ([39deb54](https://github.com/axeptio/flutter-sdk/commit/39deb543188d74407b4160b25cf951eaf39b1c31))
* **ci:** quote gpg program path to resolve shellcheck warning ([c0c97e7](https://github.com/axeptio/flutter-sdk/commit/c0c97e7721b74e6378aeaa485d693357b545dacc))
* **ci:** remove actionlint workflows and pre-commit hooks ([942f47f](https://github.com/axeptio/flutter-sdk/commit/942f47f1ed3b08f78c9ce2ab207922b6645ff799))
* **ci:** remove fallback-version and restore original CHANGELOG.md format ([78b5ac9](https://github.com/axeptio/flutter-sdk/commit/78b5ac9c9a1b4ac3bfc161a7f2c90fbe35112bb6))
* **ci:** resolve actionlint action and code formatting issues ([84bc241](https://github.com/axeptio/flutter-sdk/commit/84bc241306b37d7abcfd968a596759b9ca6d839a))
* **ci:** resolve TriPSs/conventional-changelog-action detached HEAD error ([add11b6](https://github.com/axeptio/flutter-sdk/commit/add11b6fd5f151c046f233ceaeb0fba01a799ef2))
* **ci:** use direct GitHub release download for actionlint installation ([8964342](https://github.com/axeptio/flutter-sdk/commit/89643422dfcbaaf8322daf70a28b0314b58c9aa8))
* **ci:** use fallback-version parameter for TriPSs/conventional-changelog-action ([a31d77e](https://github.com/axeptio/flutter-sdk/commit/a31d77e62b34315ad702a26b7ff75224bcd48074))
* **ci:** use go install for actionlint setup ([9a63559](https://github.com/axeptio/flutter-sdk/commit/9a635591608624b595fe2f3798b17c0f1cea5ea9))
* **ci:** use TriPSs/conventional-changelog-action@v6 with explicit version ([b52c33c](https://github.com/axeptio/flutter-sdk/commit/b52c33c5ad4a9ac74a20592538aa20ce58cd29e0))
* **docs:** align Flutter version and license in README badges ([0a5d31e](https://github.com/axeptio/flutter-sdk/commit/0a5d31e369be973dde19bc285d69d5676fe46c4e))
* **docs:** remove license section from CONTRIBUTING.md ([569d7f5](https://github.com/axeptio/flutter-sdk/commit/569d7f5c78285aa142b344b9fb61a301bcf05efd))
* enhance dry-run step with version logging ([12b529c](https://github.com/axeptio/flutter-sdk/commit/12b529cefe5b8ea51ca45efff05a9eeb552189a6))
* **example:** enhance Clear Consent with immediate refresh and visual feedback ([0506d1d](https://github.com/axeptio/flutter-sdk/commit/0506d1d0e093585accb1cb3f26bc126d0f4196b3))
* handle iOS NSDate serialization crash in getConsentSavedData (MSK-81) ([4a3e307](https://github.com/axeptio/flutter-sdk/commit/4a3e307080f390b9dd28d9aba0256cc6ea567b9c))
* implement tag-driven version publishing workflow ([f360989](https://github.com/axeptio/flutter-sdk/commit/f36098945f98638d8e12c3e63f4b8ede692dac2b))
* resolve actionlint shellcheck issues in workflows ([c92826b](https://github.com/axeptio/flutter-sdk/commit/c92826bbeb4584637718ffcb6d5816cab71ea95b))
* resolve Dart analyzer issues in getVendorConsents ([94ef074](https://github.com/axeptio/flutter-sdk/commit/94ef0746863e2a575ed020cdd2fabf7dcb8957ae))
* resolve flutter analyzer errors ([4cc75ec](https://github.com/axeptio/flutter-sdk/commit/4cc75ecb76f59104e02d113ffeed94656ee4a617))
* resolve iOS bridge type casting error for [Int: Bool] dictionaries ([71827f0](https://github.com/axeptio/flutter-sdk/commit/71827f0d937c095fe86ed768d53c291ad61edea2))
* sanitize native Android responses to prevent Flutter codec crashes ([ec1420c](https://github.com/axeptio/flutter-sdk/commit/ec1420cc4f24c8a1cbb18c6e9dcd88e4262cc49a))
* sanitize native iOS responses to prevent Flutter codec crashes ([749e0ac](https://github.com/axeptio/flutter-sdk/commit/749e0accf6780b1df937cbfd3590d57b60bc6940))
* **test:** address cubic AI review feedback on test quality ([8eab099](https://github.com/axeptio/flutter-sdk/commit/8eab0991277a70afc17afd081209b54053df6b07)), closes [#79](https://github.com/axeptio/flutter-sdk/issues/79)
* unit tests ([f5e57cf](https://github.com/axeptio/flutter-sdk/commit/f5e57cf92eaa2f4b05b187138326e429ae84b3ac))


### Features

* add comprehensive TCF vendor consent management APIs ([97fdaf5](https://github.com/axeptio/flutter-sdk/commit/97fdaf52b9df2bc06fe6cb8cef69dff41de4930b))
* add consent debug vendors info ([d5974fd](https://github.com/axeptio/flutter-sdk/commit/d5974fd91d1e7c608b3a7177a1cc212d955e606e))
* add NativeDefaultPreferences for cross-platform consent access (MSK-76) ([bf79bb4](https://github.com/axeptio/flutter-sdk/commit/bf79bb42189ef5ba3c34a262a8b986405a2e5699))
* **ci:** add beta release workflow for next version testing ([0ed76f3](https://github.com/axeptio/flutter-sdk/commit/0ed76f33969b8046a3229a488c960a555cbfa085))
* **ci:** add changelog validation to both publishing workflows ([d0482ae](https://github.com/axeptio/flutter-sdk/commit/d0482ae0b3c72495f509f3fa8c7bbb72dc81877c))
* **ci:** enhance publish workflow to support beta releases via dispatch ([8782cc7](https://github.com/axeptio/flutter-sdk/commit/8782cc7c17d6accad4a0b6fbd2604eecf6df005d))
* **ci:** implement automated changelog generation for publishing workflows ([5155878](https://github.com/axeptio/flutter-sdk/commit/51558783c471d4a69c65b00e95efbc9fe23a304e))
* **ci:** implement comprehensive development workflow improvements ([5522a5f](https://github.com/axeptio/flutter-sdk/commit/5522a5fa0ad1de816aa6c3f5e9d2449451539521))
* **ci:** implement manual workflow dispatch for publishing ([256d8f4](https://github.com/axeptio/flutter-sdk/commit/256d8f4525b2f851be8717e7643047a7c00fd224))
* **dev:** pin Node.js version to 22 with .nvmrc ([9df17cb](https://github.com/axeptio/flutter-sdk/commit/9df17cbb20360a44094bcf2f122810b8ad841fb9))
* **example:** add close button to preferences dialog title ([cc9ba71](https://github.com/axeptio/flutter-sdk/commit/cc9ba713ca564a5d1cdeb88afb0ca16b8a49505b))
* **example:** implement comprehensive TCF vendor management UI ([443f539](https://github.com/axeptio/flutter-sdk/commit/443f539e7325376289958ae8b11b0c5aa7a2d279))
* implement consent debug info with proper scrolling functionality ([0895da3](https://github.com/axeptio/flutter-sdk/commit/0895da3b74a37da20120f4f6f4521757a9e5ad4d))
* **test:** add comprehensive test coverage for SDK components ([e0e56d9](https://github.com/axeptio/flutter-sdk/commit/e0e56d915ac947dc2e2fc394cf091f058fc9aec8))
* update iOS SDK to version 2.0.15 ([9eaf350](https://github.com/axeptio/flutter-sdk/commit/9eaf3502fc3ae241c2dda42ccc946ee2ae687161))
* update native SDKs - iOS 2.0.15 and Android 2.0.8 ([59893df](https://github.com/axeptio/flutter-sdk/commit/59893df3f7cc76d46243adf29f37ede50f5c4595))


### BREAKING CHANGES

* **ci:** Publishing workflows no longer require manual CHANGELOG.md updates



