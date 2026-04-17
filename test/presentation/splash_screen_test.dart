import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows gif image', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    final provider = imageWidget.image as AssetImage;
    expect(provider.assetName, 'assets/FytterSplash.gif');
  });
}
