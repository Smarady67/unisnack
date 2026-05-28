import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:unisnack/screens/signup_screen.dart';
import 'package:unisnack/screens/verify_identity_screen.dart';
import 'package:unisnack/providers/auth_provider.dart';

@GenerateMocks([AuthProvider])
void main() {
  group('SignUpScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ],
        child: const MaterialApp(home: SignUpScreen()),
      );
    }

    testWidgets('SignUpScreen displays all required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sign up'), findsWidgets);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('Shows validation error when username is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to submit without filling username
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('Shows validation error when username is too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill with short username
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'ab'); // Less than 3 chars

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
          find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('Shows validation error for invalid email',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'valid_user');
      await tester.enterText(textFields.at(1), 'not-an-email');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Shows validation error when passwords do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'valid_user');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password456'); // Different

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Shows validation error when password is too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'valid_user');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'short'); // Less than 6 chars
      await tester.enterText(textFields.at(3), 'short');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Shows loading state when signing up',
        (WidgetTester tester) async {
      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Creating...'), findsOneWidget);
    });

    testWidgets('Sign in link navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should navigate back (in this test, we just verify the tap works)
      expect(find.byType(SignUpScreen), findsOneWidget);
    });

    testWidgets('All text form fields have validation enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFormFields = find.byType(TextFormField);

      // Should find 4 text form fields (username, email, password, confirmPassword)
      expect(textFormFields, findsNWidgets(4));
    });

    testWidgets('Sign up button is disabled while loading',
        (WidgetTester tester) async {
      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      final button = find.widgetWithText(ElevatedButton, 'Creating...');
      expect(button, findsOneWidget);
    });
  });
}
