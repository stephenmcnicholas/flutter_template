// ignore_for_file: deprecated_member_use

import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnectionImpl() {
  return WebDatabase('fytter');
}

QueryExecutor openTestConnectionImpl() {
  return WebDatabase('fytter_test');
}
