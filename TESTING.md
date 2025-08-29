# Testing Guide - Axeptio Flutter SDK

This document provides comprehensive guidance for testing the Axeptio Flutter SDK, including coverage requirements, test structure, and development workflows.

## 📊 Test Coverage Requirements

### Current Status
- **Current Coverage**: 58.9% (122/207 lines covered)
- **Target Coverage**: 95% (as specified in [CLAUDE.md](CLAUDE.md))
- **Total Tests**: 85 comprehensive tests
- **Status**: ⚠️ **Coverage Below Target** - requires improvement

### Coverage by Component
| Component | Coverage | Lines Covered | Status |
|-----------|----------|---------------|---------|
| `model/consents_v2.dart` | **100%** | 6/6 | ✅ Excellent |
| `preferences/native_default_preferences.dart` | **90%** | 27/30 | ✅ Good |
| `channel/axeptio.dart` | **74%** | 26/35 | ⚠️ Needs improvement |
| `channel/axeptio_sdk_method_channel.dart` | **69%** | 50/72 | ⚠️ Needs improvement |
| `events/events_handler.dart` | **34%** | 8/23 | ❌ Critical |
| `channel/axeptio_sdk_platform_interface.dart` | **13%** | 5/38 | ❌ Critical |
| `events/event_listener.dart` | **0%** | 0/3 | ❌ Critical |

## 🏗️ Test Structure

Our test suite is organized into logical components:

```
test/
├── axeptio_sdk_test.dart                    # Main SDK functionality tests
├── axeptio_sdk_method_channel_test.dart     # Method channel communication tests
├── events/
│   └── event_listener_test.dart             # Event system tests
├── model/
│   └── consents_v2_test.dart               # Data model tests
└── preferences/
    └── native_default_preferences_test.dart # Native preferences tests
```

### Test Categories

#### 1. Core SDK Tests (`axeptio_sdk_test.dart`)
- **MockAxeptioSdkPlatform**: Comprehensive mock with realistic state management
- **SDK Initialization**: Brands/Publishers service initialization
- **UI and Consent Management**: setupUI, showConsentScreen, clearConsent
- **Token Management**: Token retrieval and URL appending
- **Data Retrieval**: Consent data and debug information access
- **Event Listener Management**: Event registration and callback handling

#### 2. Method Channel Tests (`axeptio_sdk_method_channel_test.dart`)
- **Platform Communication**: Method channel message handling
- **Vendor Consent APIs**: getVendorConsents, getConsentedVendors, etc.
- **Edge Cases**: Empty strings, special characters, unknown vendors
- **Error Handling**: Platform exceptions and null responses

#### 3. Event System Tests (`test/events/event_listener_test.dart`)
- **Callback Assignment**: Event listener setup and configuration
- **Event Triggering**: onPopupClosedEvent, onConsentCleared, onGoogleConsentModeUpdate
- **Multiple Events**: Independent event handling
- **Exception Handling**: Graceful error handling in callbacks

#### 4. Model Tests (`test/model/consents_v2_test.dart`)
- **Constructor Validation**: Direct and dictionary-based construction
- **Data Conversion**: Boolean validation and type checking
- **Edge Cases**: Invalid data, missing keys, null handling
- **Real-world Usage**: Google Consent Mode v2 scenarios

#### 5. Native Preferences Tests (`test/preferences/native_default_preferences_test.dart`)
- **Predefined Keys**: Brand, TCF, and additional key sets
- **Data Retrieval**: Single and bulk preference access
- **Type Conversion**: String conversion from various data types
- **Error Handling**: Platform exceptions and data unavailability
- **Real-world Scenarios**: TCF consent data and brand preferences

## 🚀 Running Tests

### Basic Test Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/axeptio_sdk_test.dart

# Run specific test group
flutter test --name "SDK Initialization"

# Run tests in verbose mode
flutter test --reporter expanded
```

### Coverage Report Generation

```bash
# Generate coverage report
flutter test --coverage

# Coverage file location
./coverage/lcov.info

# Parse coverage summary (manual)
grep -E "^(SF|LF|LH|end_of_record)" coverage/lcov.info | awk '...'
```

### Coverage Analysis Commands

```bash
# Quick coverage check
flutter test --coverage && echo "Coverage report generated in coverage/lcov.info"

# Find uncovered files
flutter test --coverage && grep "^SF:" coverage/lcov.info | sed 's/SF://'

# Calculate overall coverage percentage
flutter test --coverage && awk '
BEGIN { total_lines = 0; hit_lines = 0 }
/^LF:/ { total_lines += substr($0, 4) }
/^LH:/ { hit_lines += substr($0, 4) }
END { 
    coverage = (total_lines > 0) ? (hit_lines * 100.0 / total_lines) : 0
    printf "Overall Coverage: %.1f%%\n", coverage
}' coverage/lcov.info
```

## 🎯 Coverage Improvement Roadmap

### Priority 1: Critical Coverage Issues (0-34%)
1. **`events/event_listener.dart` (0%)**: 
   - Add tests for default callback initialization
   - Test callback reassignment functionality
   - Validate callback execution patterns

2. **`channel/axeptio_sdk_platform_interface.dart` (13%)**:
   - Test platform interface contract
   - Add method signature validation
   - Test default implementations

3. **`events/events_handler.dart` (34%)**:
   - Test event streaming functionality
   - Add event transformation tests
   - Test error handling in event processing

### Priority 2: Improvement Areas (69-74%)
1. **`channel/axeptio_sdk_method_channel.dart` (69%)**:
   - Add more error scenarios
   - Test additional method channel paths
   - Enhanced vendor consent edge cases

2. **`channel/axeptio.dart` (74%)**:
   - Test more SDK configuration scenarios
   - Add integration test patterns
   - Enhanced error handling coverage

### Priority 3: Fine-tuning (90%+)
1. **`preferences/native_default_preferences.dart` (90%)**:
   - Cover remaining edge cases
   - Add more platform-specific scenarios

## 🧪 Testing Patterns and Best Practices

### Mock Platform Setup
```dart
class MockAxeptioSdkPlatform
    with MockPlatformInterfaceMixin
    implements AxeptioSdkPlatform {
  
  // State management
  bool _isInitialized = false;
  AxeptioService? _currentService;
  final List<AxeptioEventListener> _listeners = [];
  
  // Mock data with realistic values
  final Map<String, dynamic> _mockConsentData = {
    'axeptio_cookies': '{"analytics": true, "ads": false}',
    'IABTCF_TCString': 'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA',
    'IABTCF_gdprApplies': '1',
  };
  
  // Helper methods for testing
  void reset() {
    _isInitialized = false;
    _currentService = null;
    _listeners.clear();
  }
  
  void setMockData(Map<String, dynamic> data) {
    _mockConsentData.clear();
    _mockConsentData.addAll(data);
  }
}
```

### Test Organization Pattern
```dart
group('Component Name', () {
  late ComponentClass component;
  late MockPlatform mockPlatform;

  setUp(() {
    component = ComponentClass();
    mockPlatform = MockPlatform();
    // Setup component with mock
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
      expect(mockPlatform.wasMethodCalled, isTrue);
    });
  });
});
```

### Error Handling Testing
```dart
test('handles platform exceptions gracefully', () async {
  mockPlatform.setShouldThrowError(true);
  
  final result = await component.methodThatMightFail();
  
  expect(result, isNull); // or appropriate default
});
```

### Asynchronous Testing
```dart
test('async operations complete successfully', () async {
  final future = component.asyncMethod();
  
  await expectLater(future, completes);
  
  final result = await future;
  expect(result, isNotNull);
});
```

## 🔍 Debugging Test Failures

### Common Issues and Solutions

#### 1. Mock Platform State Issues
```bash
# Symptom: Tests fail due to incorrect mock state
# Solution: Ensure reset() is called in setUp()
setUp(() {
  mockPlatform.reset();
  // Other setup...
});
```

#### 2. Async Test Timeouts
```bash
# Symptom: Tests hang or timeout
# Solution: Use proper async/await patterns
test('async test', () async {
  await expectLater(asyncOperation(), completes);
});
```

#### 3. Platform Exception Handling
```bash
# Symptom: Unhandled platform exceptions
# Solution: Test both success and failure paths
test('handles errors gracefully', () async {
  mockPlatform.setShouldThrowError(true);
  expect(() => sdk.method(), throwsA(isA<PlatformException>()));
});
```

#### 4. Import Issues
```bash
# Symptom: Missing imports in test files
# Solution: Ensure all required imports are present
import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
```

## 📈 Coverage Monitoring

### Pre-commit Coverage Check
```bash
# Add to pre-commit hooks or CI
flutter test --coverage
coverage_percent=$(awk 'BEGIN { total = 0; hit = 0 } /^LF:/ { total += substr($0, 4) } /^LH:/ { hit += substr($0, 4) } END { printf "%.1f", (total > 0) ? (hit * 100.0 / total) : 0 }' coverage/lcov.info)

if (( $(echo "$coverage_percent < 95.0" | bc -l) )); then
  echo "❌ Coverage $coverage_percent% is below required 95%"
  exit 1
else
  echo "✅ Coverage $coverage_percent% meets requirements"
fi
```

### Coverage Tracking Workflow
1. **Before Changes**: Run `flutter test --coverage` and note current percentage
2. **During Development**: Add tests for new functionality
3. **After Changes**: Verify coverage maintained or improved
4. **Before PR**: Ensure coverage requirements are met

## 🎯 Testing Checklist for New Features

### For New Methods/Classes
- [ ] Unit tests for all public methods
- [ ] Error handling tests (exceptions, null inputs)
- [ ] Edge case testing (empty strings, special characters)
- [ ] Mock platform integration tests
- [ ] Async operation testing (if applicable)
- [ ] State management testing (if applicable)

### For Bug Fixes  
- [ ] Regression test that reproduces the original bug
- [ ] Test that verifies the fix works
- [ ] Edge cases related to the bug scenario
- [ ] Error handling around the bug area

### For Platform Integration
- [ ] Mock platform method channel tests
- [ ] Platform-specific error handling
- [ ] Data serialization/deserialization tests
- [ ] Cross-platform compatibility tests

## 🚦 CI/CD Integration

### GitHub Actions Testing
The repository should include automated testing in CI/CD:

```yaml
# .github/workflows/test.yml (example)
name: Test and Coverage
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.3.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests with coverage
        run: flutter test --coverage
      
      - name: Check coverage threshold
        run: |
          # Script to check coverage meets 95% requirement
          # Fail CI if coverage is below threshold
```

## 📚 Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Dart Test Package](https://pub.dev/packages/test)
- [Plugin Platform Interface Testing](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#step-2-implement-the-package)
- [Mock Platform Interface Patterns](https://pub.dev/packages/plugin_platform_interface)

## 🤝 Contributing to Tests

When contributing to the test suite:

1. **Follow Existing Patterns**: Use the established mock platform and test structure
2. **Comprehensive Coverage**: Aim for 95%+ coverage in any new components
3. **Real-world Scenarios**: Include realistic usage patterns in tests
4. **Error Handling**: Always test both success and failure paths
5. **Documentation**: Update this guide when adding new testing patterns

---

**Next Steps**: Review [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow and [README.md](README.md) for usage documentation.