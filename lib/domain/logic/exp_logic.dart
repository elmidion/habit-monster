import '../definitions/skill_definitions.dart';

class LevelUpResult {
  final int newLevel;
  final int newCurrentExp;
  final bool didLevelUp;
  final bool didEvolve;
  /// 스킬 선택이 필요한 티어 목록 (레벨업 중 통과한 스킬 선택 레벨들)
  final List<int> pendingSkillTiers;

  const LevelUpResult({
    required this.newLevel,
    required this.newCurrentExp,
    required this.didLevelUp,
    required this.didEvolve,
    required this.pendingSkillTiers,
  });
}

class ExpLogic {
  /// 목표: 하루 4미션 × 7일 → Lv20 (진화) 도달
  /// 단계별 필요 EXP:
  ///   Lv 1~9  (유체):  35 EXP/레벨 → 총 315
  ///   Lv 10~19 (성체): 50 EXP/레벨 → 총 500
  ///   Lv 20+  (진화):  80 EXP/레벨
  static int expRequiredForLevel(int level) {
    if (level < 10) return 35;
    if (level < 20) return 50;
    return 80;
  }

  static int streakBonusExp(int currentStreak) {
    if (currentStreak >= 30) return 20;
    if (currentStreak >= 14) return 15;
    if (currentStreak >= 7)  return 10;
    if (currentStreak >= 3)  return 5;
    return 0;
  }

  static LevelUpResult applyExp({
    required int currentLevel,
    required int currentExp,
    required int expGained,
    required List<String> existingSkillIds,
  }) {
    int level = currentLevel;
    int exp = currentExp + expGained;
    bool didLevelUp = false;
    bool didEvolve = false;
    final List<int> pendingTiers = [];

    while (level < 99) {
      final required = expRequiredForLevel(level);
      if (exp >= required) {
        exp -= required;
        level++;
        didLevelUp = true;

        if (level == 10) didEvolve = false; // 성체 전환 (진화 아님)
        if (level == 20) didEvolve = true;  // 실제 진화

        // 스킬 선택 레벨을 통과했는지 확인
        final tier = tierForLevel(level);
        if (tier != null) {
          pendingTiers.add(tier);
        }
      } else {
        break;
      }
    }

    return LevelUpResult(
      newLevel: level,
      newCurrentExp: exp,
      didLevelUp: didLevelUp,
      didEvolve: didEvolve,
      pendingSkillTiers: pendingTiers,
    );
  }
}
