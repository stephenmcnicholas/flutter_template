import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/profile/profile_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/login_prompt_provider.dart';
import '../test_utils/fake_auth_repository.dart';
import '../test_utils/fake_login_prompt_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ProfileScreen shows fields and enables save on change', (tester) async {
    SharedPreferences.setMockInitialValues({
      'profileDisplayName': 'Sam',
      'profileEmail': 'sam@example.com',
    });
    SharedPrefs.instance.resetForTests();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
        ],
        child: MaterialApp(theme: FytterTheme.light, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);

    // Save should be disabled before changes
    final saveButtonBefore =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(saveButtonBefore.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Samuel');
    await tester.pump();

    final saveButtonAfter =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(saveButtonAfter.onPressed, isNotNull);
  });
}
