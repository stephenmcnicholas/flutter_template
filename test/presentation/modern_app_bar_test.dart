import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/modern_app_bar.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

const _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class _MockHttpClient extends Fake implements HttpClient {
  bool _autoUncompress = true;

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final stream = Stream<List<int>>.fromIterable([_transparentImage]);
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('ModernAppBar shows title, initials, and streak',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          appBar: const ModernAppBar(
            title: 'Workouts',
            profileInitials: 'SM',
            streakCount: 5,
          ),
        ),
      ),
    );

    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('SM'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
  });

  testWidgets('ModernAppBar shows person icon when no initials',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          appBar: ModernAppBar(
            title: 'Exercises',
            profileInitials: '',
          ),
        ),
      ),
    );

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('ModernAppBar uses profile image when provided',
      (tester) async {
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FytterTheme.light,
            home: const Scaffold(
              appBar: ModernAppBar(
                title: 'Progress',
                profileImageUrl: 'https://example.com/avatar.png',
              ),
            ),
          ),
        );

        final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(avatar.backgroundImage, isA<NetworkImage>());
        expect((avatar.backgroundImage as NetworkImage).url,
            'https://example.com/avatar.png');
      },
      createHttpClient: (_) => _MockHttpClient(),
    );
  });

  testWidgets('ModernAppBar triggers profile tap callback',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          appBar: ModernAppBar(
            title: 'Workouts',
            profileInitials: 'SM',
            onProfileTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CircleAvatar));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

