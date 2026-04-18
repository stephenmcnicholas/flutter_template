import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnectionImpl() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    // TODO: rename to your app's database file (e.g. 'mealplanner.sqlite')
    final file = File(p.join(dir.path, 'fytter.sqlite'));
    return NativeDatabase(file);
  });
}

QueryExecutor openTestConnectionImpl() {
  return NativeDatabase.memory();
}
