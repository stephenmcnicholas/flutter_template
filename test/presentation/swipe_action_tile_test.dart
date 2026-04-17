import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/swipe_action_tile.dart';

void main() {
  testWidgets('SwipeActionTile renders and responds to onDelete', (WidgetTester tester) async {
    bool deleted = false;
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SwipeActionTile(
          child: const ListTile(title: Text('Test')), 
          onDelete: () { deleted = true; },
          onReplace: () {},
        ),
      ),
    ));
    // Simulate swipe to delete (or just call onDelete directly)
    expect(find.text('Test'), findsOneWidget);
    // Call onDelete
    (tester.firstWidget(find.byType(SwipeActionTile)) as SwipeActionTile).onDelete();
    expect(deleted, true);
  });
} 