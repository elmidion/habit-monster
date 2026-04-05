import '../../core/utils/app_clock.dart';

class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final bool isComebackDay;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.isComebackDay,
  });
}

class StreakLogic {
  /// Computes streak from a list of dates on which missions were completed.
  /// [activeDates] should be normalized to midnight (date only, no time).
  static StreakResult compute(List<DateTime> activeDates) {
    if (activeDates.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0, isComebackDay: false);
    }

    final sorted = activeDates.map(_normalizeDate).toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    final today = _normalizeDate(AppClock.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Current streak: consecutive days ending today or yesterday
    int current = 0;
    DateTime? checkDate = sorted.contains(today) ? today : null;
    checkDate ??= sorted.contains(yesterday) ? yesterday : null;

    if (checkDate != null) {
      current = 1;
      DateTime prev = checkDate;
      for (int i = sorted.indexOf(checkDate) - 1; i >= 0; i--) {
        final diff = prev.difference(sorted[i]).inDays;
        if (diff == 1) {
          current++;
          prev = sorted[i];
        } else {
          break;
        }
      }
    }

    // Longest streak ever
    int longest = 0;
    int streak = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        longest = streak > longest ? streak : longest;
        streak = 1;
      }
    }
    longest = streak > longest ? streak : longest;

    // Is comeback day: completed today after a gap of ≥2 days
    bool isComebackDay = false;
    if (sorted.contains(today) && sorted.length >= 2) {
      final lastBefore = sorted[sorted.length - 2];
      final gap = today.difference(lastBefore).inDays;
      if (gap >= 2) isComebackDay = true;
    }

    return StreakResult(
      currentStreak: current,
      longestStreak: longest,
      isComebackDay: isComebackDay,
    );
  }

  static DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
