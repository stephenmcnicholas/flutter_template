import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/presentation/app_router.dart';
import 'src/presentation/theme.dart';
import 'src/providers/auth_providers.dart';
import 'src/providers/theme_settings_provider.dart';
import 'src/services/app_logger.dart';
import 'src/services/notification_service.dart';
import 'src/services/notification_sync_service.dart';

Future<void> main() async {
  await bootstrap();
}

Future<void> bootstrap({bool skipFirebase = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  AppLogger.event(AppEvent.appLaunch);

  if (!skipFirebase && !kIsWeb) {
    await Firebase.initializeApp();

    // App Check must be activated before any other Firebase service calls.
    // Debug provider in debug builds; production providers on release.
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      // ignore: deprecated_member_use
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );

    if (!kDebugMode) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    }

    await initNotificationChannels();

    // Route Flutter framework errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Route uncaught async errors outside the Flutter framework to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Wrap runApp so zone errors are also caught by Crashlytics.
  await runZonedGuarded(
    () async => runApp(const ProviderScope(child: TemplateApp())),
    (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class TemplateApp extends ConsumerStatefulWidget {
  const TemplateApp({super.key});

  @override
  ConsumerState<TemplateApp> createState() => _TemplateAppState();
}

class _TemplateAppState extends ConsumerState<TemplateApp> {
  bool _tokenRefreshSetup = false;

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
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Template App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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
