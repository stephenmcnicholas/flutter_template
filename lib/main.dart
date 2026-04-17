import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/presentation/app_router.dart';
import 'src/presentation/theme.dart'; // if you have a theme file
import 'src/providers/auth_providers.dart';
import 'src/providers/audio_providers.dart';
import 'src/providers/theme_settings_provider.dart';
import 'src/services/notification_service.dart';
import 'src/services/notification_sync_service.dart';

Future<void> main() async {
  await bootstrap();
}

Future<void> bootstrap({bool skipFirebase = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching to prevent AssetManifest.json errors
  // Fonts will fall back to system fonts if Google Fonts can't load
  GoogleFonts.config.allowRuntimeFetching = false;

  if (!skipFirebase && !kIsWeb) {
    await Firebase.initializeApp();
    await initNotificationChannels();
  }

  runApp(const ProviderScope(child: FytterApp()));
}

class FytterApp extends ConsumerStatefulWidget {
  const FytterApp({super.key});

  @override
  ConsumerState<FytterApp> createState() => _FytterAppState();
}

class _FytterAppState extends ConsumerState<FytterApp> {
  bool _tokenRefreshSetup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sentenceLibraryProvider.future);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_tokenRefreshSetup && !kIsWeb) {
      _tokenRefreshSetup = true;
      setupFCMTokenRefresh(() async {
        final token = await getFCMToken();
        final user = ref.read(authUserProvider).valueOrNull;
        if (user != null && token != null) {
          await updateFCMTokenInFirestore(
            uid: user.uid,
            fcmToken: token,
            timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
          );
        }
      });
    }
    final themeSettings = ref.watch(themeSettingsProvider);
    return MaterialApp.router(
      title: 'Fytter',
      theme: FytterTheme.light,      // or your ThemeData
      darkTheme: FytterTheme.dark,   // optional
      themeMode: themeSettings.mode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}