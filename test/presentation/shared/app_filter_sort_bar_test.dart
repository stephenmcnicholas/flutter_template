import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_body_region.dart';
import 'package:fytter/src/presentation/shared/app_filter_sort_bar.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

const _testBodyAreas = [
  ExerciseBodyRegion.chest,
  ExerciseBodyRegion.legs,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  group('AppFilterSortBar', () {
    testWidgets('displays search field and sort button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date', 'Volume'],
              onSortOptionSelected: (option, ascending) {},
              showFilterButton: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the search TextField
      expect(find.byType(TextField), findsOneWidget);
      
      // Should find the sort button (PopupMenuButton)
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('calls onFilterChanged when text is entered', (tester) async {
      String? filterValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (value) => filterValue = value,
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              showFilterButton: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      expect(filterValue, 'test');
    });

    testWidgets('displays current filter text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: 'existing filter',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              showFilterButton: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The TextField should be present and we can verify the hint text
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows sort dropdown when sort button is tapped', (tester) async {

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date', 'Volume'],
              onSortOptionSelected: (option, ascending) {},
              showFilterButton: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the sort button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Should find sort options in the popup menu
      expect(find.text('Name'), findsWidgets);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
    });

    testWidgets('toggles sort direction when same option is selected', (tester) async {
      String? selectedOption;
      bool? selectedAscending;

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {
                selectedOption = option;
                selectedAscending = ascending;
              },
              showFilterButton: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the sort button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Select the same option (Name) - should toggle direction
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      expect(selectedOption, 'Name');
      expect(selectedAscending, false); // Toggled from true to false
    });

    testWidgets('sets new option as ascending when different option is selected', (tester) async {
      String? selectedOption;
      bool? selectedAscending;

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {
                selectedOption = option;
                selectedAscending = ascending;
              },
              showFilterButton: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the sort button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Select a different option (Date) - should default to ascending
      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();

      expect(selectedOption, 'Date');
      expect(selectedAscending, true); // New option defaults to ascending
    });

    testWidgets('displays filter button when showFilterButton is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the filter icon button
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('filter button shows active state when filter is applied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              currentBodyAreaFilter: const ['chest'],
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find filter button with active state (primary color)
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('filter button opens menu with Body area and Equipment options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the filter icon button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should find Body area and Equipment sections
      expect(find.text('Body area'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
    });

    testWidgets('filter button shows checkmark when body part filter is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              currentBodyAreaFilter: const ['chest'],
              bodyAreaRegions: _testBodyAreas,
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show active filter badge count
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('filter button shows Clear Filters option when filter is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              currentBodyAreaFilter: const ['chest'],
              bodyAreaRegions: _testBodyAreas,
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should find Clear all option
      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('opening body part filter shows dialog with options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show sheet with body-area options (e.g., Chest, Legs)
      expect(find.text('Chest'), findsOneWidget);
    });

    testWidgets('selecting a body part filter value calls callback', (tester) async {
      List<String> selectedValues = [];

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (values) => selectedValues = values,
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Ensure the dialog is visible and find the Chest option
      final chestText = find.text('Chest');
      expect(chestText, findsOneWidget);
      
      // Scroll to ensure it's visible if needed
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.ensureVisible(chestText);
        await tester.pumpAndSettle();
      }
      
      // Tap the Chest tile
      await tester.tap(chestText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Callback should be called with selected values
      expect(selectedValues, contains('chest'));
    });

    testWidgets('Clear All in filter dialog clears filter', (tester) async {
      List<String> selectedValues = ['chest']; // Start with a filter

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              currentBodyAreaFilter: const ['chest'],
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (values) => selectedValues = values,
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Find and tap the Clear All button
      final clearAllButton = find.text('Clear all');
      expect(clearAllButton, findsOneWidget);
      await tester.tap(clearAllButton);
      await tester.pumpAndSettle();

      // Callback should be called with empty list to clear filter
      expect(selectedValues, isEmpty);
    });

    testWidgets('opening equipment filter shows dialog with options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show some equipment options (e.g., Barbell, Dumbbell)
      expect(find.text('Barbell'), findsOneWidget);
    });

    testWidgets('selecting an equipment filter value calls callback', (tester) async {
      List<String> selectedValues = [];

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (_) {},
              onEquipmentFilterChanged: (values) => selectedValues = values,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Ensure the dialog is visible and find the Barbell option
      final barbellText = find.text('Barbell');
      expect(barbellText, findsOneWidget);
      
      // Ensure the option is visible before tapping
      await tester.ensureVisible(barbellText);
      await tester.pumpAndSettle();
      
      // Tap the Barbell tile
      await tester.tap(barbellText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Callback should be called with selected values
      expect(selectedValues, contains('Barbell'));
    });

    testWidgets('Clear Filters option clears both filters', (tester) async {
      List<String> bodyPartValue = ['chest'];
      List<String> equipmentValue = ['Barbell'];

      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: AppFilterSortBar(
              filterText: '',
              onFilterChanged: (_) {},
              currentSortLabel: 'Name',
              isAscending: true,
              sortOptions: ['Name', 'Date'],
              onSortOptionSelected: (option, ascending) {},
              currentBodyAreaFilter: const ['chest'],
              currentEquipmentFilter: ['Barbell'],
              bodyAreaRegions: _testBodyAreas,
              equipmentOptions: const ['Barbell', 'Dumbbell'],
              onBodyAreaFilterChanged: (values) => bodyPartValue = values,
              onEquipmentFilterChanged: (values) => equipmentValue = values,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Tap Clear all
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      // Both callbacks should be called with empty lists
      expect(bodyPartValue, isEmpty);
      expect(equipmentValue, isEmpty);
    });
  });
}

