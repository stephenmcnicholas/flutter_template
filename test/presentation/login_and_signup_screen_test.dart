import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/auth/login_screen.dart';
import 'package:fytter/src/presentation/auth/signup_screen.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/test_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('LoginScreen email sign-in pops on success', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => c.push('/login'),
                child: const Text('to-login'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (c, s) => const LoginScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('to-login'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'hello@test.com');
    await tester.enterText(fields.at(1), 'secret12');
    await tester.tap(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.widgetWithText(AppButton, 'Sign in'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('to-login'), findsOneWidget);
  });

  testWidgets('SignupScreen shows verify dialog after sign-up', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => c.push('/signup'),
                child: const Text('to-signup'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/signup',
          builder: (c, s) => const SignupScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('to-signup'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new@test.com');
    await tester.enterText(fields.at(1), 'secret12');
    await tester.enterText(fields.at(2), 'secret12');
    await tester.tap(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.widgetWithText(AppButton, 'Create account'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });
}
