import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/logger/rest_timer_settings_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('RestTimerSettingsScreen shows current duration', (tester) async {
    SharedPreferences.setMockInitialValues({
      'restTimerDefaultSeconds': 120,
      'restTimerHapticsEnabled': true,
      'restTimerSoundEnabled': true,
    });
    SharedPrefs.instance.resetForTests();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: FytterTheme.light, home: const RestTimerSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
  });
}
