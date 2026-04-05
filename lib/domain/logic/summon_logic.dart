import 'dart:math';

import '../enums/lineage.dart';

class SummonLogic {
  static const int stoneCost = 10;
  static const double rareProbability = 0.10; // 10%

  static final _rng = Random();

  /// 소환석 10개를 소비해 계통을 결정한다.
  static Lineage roll() {
    if (_rng.nextDouble() < rareProbability) {
      return Lineage.rare;
    }
    final pool = Lineage.commonPool;
    return pool[_rng.nextInt(pool.length)];
  }

  /// 스트릭 보상 소환석 수량
  static int streakStoneReward(int streak) {
    if (streak == 30) return 15;
    if (streak == 14) return 8;
    if (streak == 7)  return 5;
    return 0;
  }

  /// 캐릭터를 놓아줄 때 돌려받는 소환석 (레벨당 2석, 최소 2)
  static int releaseReward(int level) => (level * 2).clamp(2, 999);
}
