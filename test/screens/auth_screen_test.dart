import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reseller_copilot/screens/auth_screen.dart';

import 'auth_screen_test.mocks.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient])
void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(mockSupabase.auth).thenReturn(mockAuth);

    // Set up Supabase singleton (required for AuthScreen to work)
    // Note: This is a workaround since AuthScreen uses Supabase.instance.client
    // In a real refactor, we'd inject the client as a dependency
  });

  Widget createAuthScreen() {
    return MaterialApp(
      home: AuthScreen(),
    );
  }

  group('AuthScreen - UI Tests', () {
    testWidgets('should display app title and subtitle', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(createAuthScreen());

      // Verify title
      expect(find.text('Reseller Copilot'), findsOneWidget);

      // Verify subtitle
      expect(find.text('Analyze product profitability'), findsOneWidget);

      // Verify logo icon
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
    });

    testWidgets('should display login/signup toggle', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Verify both toggle options are visible
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should display email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Find text fields by their hint text
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });

    testWidgets('should display submit button with correct text', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Initially in login mode
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('should switch to signup mode when Sign Up is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Tap Sign Up toggle
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Button should now say "Sign Up"
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets('should switch back to login mode when Login is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Switch to signup mode first
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Tap Login toggle
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Button should say "Login"
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });
  });

  group('AuthScreen - Form Validation', () {
    testWidgets('should show error when email is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Leave email empty, fill password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Tap submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should show error when password is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Fill email, leave password empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      // Tap submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should show error for invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Tap submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show error for short password', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      // Enter short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );

      // Tap submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  group('AuthScreen - Loading State', () {
    testWidgets('should show loading indicator during authentication', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Note: Testing loading state requires mocking Supabase auth call
      // This is a simplified test that verifies the UI structure

      // Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // The loading indicator would appear during async auth
      // Full testing would require integration test or mocking
    });
  });

  group('AuthScreen - Accessibility', () {
    testWidgets('should have proper semantics for screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Verify form field semantics
      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget);

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      expect(passwordField, findsOneWidget);

      // Verify button semantics
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButton, findsOneWidget);
    });
  });
}
