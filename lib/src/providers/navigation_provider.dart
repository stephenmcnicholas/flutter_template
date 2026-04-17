import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global selected tab index for RootScaffold.
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// Selected program ID for the Programs tab embedded detail view.
final selectedProgramIdProvider = StateProvider<String?>((ref) => null);
