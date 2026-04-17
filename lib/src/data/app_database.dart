import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database_connection.dart';

part 'app_database.g.dart';

// Add your app's tables here. Example:
// class Items extends Table {
//   IntColumn get id => integer().autoIncrement()();
//   TextColumn get name => text()();
// }

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.test() : super(openTestConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Add migration steps here as schemaVersion increments
    },
  );
}
