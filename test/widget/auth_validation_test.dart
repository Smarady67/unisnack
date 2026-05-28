import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:unisnack/screens/signin_screen.dart';
import 'package:unisnack/providers/auth_provider.dart';

void main() {
  group('SignInScreen Validation Tests', () {
    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      );
    }

    testWidgets('DisplaysSignInTitle', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('Email validation rejects empty email',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap sign in button without filling email
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('Password validation rejects empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill email but leave password empty
      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      // Should show password validation error
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Email validation rejects invalid format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill with invalid email
      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      // Should show invalid email error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Password validation rejects short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'valid@email.com');
      await tester.enterText(textFields.last, 'short');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      // Should show password length error
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Form accepts valid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'valid@email.com');
      await tester.enterText(textFields.last, 'password123');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      // No validation errors should appear
      expect(find.text('is required'), findsNothing);
      expect(find.text('must be'), findsNothing);
    });

    testWidgets('SignInScreen has correct layout elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('Email field accepts valid email', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'user@example.com');

      // Verify no error on valid email
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets('Sign in button is present', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    });
  });
}
