# Contributing to Axeptio Flutter SDK

Thank you for your interest in contributing to the Axeptio Flutter SDK! This document outlines the development workflow and guidelines for contributors.

## Development Setup

### Prerequisites

- Flutter SDK 3.3.0 or later
- Dart SDK 3.3.1 or later
- Python 3.x (for pre-commit hooks)

### Initial Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/flutter-sdk.git
   cd flutter-sdk
   ```

2. **Install pre-commit hooks**
   ```bash
   pip install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Set up commit message template** (optional)
   ```bash
   git config commit.template .gitmessage
   ```

## Development Workflow

### Branch Strategy

- `master` - Main production branch
- Feature branches: `feat/feature-name`
- Bugfix branches: `fix/issue-description`
- Documentation: `docs/topic`

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes**
   - Follow Dart/Flutter coding conventions
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   flutter analyze
   flutter test
   dart format .
   ```

4. **Commit with conventional format**
   ```bash
   git add .
   git commit -m "feat(core): add new feature description"
   ```

## Commit Message Format

We use [Conventional Commits](https://conventionalcommits.org/) for consistent commit messages and automated versioning.

### Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting changes (no code logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD configuration changes
- `build`: Build system or dependency changes
- `perf`: Performance improvements

### Scopes
- `android`: Android-specific changes
- `ios`: iOS-specific changes
- `core`: Core Flutter/Dart code
- `example`: Example app changes
- `docs`: Documentation changes
- `ci`: CI/CD changes

### Examples
```
feat(core): add native preferences access for consent data
fix(android): resolve gradle build configuration issue
docs(readme): update installation instructions
ci(workflow): add GitHub Actions linting validation
```

## Code Quality Standards

### Pre-commit Hooks

The following checks run automatically on each commit:

- **Flutter Analyze**: Checks for code issues
- **Flutter Format**: Ensures consistent formatting
- **Flutter Test**: Runs all unit tests
- **Conventional Commit**: Validates commit message format

### Manual Quality Checks

Before submitting a PR, ensure:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests with coverage
flutter test --coverage

# Validate package
dart pub publish --dry-run
```

## Testing

### Testing Requirements

**Critical**: This project requires **95% test coverage** as specified in [CLAUDE.md](CLAUDE.md).

- **Current Coverage**: 58.9% (needs improvement to reach 95% target)
- **All Tests Must Pass**: PRs with failing tests will not be accepted
- **New Features**: Must include comprehensive tests with mock platform integration
- **Bug Fixes**: Must include regression tests

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/specific_test.dart

# Run specific test group
flutter test --name "SDK Initialization"

# Verbose test output
flutter test --reporter expanded
```

### Coverage Requirements for PRs

Before submitting a PR, ensure:

```bash
# 1. All tests pass
flutter test

# 2. Coverage meets requirements
flutter test --coverage
# Check that overall coverage is maintained or improved

# 3. No analysis issues
flutter analyze

# 4. Code is properly formatted
dart format .
```

### Writing Tests

**Follow Established Patterns**: 
- Use `MockAxeptioSdkPlatform` for platform integration tests
- Organize tests by component (core, events, models, preferences)
- Follow the test structure documented in [TESTING.md](TESTING.md)

**Required Test Categories**:
- Unit tests for all public methods
- Error handling tests (exceptions, null inputs)
- Edge case testing (empty strings, special characters)
- Mock platform integration tests
- Async operation testing (if applicable)
- State management testing (if applicable)

**Test Organization Pattern**:
```dart
group('Component Name', () {
  late ComponentClass component;
  late MockPlatform mockPlatform;

  setUp(() {
    component = ComponentClass();
    mockPlatform = MockPlatform();
    mockPlatform.reset();
  });

  group('Feature Category', () {
    test('specific behavior description', () async {
      // Arrange
      mockPlatform.setExpectedData(data);
      
      // Act
      final result = await component.method();
      
      // Assert
      expect(result, expectedValue);
    });
  });
});
```

### Coverage Improvement Guidelines

**Priority Areas** (for reaching 95% coverage):
1. **Critical (0-34% coverage)**: `events/event_listener.dart`, `channel/axeptio_sdk_platform_interface.dart`, `events/events_handler.dart`
2. **Improvement (69-74% coverage)**: `channel/axeptio_sdk_method_channel.dart`, `channel/axeptio.dart`
3. **Fine-tuning (90%+ coverage)**: `preferences/native_default_preferences.dart`

**Testing Strategy**:
- Add tests for uncovered lines identified in coverage reports
- Focus on error handling and edge cases
- Include platform-specific testing scenarios
- Test both success and failure code paths

For comprehensive testing guidance, patterns, and coverage strategies, see [TESTING.md](TESTING.md).

## Documentation

### Code Documentation

- Use dartdoc comments for public APIs
- Include examples in documentation
- Keep comments up to date with code changes

### README Updates

- Update README.md for public API changes
- Include usage examples
- Maintain compatibility information

## Pull Request Process

1. **Create a Pull Request**
   - Use a descriptive title
   - Reference related issues
   - Include a detailed description

2. **PR Requirements**
   - All CI checks must pass
   - Code review approval required
   - No merge conflicts
   - Tests must pass

3. **After Review**
   - Address review feedback
   - Update documentation if needed
   - Ensure CI passes

## Release Process

Releases follow one path: `develop` → `master` PR → GitHub Release → `publish.yml` → pub.dev.
See [RELEASE_PROCESS.md](RELEASE_PROCESS.md) for the full steps.

- The version bump is manual: set `version:` in `pubspec.yaml` and add a `## X.Y.Z` entry to `CHANGELOG.md` on `develop`.
- Publishing a GitHub Release tagged `vX.Y.Z` on `master` triggers `publish.yml`, which fails if `pubspec.yaml` does not match the tag.
- Pre-releases (e.g. `3.1.0-beta.1`) use the same path with a suffixed version and the GitHub "pre-release" flag.
- `dry-run-publish.yml` validates a release tag without publishing.

**Choosing the version** (guidance, not automation):
- `fix`: patch (3.0.0 → 3.0.1)
- `feat`: minor (3.0.0 → 3.1.0)
- `BREAKING CHANGE`: major (3.0.0 → 4.0.0)

## SDK Version Management

When updating native SDK dependencies:

### Android
Update `android/build.gradle`:
```gradle
dependencies {
    implementation("io.axept.android:android-sdk:x.x.x")
}
```

### iOS
Update `ios/axeptio_sdk.podspec`:
```ruby
s.dependency "AxeptioIOSSDK", "x.x.x"
```

## Getting Help

- Check existing issues and documentation
- Ask questions in pull request discussions
- Follow the existing code patterns and conventions

