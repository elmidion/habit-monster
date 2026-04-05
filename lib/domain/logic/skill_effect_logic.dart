import 'dart:math';

import '../enums/lineage.dart';
import '../enums/mission_category.dart';

/// 활성 캐릭터의 스킬 효과를 계산하는 유틸
class SkillEffectLogic {
  static final _rng = Random();

  /// 미션 완료 시 실제 EXP 배율 (1.0 = 변화 없음)
  static double expMultiplier({
    required List<String> skillIds,
    required Lineage lineage,
    required MissionCategory category,
    required int creatureLevel,
    required int currentStreak,
    required int todayCompletionCount,
  }) {
    double multiplier = 1.0;

    // 빠른 성장: 모든 미션 EXP +15%
    if (skillIds.contains('skill_fast_growth')) multiplier += 0.15;

    // 빠른 학습: Lv10 이하 EXP +25%
    if (skillIds.contains('skill_quick_learner') && creatureLevel <= 10) {
      multiplier += 0.25;
    }

    // 콤보 파워: 오늘 2번째 미션부터 +20%
    if (skillIds.contains('skill_combo_power') && todayCompletionCount >= 1) {
      multiplier += 0.20;
    }

    // 무지개 힘: 모든 미션 +20%
    if (skillIds.contains('skill_rainbow')) multiplier += 0.20;

    // 끈기의 힘: 스트릭 7일 이상 +15%
    if (skillIds.contains('skill_endurance') && currentStreak >= 7) {
      multiplier += 0.15;
    }

    // 만능 공명: 모든 미션 +25%
    if (skillIds.contains('skill_master')) multiplier += 0.25;

    // 계보 고유 1단계: 특정 카테고리 +15%
    if (_hasLineageBoost(skillIds, lineage, category, stage: 1)) multiplier += 0.15;
    // 계보 고유 2단계: 특정 카테고리 +30% (1단계 대체)
    if (_hasLineageBoost(skillIds, lineage, category, stage: 2)) multiplier += 0.15;

    // 신비 계보 1단계: 모든 카테고리 +10%
    if (skillIds.contains('skill_rare_all_boost_1')) multiplier += 0.10;
    // 신비 계보 2단계: 모든 카테고리 +20% (1단계 대체)
    if (skillIds.contains('skill_rare_all_boost_2')) multiplier += 0.10;

    return multiplier;
  }

  /// 스트릭 보너스 EXP 배율
  static double streakBonusMultiplier(List<String> skillIds) {
    double multiplier = 1.0;
    // 꾸준함의 씨앗: +50%
    if (skillIds.contains('skill_streak_seed')) multiplier += 0.5;
    // 스트릭 부스터: 2배
    if (skillIds.contains('skill_double_streak')) multiplier += 1.0;
    // 전설의 끈기: 3배
    if (skillIds.contains('skill_mega_streak')) multiplier += 2.0;
    return multiplier;
  }

  /// 첫 미션 보너스 배율 (오늘 첫 미션일 때)
  static double firstMissionMultiplier(List<String> skillIds, int todayCompletionCount) {
    if (todayCompletionCount == 0 && skillIds.contains('skill_first_step')) {
      return 1.5;
    }
    return 1.0;
  }

  /// 완벽한 하루 보너스 EXP (미션 3개 이상 완료 시)
  static int perfectDayBonus(List<String> skillIds, int todayCompletionCount) {
    if (skillIds.contains('skill_perfect_day') && todayCompletionCount >= 3) {
      return 30;
    }
    return 0;
  }

  /// 미션 완료 시 추가 소환석
  static int bonusStones(List<String> skillIds) {
    int bonus = 0;
    if (skillIds.contains('skill_stone_sense')) bonus += 1;
    if (skillIds.contains('skill_stone_mine')) bonus += 2;
    if (skillIds.contains('skill_stone_fountain')) bonus += 3;
    // 행운의 돌: 50% 확률로 +1
    if (skillIds.contains('skill_stone_luck') && _rng.nextBool()) bonus += 1;
    return bonus;
  }

  /// 레벨업 시 소환석 보너스
  static int levelUpStoneBonus(List<String> skillIds) {
    if (skillIds.contains('skill_levelup_gift')) return 5;
    return 0;
  }

  /// EXP 나눔 비율 (보관함 내 다른 캐릭터에게)
  static double expShareRatio(List<String> skillIds) {
    return skillIds.contains('skill_exp_share') ? 0.1 : 0.0;
  }

  /// 스트릭 가드 활성 여부
  static bool hasStreakGuard(List<String> skillIds) {
    return skillIds.contains('skill_streak_guard');
  }

  static bool _hasLineageBoost(List<String> skillIds, Lineage lineage, MissionCategory category, {required int stage}) {
    if (category.name != lineage.boostCategory) return false;
    final id = _lineageBoostSkillId(lineage, stage);
    return skillIds.contains(id);
  }

  static String _lineageBoostSkillId(Lineage lineage, int stage) {
    switch (lineage) {
      case Lineage.dragon:  return 'skill_dragon_boost_$stage';
      case Lineage.plant:   return 'skill_plant_boost_$stage';
      case Lineage.machine: return 'skill_machine_boost_$stage';
      case Lineage.fairy:   return 'skill_fairy_boost_$stage';
      case Lineage.rare:    return 'skill_rare_all_boost_$stage';
    }
  }
}
