import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database_service.dart';
import '../../core/utils/app_clock.dart';
import '../../data/models/completion_model.dart';
import '../../domain/logic/streak_logic.dart';

// ── Today's completions ────────────────────────────────────────────────────
final todayCompletionsProvider =
    FutureProvider<List<CompletionModel>>((ref) async {
  return DatabaseService.getCompletionsForDate(AppClock.now());
});

/// Set of missionIds completed today — convenient for UI checks.
final todayCompletedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final list = await ref.watch(todayCompletionsProvider.future);
  return list.map((c) => c.missionId).toSet();
});

// ── All completions ────────────────────────────────────────────────────────
final allCompletionsProvider =
    FutureProvider<List<CompletionModel>>((ref) async {
  return DatabaseService.getAllCompletions();
});

// ── Streak ─────────────────────────────────────────────────────────────────
final streakProvider = FutureProvider<StreakResult>((ref) async {
  final dates = await DatabaseService.getActiveDates();
  return StreakLogic.compute(dates);
});
