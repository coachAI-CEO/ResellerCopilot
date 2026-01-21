# Reseller Copilot Tests

This directory contains all unit and widget tests for the Reseller Copilot application.

## Test Structure

```
test/
├── services/
│   └── supabase_service_test.dart  # Unit tests for SupabaseService
├── screens/
│   ├── auth_screen_test.dart       # Widget tests for AuthScreen
│   └── scanner_screen_test.dart    # Widget tests for ScannerScreen
└── README.md                        # This file
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run tests with coverage
```bash
flutter test --coverage
```

### View coverage report (requires lcov)
```bash
# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### Run specific test file
```bash
flutter test test/services/supabase_service_test.dart
```

### Run tests matching a pattern
```bash
flutter test --name="SupabaseService"
```

## Generating Mocks

The tests use Mockito for mocking dependencies. Mock files are auto-generated using `build_runner`.

### Generate mock files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch mode (auto-regenerate on changes)
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Test Coverage Goals

- **Overall Coverage:** 70%+
- **Services:** 80%+ (critical business logic)
- **Screens:** 60%+ (UI components)
- **Models:** 90%+ (data models)

## Writing New Tests

### Unit Tests

Create test files in `test/services/` or `test/models/`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([YourDependency])
void main() {
  late MockYourDependency mockDependency;

  setUp(() {
    mockDependency = MockYourDependency();
  });

  test('description of what you are testing', () {
    // Arrange
    when(mockDependency.method()).thenReturn(value);

    // Act
    final result = yourFunction();

    // Assert
    expect(result, expectedValue);
    verify(mockDependency.method()).called(1);
  });
}
```

### Widget Tests

Create test files in `test/screens/`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidget() {
    return MaterialApp(
      home: YourWidget(),
    );
  }

  testWidgets('description of UI behavior', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(createWidget());

    // Interact with the widget
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    // Verify the result
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

## Integration Tests

Integration tests are in the `integration_test/` directory. See `integration_test/README.md` for details.

## CI/CD Integration

Tests run automatically on:
- Pull requests
- Push to main/develop branches

See `.github/workflows/ci.yml` for CI configuration.

## Troubleshooting

### "Missing mock file" errors

Run build_runner to generate mocks:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Package not found" errors

Make sure dependencies are installed:
```bash
flutter pub get
```

### "Invalid test" errors

Ensure your test files end with `_test.dart` and are in the `test/` directory.

## Best Practices

1. **Test Naming:** Use descriptive names that explain what's being tested
2. **Arrange-Act-Assert:** Structure tests clearly with setup, action, and verification
3. **One Assertion Per Test:** Keep tests focused and easy to debug
4. **Mock External Dependencies:** Don't make real API calls in unit tests
5. **Clean Up:** Use `setUp()` and `tearDown()` to manage test state
6. **Test Edge Cases:** Include tests for error conditions and boundary values

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Test Package](https://pub.dev/packages/integration_test)
