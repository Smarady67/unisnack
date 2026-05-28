import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:unisnack/screens/signin_screen.dart';
import 'package:unisnack/screens/signup_screen.dart';
import 'package:unisnack/providers/auth_provider.dart';

void main() {
  group('SignInScreen Widget Tests', () {
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

    testWidgets('SignInScreen displays email and password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Shows validation error when email field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to submit without filling email
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('Shows validation error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill with invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Shows validation error when password field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill email but leave password empty
      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Shows validation error when password is too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'short');

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Sign up link navigates to SignUpScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
    });

    testWidgets('Forgot Password link is clickable',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Forgot Password?'), findsOneWidget);

      // Verify the link can be tapped
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should navigate to forgot password screen
      expect(find.text('Forgot Password'), findsOneWidget);
    });

    testWidgets('Email validation accepts valid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'valid@example.com');
      await tester.enterText(textFields.last, 'password123');

      // Try to submit (should pass email validation)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpWidget(createWidgetUnderTest());

      // Email validation error should NOT appear
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Email is required'), findsNothing);
    });

    testWidgets('Form has proper structure with back button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
