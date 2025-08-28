# Contributing to Axeptio Flutter SDK

Thank you for your interest in contributing to the Axeptio Flutter SDK! This document outlines the development workflow and guidelines for contributors.

## Development Setup

### Prerequisites

- Flutter SDK 3.3.0 or later
- Dart SDK 3.3.1 or later
- Python 3.x (for pre-commit hooks)
- Node.js 18+ (for semantic release)

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

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/specific_test.dart
```

### Writing Tests

- Write unit tests for new functionality
- Follow existing test patterns
- Aim for meaningful test coverage
- Mock external dependencies

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

Releases are managed through semantic versioning with GitHub Actions:

1. **Automatic Versioning**: Based on conventional commits
2. **Manual Trigger**: Use workflow dispatch for controlled releases
3. **Changelog**: Generated automatically from commit messages

### Version Bumping

- `feat`: Minor version bump
- `fix`: Patch version bump
- `BREAKING CHANGE`: Major version bump

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

