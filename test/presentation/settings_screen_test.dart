import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/settings/settings_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('SettingsScreen shows sections and toggles', (tester) async {
    SharedPreferences.setMockInitialValues({
      'restTimerDefaultSeconds': 120,
      'restTimerHapticsEnabled': true,
      'restTimerSoundEnabled': true,
      'themeMode': 'system',
      'weightUnit': WeightUnit.kg.name,
      'distanceUnit': DistanceUnit.km.name,
      'audio_coaching_mode': 'guided',
      'workout_experience_mode': 'guided',
    });
    SharedPrefs.instance.resetForTests();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: FytterTheme.light, home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Starting a workout'), findsOneWidget);
    expect(find.text('Guided'), findsWidgets);
    expect(find.text('Logger'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Appearance'),
      400,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
    );
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Units'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Units'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows Notifications section with reminder switch', (tester) async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'system',
      'notifications_enabled': true,
      'notifications_reminder_time_minutes': 8 * 60,
    });
    SharedPrefs.instance.resetForTests();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: FytterTheme.light, home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Notifications'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Workout reminders'), findsOneWidget);
    expect(find.text('Daily reminder for scheduled program workouts'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
  });
}
