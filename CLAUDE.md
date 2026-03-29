# CLAUDE.md - Axeptio Flutter SDK Development Guidelines

<!-- IMPORTANT_RULES_START -->

## Important Rules
- ALL instructions within this document MUST BE FOLLOWED, these are not optional unless explicitly stated.
- DO NOT edit more code than you have to.
- DO NOT WASTE TOKENS, be succinct and concise.
- ASK FOR CLARIFICATION if you are uncertain of anything within the document.
- DO NOT modify other repositories
- ALWAYS use gh command for github operations
- Test coverage MUST ALWAYS BE 95%
- ALL tests MUST ALWAYS pass
- DO NOT DO quick fixes
- DO NOT bypass tests
- ALWAYS check test coverage before committing
- ALWAYS add tests for new functionality
- Go fix failing CI tests without being told how
- **Simplicity firt**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.

# Plan Mode
- ALWAYS enter plan mode for ANY non-trivial task (+3 steps or architectural decision)
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity
- ALWAYS check the context window is appropriate for the execution
- ALWAYS plan to use beads for execution orchestration

# Self Improvement
- After ANY correction from the user: update the `tasks/lessons.md`with the patterns
- Offload research, exploration and parallel analysis to subagents
- One task per subagent for focused execution

## SDK Version Management
- ALWAYS ensure that the README.md is up to date as it's documentation for app developper to integrate the SDK
- ALWAYS ensure the example/ app is UP TO DATE in accordance with latest changes

## Testing Requirements and Workflow
- NEVER mark a task complete without proving it works
- Ask yourself: "would a staff engineer approve this?"
- ALWAYS run tests, check logs, demonstrate correctness

### Critical Testing Standards
- **Coverage Requirement**: 95% minimum test coverage (current: 58.9% - needs improvement)
- **Test Status**: All 85+ tests must pass before any commit
- **New Code**: All new functionality must include comprehensive tests
- **Coverage Verification**: Always run `flutter test --coverage` before committing

### Testing Commands for Development
```bash
# Check current test status
flutter test

# Generate coverage report
flutter test --coverage

# Verify coverage percentage
flutter test --coverage && awk 'BEGIN { total = 0; hit = 0 } /^LF:/ { total += substr($0, 4) } /^LH:/ { hit += substr($0, 4) } END { printf "Coverage: %.1f%%\n", (total > 0) ? (hit * 100.0 / total) : 0 }' coverage/lcov.info
```

### Testing Workflow for Future Development
1. **Before Starting**: Check current coverage with `flutter test --coverage`
2. **During Development**: Add tests alongside code changes
3. **Before Committing**: Verify coverage meets or exceeds 95%
4. **If Coverage Below 95%**: Focus on priority areas listed in TESTING.md

### Coverage Improvement Priority (to reach 95%)
1. **Critical (0-34%)**: `events/event_listener.dart`, `channel/axeptio_sdk_platform_interface.dart`, `events/events_handler.dart`
2. **Important (69-74%)**: `channel/axeptio_sdk_method_channel.dart`, `channel/axeptio.dart`

### Testing Documentation Reference
- **Comprehensive Guide**: [TESTING.md](TESTING.md) - Complete testing documentation
- **Quick Reference**: [CONTRIBUTING.md](CONTRIBUTING.md) - Testing requirements for contributors
- **User Info**: [README.md](README.md) - Testing section for developers using the SDK

## Development Workflow

### Pre-commit Hooks
This repository uses pre-commit hooks to ensure code quality. Install them with:
```bash
pip install pre-commit
pre-commit install
```

The hooks will automatically:
- Run `flutter analyze` for Dart analysis
- Run `dart format --set-exit-if-changed` for code formatting
- Validate conventional commit messages

### Conventional Commits
All commits MUST follow the conventional commit format:
```
type(scope): description

[optional body]

[optional footer(s)]
```

**Types**: feat, fix, docs, style, refactor, test, chore, ci, build, perf
**Scopes**: android, ios, core, example, docs, ci

Examples:
- `feat(core): add native preferences access for consent data`
- `fix(android): resolve gradle build configuration issue`
- `docs(readme): update installation instructions`

### Release Process

#### Stable Releases
1. Releases are managed through semantic versioning from `master` branch
2. Version bumps are automated based on conventional commits
3. Use GitHub workflow dispatch to trigger releases manually
4. Never manually edit version numbers - use the semver workflow

#### Beta Releases
1. Beta releases are created from `develop` branch for next version testing
2. Use "Beta Release" workflow to create beta versions (e.g., 2.1.0-beta.1)
3. Betas are published to pub.dev as pre-release versions for customer testing
4. Multiple beta increments can be released before stable version

### Code Quality
- Run `flutter analyze` before committing
- Run `flutter test` to ensure all tests pass
- Follow Flutter/Dart linting rules defined in analysis_options.yaml
- Use `dart format` for consistent code formatting

### File Creation Guidelines
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

<!-- IMPORTANT_RULES_END -->
