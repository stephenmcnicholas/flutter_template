import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/user_scorecard_repository.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:fytter/src/providers/data_providers.dart';

final userScorecardRepositoryProvider =
    Provider<UserScorecardRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserScorecardRepository(db);
});

final userScorecardProvider = FutureProvider<UserScorecard?>((ref) async {
  final repo = ref.watch(userScorecardRepositoryProvider);
  return repo.getScorecard();
});
