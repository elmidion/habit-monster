class BadgeRecord {
  final String badgeId;
  final DateTime earnedAt;
  final String? parentComment;

  const BadgeRecord({
    required this.badgeId,
    required this.earnedAt,
    this.parentComment,
  });

  Map<String, dynamic> toJson() => {
    'badgeId': badgeId,
    'earnedAt': earnedAt.toIso8601String(),
    'parentComment': parentComment,
  };

  factory BadgeRecord.fromJson(Map<String, dynamic> json) {
    return BadgeRecord(
      badgeId: json['badgeId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      parentComment: json['parentComment'] as String?,
    );
  }
}

enum BadgeRarity {
  common,   // 3석
  rare,     // 8석
  legendary; // 20석

  int get stoneReward {
    switch (this) {
      case BadgeRarity.common:    return 3;
      case BadgeRarity.rare:      return 8;
      case BadgeRarity.legendary: return 20;
    }
  }

  String get label {
    switch (this) {
      case BadgeRarity.common:    return 'COMMON';
      case BadgeRarity.rare:      return 'RARE';
      case BadgeRarity.legendary: return 'LEGENDARY';
    }
  }
}

class BadgeDefinition {
  final String id;
  final String nameKo;
  final String descriptionKo;
  final String emoji;
  final BadgeRarity rarity;

  const BadgeDefinition({
    required this.id,
    required this.nameKo,
    required this.descriptionKo,
    required this.emoji,
    required this.rarity,
  });

  int get stoneReward => rarity.stoneReward;
}

final List<BadgeDefinition> allBadgeDefinitions = [
  // ── 첫 발걸음 ──────────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'first_hatch',
    nameKo: '첫 부화!',
    descriptionKo: '알에서 처음으로 부화했어요',
    emoji: '🥚',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'evolved',
    nameKo: '진화 완성!',
    descriptionKo: '캐릭터가 진화했어요!',
    emoji: '✨',
    rarity: BadgeRarity.legendary,
  ),
  const BadgeDefinition(
    id: 'comeback',
    nameKo: '다시 시작!',
    descriptionKo: '쉬었다가 다시 도전했어요',
    emoji: '💪',
    rarity: BadgeRarity.common,
  ),

  // ── 스트릭 ─────────────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'streak_3',
    nameKo: '3일 연속!',
    descriptionKo: '3일 연속으로 미션을 완료했어요',
    emoji: '🔥',
    rarity: BadgeRarity.common,
  ),
  const BadgeDefinition(
    id: 'streak_7',
    nameKo: '일주일 연속!',
    descriptionKo: '7일 연속으로 미션을 완료했어요',
    emoji: '🌟',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'streak_14',
    nameKo: '2주 연속!',
    descriptionKo: '14일 연속으로 미션을 완료했어요',
    emoji: '⭐',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'streak_30',
    nameKo: '한 달 연속!',
    descriptionKo: '30일 연속으로 미션을 완료했어요',
    emoji: '🏆',
    rarity: BadgeRarity.legendary,
  ),
  const BadgeDefinition(
    id: 'streak_60',
    nameKo: '두 달 연속!',
    descriptionKo: '60일 연속으로 미션을 완료했어요. 전설이에요!',
    emoji: '👑',
    rarity: BadgeRarity.legendary,
  ),
  const BadgeDefinition(
    id: 'streak_100',
    nameKo: '100일 연속!',
    descriptionKo: '100일 연속 달성! 믿을 수 없어요!',
    emoji: '💎',
    rarity: BadgeRarity.legendary,
  ),

  // ── 레벨 ───────────────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'level_5',
    nameKo: 'Lv.5 달성!',
    descriptionKo: '레벨 5에 도달했어요',
    emoji: '🎯',
    rarity: BadgeRarity.common,
  ),
  const BadgeDefinition(
    id: 'level_10',
    nameKo: 'Lv.10 달성!',
    descriptionKo: '성체가 됐어요! 레벨 10 달성',
    emoji: '🎖️',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'level_15',
    nameKo: 'Lv.15 달성!',
    descriptionKo: '레벨 15에 도달했어요',
    emoji: '🏅',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'level_20',
    nameKo: 'Lv.20 진화!',
    descriptionKo: '레벨 20, 진화 달성!',
    emoji: '🌈',
    rarity: BadgeRarity.legendary,
  ),
  const BadgeDefinition(
    id: 'level_30',
    nameKo: 'Lv.30 마스터!',
    descriptionKo: '레벨 30에 도달했어요',
    emoji: '🦋',
    rarity: BadgeRarity.legendary,
  ),
  const BadgeDefinition(
    id: 'level_50',
    nameKo: 'Lv.50 전설!',
    descriptionKo: '레벨 50 달성! 당신은 전설이에요',
    emoji: '🌠',
    rarity: BadgeRarity.legendary,
  ),

  // ── 미션 누적 ──────────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'missions_10',
    nameKo: '미션 10회!',
    descriptionKo: '미션을 총 10회 완료했어요',
    emoji: '📋',
    rarity: BadgeRarity.common,
  ),
  const BadgeDefinition(
    id: 'missions_50',
    nameKo: '미션 50회!',
    descriptionKo: '미션을 총 50회 완료했어요',
    emoji: '📚',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'missions_100',
    nameKo: '미션 100회!',
    descriptionKo: '미션을 총 100회 완료했어요',
    emoji: '💯',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'missions_300',
    nameKo: '미션 300회!',
    descriptionKo: '미션을 총 300회 완료했어요',
    emoji: '🎪',
    rarity: BadgeRarity.legendary,
  ),
  const BadgeDefinition(
    id: 'missions_500',
    nameKo: '미션 500회!',
    descriptionKo: '미션을 총 500회 완료했어요. 엄청나요!',
    emoji: '🚀',
    rarity: BadgeRarity.legendary,
  ),

  // ── 카테고리 전문가 ────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'fire_master',
    nameKo: '도전왕!',
    descriptionKo: '도전 미션을 30회 완료했어요',
    emoji: '🔥',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'water_master',
    nameKo: '청결왕!',
    descriptionKo: '청결 미션을 30회 완료했어요',
    emoji: '💧',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'grass_master',
    nameKo: '독서왕!',
    descriptionKo: '독서 미션을 30회 완료했어요',
    emoji: '📖',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'electric_master',
    nameKo: '집중왕!',
    descriptionKo: '집중 미션을 30회 완료했어요',
    emoji: '⚡',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'moon_master',
    nameKo: '생활왕!',
    descriptionKo: '생활 미션을 30회 완료했어요',
    emoji: '🌙',
    rarity: BadgeRarity.rare,
  ),

  // ── 컬렉션 ─────────────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'collector_3',
    nameKo: '수집 시작!',
    descriptionKo: '캐릭터를 3마리 부화시켰어요',
    emoji: '🐣',
    rarity: BadgeRarity.common,
  ),
  const BadgeDefinition(
    id: 'collector_5',
    nameKo: '몬스터 박사!',
    descriptionKo: '캐릭터를 5마리 부화시켰어요',
    emoji: '🎒',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'first_release',
    nameKo: '자연으로!',
    descriptionKo: '처음으로 캐릭터를 자연으로 돌려보냈어요',
    emoji: '🌿',
    rarity: BadgeRarity.common,
  ),

  // ── 하루 완성 ──────────────────────────────────────────────────────────────
  const BadgeDefinition(
    id: 'all_types',
    nameKo: '만능 탐험가!',
    descriptionKo: '하루에 모든 종류의 미션을 완료했어요',
    emoji: '🌈',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'total_30',
    nameKo: '30일 달성!',
    descriptionKo: '총 30일 동안 미션을 완료했어요',
    emoji: '📅',
    rarity: BadgeRarity.rare,
  ),
  const BadgeDefinition(
    id: 'total_100',
    nameKo: '100일의 기록!',
    descriptionKo: '총 100일 동안 미션을 완료했어요',
    emoji: '🗓️',
    rarity: BadgeRarity.legendary,
  ),
];

BadgeDefinition? getBadgeById(String id) {
  try {
    return allBadgeDefinitions.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}
