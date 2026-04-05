import 'package:flutter/foundation.dart';

/// 앱 전체에서 현재 시각을 제공하는 유틸.
/// 디버그 모드에서만 날짜 오프셋을 설정할 수 있다.
class AppClock {
  AppClock._();

  static int _offsetDays = 0;

  /// 현재 날짜+시간 (디버그 오프셋 포함).
  static DateTime now() {
    final base = DateTime.now();
    if (!kDebugMode || _offsetDays == 0) return base;
    return base.add(Duration(days: _offsetDays));
  }

  // ── Debug-only controls ──────────────────────────────────────────────────

  static int get offsetDays => _offsetDays;

  static void addDay() {
    assert(kDebugMode);
    _offsetDays++;
  }

  static void subtractDay() {
    assert(kDebugMode);
    _offsetDays--;
  }

  static void reset() {
    assert(kDebugMode);
    _offsetDays = 0;
  }
}
