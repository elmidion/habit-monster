import '../../data/models/completion_model.dart';

class BadgeLogic {
  static List<String> detectNewBadges({
    required List<String> existingBadgeIds,
    required int level,
    required int totalDaysActive,
    required int currentStreak,
    required bool isFirstHatch,
    required bool isComebackDay,
    required bool justEvolved,
    required List<CompletionModel> todayCompletions,
    required List<CompletionModel> allCompletions,
    required int totalHatched,   // 지금까지 부화시킨 총 마리 수
    required bool justReleased,  // 이번에 놓아줬는지
  }) {
    final earned = <String>[];

    void tryAdd(String id, bool condition) {
      if (condition && !existingBadgeIds.contains(id) && !earned.contains(id)) {
        earned.add(id);
      }
    }

    final total = allCompletions.length;
    final catCounts = <String, int>{};
    for (final c in allCompletions) {
      catCounts[c.category.name] = (catCounts[c.category.name] ?? 0) + 1;
    }

    // ── 첫 발걸음 ──────────────────────────────────────────────────────────
    tryAdd('first_hatch', isFirstHatch);
    tryAdd('evolved',     justEvolved);
    tryAdd('comeback',    isComebackDay);

    // ── 스트릭 ─────────────────────────────────────────────────────────────
    tryAdd('streak_3',   currentStreak >= 3);
    tryAdd('streak_7',   currentStreak >= 7);
    tryAdd('streak_14',  currentStreak >= 14);
    tryAdd('streak_30',  currentStreak >= 30);
    tryAdd('streak_60',  currentStreak >= 60);
    tryAdd('streak_100', currentStreak >= 100);

    // ── 레벨 ───────────────────────────────────────────────────────────────
    tryAdd('level_5',  level >= 5);
    tryAdd('level_10', level >= 10);
    tryAdd('level_15', level >= 15);
    tryAdd('level_20', level >= 20);
    tryAdd('level_30', level >= 30);
    tryAdd('level_50', level >= 50);

    // ── 미션 누적 ──────────────────────────────────────────────────────────
    tryAdd('missions_10',  total >= 10);
    tryAdd('missions_50',  total >= 50);
    tryAdd('missions_100', total >= 100);
    tryAdd('missions_300', total >= 300);
    tryAdd('missions_500', total >= 500);

    // ── 카테고리 전문가 ────────────────────────────────────────────────────
    tryAdd('fire_master',     (catCounts['fire']     ?? 0) >= 30);
    tryAdd('water_master',    (catCounts['water']    ?? 0) >= 30);
    tryAdd('grass_master',    (catCounts['grass']    ?? 0) >= 30);
    tryAdd('electric_master', (catCounts['electric'] ?? 0) >= 30);
    tryAdd('moon_master',     (catCounts['moon']     ?? 0) >= 30);

    // ── 컬렉션 ─────────────────────────────────────────────────────────────
    tryAdd('collector_3',   totalHatched >= 3);
    tryAdd('collector_5',   totalHatched >= 5);
    tryAdd('first_release', justReleased);

    // ── 하루 완성 ──────────────────────────────────────────────────────────
    if (todayCompletions.isNotEmpty) {
      final todayCats = todayCompletions.map((c) => c.category.name).toSet();
      tryAdd('all_types', todayCats.length >= 5);
    }
    tryAdd('total_30',  totalDaysActive >= 30);
    tryAdd('total_100', totalDaysActive >= 100);

    return earned;
  }
}
