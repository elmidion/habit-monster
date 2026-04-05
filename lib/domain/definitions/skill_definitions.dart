import '../enums/lineage.dart';

class SkillDefinition {
  final String id;
  final String nameKo;
  final String descriptionKo;
  final String emoji;
  final int tier; // 1, 2, 3

  const SkillDefinition({
    required this.id,
    required this.nameKo,
    required this.descriptionKo,
    required this.emoji,
    required this.tier,
  });
}

// ── 티어 1: Lv5 에서 선택 ──────────────────────────────────────────────────
const tier1Skills = [
  SkillDefinition(
    id: 'skill_stone_sense',
    nameKo: '소환석 감각',
    descriptionKo: '미션을 하면 소환석을 1개 더 받아요',
    emoji: '💎',
    tier: 1,
  ),
  SkillDefinition(
    id: 'skill_fast_growth',
    nameKo: '빠른 성장',
    descriptionKo: '미션을 하면 경험치를 조금 더 받아요',
    emoji: '📈',
    tier: 1,
  ),
  SkillDefinition(
    id: 'skill_first_step',
    nameKo: '첫 발걸음',
    descriptionKo: '오늘 첫 번째 미션의 경험치가 1.5배!',
    emoji: '🌅',
    tier: 1,
  ),
  SkillDefinition(
    id: 'skill_streak_seed',
    nameKo: '꾸준함의 씨앗',
    descriptionKo: '매일 연속으로 하면 받는 보너스가 더 커져요',
    emoji: '⭐',
    tier: 1,
  ),
  SkillDefinition(
    id: 'skill_quick_learner',
    nameKo: '빠른 학습',
    descriptionKo: '아직 어릴 때(Lv10 이하) 경험치를 많이 받아요',
    emoji: '🎒',
    tier: 1,
  ),
  SkillDefinition(
    id: 'skill_stone_luck',
    nameKo: '행운의 돌',
    descriptionKo: '운이 좋으면 소환석을 1개 더 받을 수 있어요',
    emoji: '🍀',
    tier: 1,
  ),
];

// ── 티어 2: Lv15 에서 선택 ─────────────────────────────────────────────────
const tier2Skills = [
  SkillDefinition(
    id: 'skill_streak_guard',
    nameKo: '불굴의 연속',
    descriptionKo: '일주일에 한 번은 쉬어도 연속 기록이 안 끊겨요',
    emoji: '🛡️',
    tier: 2,
  ),
  SkillDefinition(
    id: 'skill_combo_power',
    nameKo: '콤보 파워',
    descriptionKo: '오늘 두 번째 미션부터 경험치가 더 올라가요',
    emoji: '🔥',
    tier: 2,
  ),
  SkillDefinition(
    id: 'skill_stone_mine',
    nameKo: '소환석 광맥',
    descriptionKo: '미션을 하면 소환석을 2개 더 받아요',
    emoji: '💠',
    tier: 2,
  ),
  SkillDefinition(
    id: 'skill_rainbow',
    nameKo: '무지개 힘',
    descriptionKo: '모든 미션의 경험치가 꽤 많이 올라가요',
    emoji: '🌈',
    tier: 2,
  ),
  SkillDefinition(
    id: 'skill_double_streak',
    nameKo: '연속 부스터',
    descriptionKo: '매일 연속으로 하면 받는 보너스가 2배!',
    emoji: '⚡',
    tier: 2,
  ),
  SkillDefinition(
    id: 'skill_endurance',
    nameKo: '끈기의 힘',
    descriptionKo: '7일 넘게 연속으로 하면 경험치가 더 올라가요',
    emoji: '💪',
    tier: 2,
  ),
];

// ── 티어 3: Lv25 에서 선택 ─────────────────────────────────────────────────
const tier3Skills = [
  SkillDefinition(
    id: 'skill_exp_share',
    nameKo: '경험치 나눔',
    descriptionKo: '받은 경험치의 일부를 다른 몬스터에게도 나눠줘요',
    emoji: '🔗',
    tier: 3,
  ),
  SkillDefinition(
    id: 'skill_stone_fountain',
    nameKo: '소환석 폭발',
    descriptionKo: '미션을 하면 소환석을 3개나 더 받아요!',
    emoji: '🌊',
    tier: 3,
  ),
  SkillDefinition(
    id: 'skill_master',
    nameKo: '만능 공명',
    descriptionKo: '모든 미션의 경험치가 엄청 많이 올라가요!',
    emoji: '💫',
    tier: 3,
  ),
  SkillDefinition(
    id: 'skill_mega_streak',
    nameKo: '전설의 끈기',
    descriptionKo: '매일 연속으로 하면 받는 보너스가 3배!',
    emoji: '🌟',
    tier: 3,
  ),
  SkillDefinition(
    id: 'skill_perfect_day',
    nameKo: '완벽한 하루',
    descriptionKo: '하루에 미션 3개 이상 하면 특별 보너스 경험치!',
    emoji: '👑',
    tier: 3,
  ),
  SkillDefinition(
    id: 'skill_levelup_gift',
    nameKo: '성장의 선물',
    descriptionKo: '레벨업할 때마다 소환석 5개를 받아요',
    emoji: '🏆',
    tier: 3,
  ),
];

// ── 계보별 고유 스킬 (Lv10 1단계, Lv20 2단계 자동 습득) ────────────────────

class LineageSkillPair {
  final SkillDefinition stage1;
  final SkillDefinition stage2;
  const LineageSkillPair({required this.stage1, required this.stage2});
}

final Map<Lineage, LineageSkillPair> lineageSkillDefinitions = {
  Lineage.dragon: const LineageSkillPair(
    stage1: SkillDefinition(
      id: 'skill_dragon_boost_1',
      nameKo: '도전 불꽃',
      descriptionKo: '도전(🔥) 미션의 경험치가 조금 올라가요',
      emoji: '🔥',
      tier: 0,
    ),
    stage2: SkillDefinition(
      id: 'skill_dragon_boost_2',
      nameKo: '도전 불꽃+',
      descriptionKo: '도전(🔥) 미션의 경험치가 많이 올라가요!',
      emoji: '🔥',
      tier: 0,
    ),
  ),
  Lineage.plant: const LineageSkillPair(
    stage1: SkillDefinition(
      id: 'skill_plant_boost_1',
      nameKo: '독서의 새싹',
      descriptionKo: '독서(🌿) 미션의 경험치가 조금 올라가요',
      emoji: '📚',
      tier: 0,
    ),
    stage2: SkillDefinition(
      id: 'skill_plant_boost_2',
      nameKo: '독서의 새싹+',
      descriptionKo: '독서(🌿) 미션의 경험치가 많이 올라가요!',
      emoji: '📚',
      tier: 0,
    ),
  ),
  Lineage.machine: const LineageSkillPair(
    stage1: SkillDefinition(
      id: 'skill_machine_boost_1',
      nameKo: '집중 회로',
      descriptionKo: '집중(⚡) 미션의 경험치가 조금 올라가요',
      emoji: '⚡',
      tier: 0,
    ),
    stage2: SkillDefinition(
      id: 'skill_machine_boost_2',
      nameKo: '집중 회로+',
      descriptionKo: '집중(⚡) 미션의 경험치가 많이 올라가요!',
      emoji: '⚡',
      tier: 0,
    ),
  ),
  Lineage.fairy: const LineageSkillPair(
    stage1: SkillDefinition(
      id: 'skill_fairy_boost_1',
      nameKo: '생활 마법',
      descriptionKo: '생활(🌙) 미션의 경험치가 조금 올라가요',
      emoji: '🌙',
      tier: 0,
    ),
    stage2: SkillDefinition(
      id: 'skill_fairy_boost_2',
      nameKo: '생활 마법+',
      descriptionKo: '생활(🌙) 미션의 경험치가 많이 올라가요!',
      emoji: '🌙',
      tier: 0,
    ),
  ),
  Lineage.rare: const LineageSkillPair(
    stage1: SkillDefinition(
      id: 'skill_rare_all_boost_1',
      nameKo: '신비의 공명',
      descriptionKo: '모든 미션의 경험치가 조금 올라가요',
      emoji: '✨',
      tier: 0,
    ),
    stage2: SkillDefinition(
      id: 'skill_rare_all_boost_2',
      nameKo: '신비의 공명+',
      descriptionKo: '모든 미션의 경험치가 많이 올라가요!',
      emoji: '✨',
      tier: 0,
    ),
  ),
};

// ── 스킬 선택이 발생하는 레벨 목록 ────────────────────────────────────────
const skillChoiceLevels = [5, 15, 25];

/// 레벨에 해당하는 스킬 티어 반환. 선택 레벨이 아니면 null.
int? tierForLevel(int level) {
  switch (level) {
    case 5:  return 1;
    case 15: return 2;
    case 25: return 3;
    default: return null;
  }
}

/// 주어진 티어에서 선택 가능한 스킬 후보 가져오기 (이미 보유한 것 제외)
List<SkillDefinition> getSkillChoices({
  required int tier,
  required List<String> existingSkillIds,
  required Lineage lineage,
  required int level,
}) {
  List<SkillDefinition> pool;
  switch (tier) {
    case 1:
      pool = [...tier1Skills];
      break;
    case 2:
      pool = [...tier2Skills];
      break;
    case 3:
      pool = [...tier3Skills];
      break;
    default:
      pool = [...tier3Skills]; // fallback
  }

  // 이미 보유한 스킬 제외
  pool = pool.where((s) => !existingSkillIds.contains(s.id)).toList();

  // 풀이 부족하면 다른 티어에서 보충
  if (pool.length < 3) {
    final allPools = [...tier1Skills, ...tier2Skills, ...tier3Skills];
    final extras = allPools
        .where((s) => !existingSkillIds.contains(s.id) && !pool.any((p) => p.id == s.id))
        .toList();
    extras.shuffle();
    pool.addAll(extras.take(3 - pool.length));
  }

  pool.shuffle();
  return pool.take(3).toList();
}

List<SkillDefinition> get allSkillDefinitions => [
  ...tier1Skills,
  ...tier2Skills,
  ...tier3Skills,
  ...lineageSkillDefinitions.values.expand((p) => [p.stage1, p.stage2]),
];

SkillDefinition? getSkillById(String id) {
  try {
    return allSkillDefinitions.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}
