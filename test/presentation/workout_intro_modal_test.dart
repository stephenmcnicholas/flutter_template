import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/logger/workout_intro_modal.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/services/audio/audio_service.dart';
import 'package:fytter/src/services/audio/audio_template_engine.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioService extends Mock implements AudioService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() {
    registerFallbackValue(<AudioClipSpec>[]);
  });

  testWidgets('WorkoutIntroModal shows summary and dismisses on tap', (tester) async {
    final mockAudio = MockAudioService();
    when(() => mockAudio.playSequence(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWith((ref) => mockAudio),
          audioTemplateEngineProvider.overrideWith((ref) => AudioTemplateEngine()),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => UncontrolledProviderScope(
                        container: ProviderScope.containerOf(context),
                        child: WorkoutIntroModal(
                          exerciseCount: 3,
                          durationMinutes: 45,
                          firstExerciseId: 'e1',
                          onDismiss: () {},
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Session summary'), findsOneWidget);
    expect(find.textContaining('3 exercise'), findsOneWidget);

    await tester.tap(find.text('Ready to go'));
    await tester.pumpAndSettle();

    expect(find.text('Session summary'), findsNothing);
    verify(() => mockAudio.playSequence(any())).called(1);
  });
}
