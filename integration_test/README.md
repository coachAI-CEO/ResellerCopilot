# Integration Tests

This directory contains integration tests that verify the complete application workflow.

## Structure

```
integration_test/
├── app_test.dart  # Main integration test suite
└── README.md      # This file
```

## What are Integration Tests?

Integration tests verify that different parts of the app work together correctly. Unlike unit tests which test individual components in isolation, integration tests:

- Test complete user workflows (e.g., login → scan → view results)
- Verify navigation between screens
- Test data persistence
- Verify authentication flows
- Test error handling across multiple components

## Running Integration Tests

### Prerequisites

For integration tests to work properly, you need:
1. A test Supabase instance (or mocked backend)
2. Test user credentials
3. Configured environment variables

### Run on Flutter devices

```bash
# Run on all connected devices
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d <device_id>

# Run with specific flavor
flutter test integration_test/ --flavor staging
```

### Run on iOS Simulator

```bash
flutter test integration_test/ -d iPhone
```

### Run on Android Emulator

```bash
flutter test integration_test/ -d emulator-5554
```

### Run on Chrome (Web)

```bash
flutter test integration_test/ -d chrome
```

## Test Scenarios

### Current Test Coverage

1. **Authentication Flow**
   - User signup
   - User login
   - Session persistence
   - Logout

2. **Scan Workflow**
   - Photo selection
   - Price input
   - Product analysis
   - Result display
   - Scan persistence

3. **Error Handling**
   - Network failures
   - Invalid inputs
   - Session expiration
   - Edge function errors

4. **Offline Scenarios**
   - Cached authentication
   - Offline error messages

## Test Configuration

### Environment Setup

Create a `.env.test` file for integration test configuration:

```env
SUPABASE_URL=https://your-test-project.supabase.co
SUPABASE_ANON_KEY=your-test-anon-key
TEST_USER_EMAIL=test@example.com
TEST_USER_PASSWORD=testpassword123
```

### Test Data

Integration tests may require test data:

- Test product images (stored in `integration_test/fixtures/`)
- Mock API responses
- Test user accounts

## Writing Integration Tests

### Basic Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Integration Tests', () {
    testWidgets('should complete user workflow', (WidgetTester tester) async {
      // 1. Setup
      await IntegrationTestHelper.setupTestEnvironment();

      // 2. Execute workflow
      await IntegrationTestHelper.loginTestUser(tester);
      await IntegrationTestHelper.performScan(
        tester: tester,
        price: '29.99',
        condition: 'New',
      );

      // 3. Verify results
      IntegrationTestHelper.verifyAnalysisResults(
        tester: tester,
        verdict: 'BUY',
      );
    });
  });
}
```

### Best Practices

1. **Use Helper Methods:** Extract common workflows into helper methods
2. **Clean Up:** Reset test data after each test
3. **Be Patient:** Use `pumpAndSettle()` to wait for async operations
4. **Test Real Scenarios:** Simulate actual user behavior
5. **Handle Timeouts:** Set appropriate timeouts for network operations

## CI/CD Integration

Integration tests can be run in CI/CD pipelines:

```yaml
# .github/workflows/integration-test.yml
- name: Run Integration Tests
  run: |
    flutter test integration_test/ \
      -d chrome \
      --dart-define=ENV=test
```

## Debugging Integration Tests

### Enable Verbose Logging

```bash
flutter test integration_test/ --verbose
```

### Run with Screenshots

```dart
await tester.takeScreenshot('screenshot_name');
```

### Use Debugger

```dart
await tester.pump(Duration(seconds: 30)); // Pause for debugging
```

## Performance Testing

Integration tests can also measure performance:

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('measure scan performance', (WidgetTester tester) async {
    await binding.watchPerformance(() async {
      // Perform scan workflow
      await IntegrationTestHelper.performScan(/*...*/);
    });
  });
}
```

## Troubleshooting

### "Driver not found" errors

Make sure you're running on a connected device or emulator:
```bash
flutter devices
```

### Timeout errors

Increase timeout for async operations:
```dart
await tester.pumpAndSettle(Duration(seconds: 10));
```

### State persistence issues

Reset app state between tests:
```dart
setUp(() async {
  await IntegrationTestHelper.resetAppState();
});
```

## Resources

- [Flutter Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Flutter Driver](https://api.flutter.dev/flutter/flutter_driver/flutter_driver-library.html)
