import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/database_service.dart';
import '../../core/storage/hive_service.dart';
import '../../core/utils/app_clock.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/completion_model.dart';
import '../../data/models/creature_model.dart';
import '../../data/models/mission_model.dart';
import '../../domain/enums/creature_stage.dart';
import '../../domain/enums/creature_type.dart';
import '../../domain/definitions/skill_definitions.dart';
import '../../domain/enums/lineage.dart';
import '../../domain/logic/badge_logic.dart';
import '../../domain/logic/exp_logic.dart';
import '../../domain/logic/skill_effect_logic.dart';
import '../../domain/logic/streak_logic.dart';
import '../../domain/logic/summon_logic.dart';
import 'coin_provider.dart';
import 'completions_provider.dart';
import 'summon_provider.dart';

const _uuid = Uuid();
const _collectionKey = 'collection';
const _activeIdKey = 'active_creature_id';
const int maxSlots = 30;

// ── Collection ──────────────────────────────────────────────────────────────
final collectionProvider =
    AsyncNotifierProvider<CollectionNotifier, List<CreatureModel>>(
  CollectionNotifier.new,
);

// ── Active creature ID ───────────────────────────────────────────────────────
final activeCreatureIdProvider = StateProvider<String?>((ref) {
  return HiveService.settings.get(_activeIdKey) as String?;
});

// ── Active creature (derived) ────────────────────────────────────────────────
final activeCreatureProvider = Provider<CreatureModel?>((ref) {
  final list = ref.watch(collectionProvider).valueOrNull ?? [];
  final id = ref.watch(activeCreatureIdProvider);
  if (list.isEmpty) return null;
  if (id == null) return list.firstWhere((c) => c.stage.isHatched, orElse: () => list.first);
  try {
    return list.firstWhere((c) => c.id == id);
  } catch (_) {
    return list.firstWhere((c) => c.stage.isHatched, orElse: () => list.first);
  }
});

// ── Badges ───────────────────────────────────────────────────────────────────
final badgesProvider =
    AsyncNotifierProvider<BadgesNotifier, List<BadgeRecord>>(
  BadgesNotifier.new,
);

// ── Result returned after completing a mission ───────────────────────────────
class CompletionResult {
  final int expGained;
  final int streakBonus;
  final bool didLevelUp;
  final int newLevel;
  final bool didEvolve;
  final bool didStageUp;   // baby→adult (Lv10), not a full evolution
  final List<int> pendingSkillTiers;
  final List<String> newBadgeIds;
  final bool isFirstHatch;
  final int stonesEarned;

  const CompletionResult({
    required this.expGained,
    required this.streakBonus,
    required this.didLevelUp,
    required this.newLevel,
    required this.didEvolve,
    this.didStageUp = false,
    this.pendingSkillTiers = const [],
    required this.newBadgeIds,
    this.isFirstHatch = false,
    this.stonesEarned = 0,
  });

  bool get hasEvents =>
      didLevelUp || didEvolve || didStageUp ||
      pendingSkillTiers.isNotEmpty || newBadgeIds.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
class CollectionNotifier extends AsyncNotifier<List<CreatureModel>> {
  @override
  Future<List<CreatureModel>> build() async {
    final raw = HiveService.creature.get(_collectionKey);
    if (raw == null) {
      // 첫 실행: 랜덤 계통 알 1개 자동 생성
      final egg = CreatureModel.newEgg(
        id: _uuid.v4(),
        lineage: Lineage.dragon,
      );
      await _persist([egg]);
      return [egg];
    }
    final list = raw as List;
    return list
        .map((e) => CreatureModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist(List<CreatureModel> list) async {
    await HiveService.creature
        .put(_collectionKey, list.map((c) => c.toJson()).toList());
  }

  List<CreatureModel> get _current => state.valueOrNull ?? [];

  void _updateState(List<CreatureModel> updated) {
    state = AsyncValue.data(updated);
    _persist(updated);
  }

  void _updateOne(CreatureModel creature) {
    final updated = _current.map((c) => c.id == creature.id ? creature : c).toList();
    _updateState(updated);
  }

  // ── 알 부화 ────────────────────────────────────────────────────────────────
  Future<CompletionResult> hatch(
    String creatureId,
    String name, {
    Map<String, String> stageImagePaths = const {},
    Map<String, String> stageImageData = const {},
  }) async {
    final list = _current;
    final idx = list.indexWhere((c) => c.id == creatureId);
    if (idx < 0) throw StateError('creature not found: $creatureId');

    final hatched = list[idx].copyWith(
      name: name,
      stage: CreatureStage.baby,
      hatchedAt: AppClock.now(),
      stageImagePaths: stageImagePaths,
      stageImageData: stageImageData,
    );
    _updateOne(hatched);

    // 첫 부화 시 활성 설정
    final activeId = ref.read(activeCreatureIdProvider);
    if (activeId == null) _setActiveId(hatched.id);

    final allCompletions = await DatabaseService.getAllCompletions();
    final totalHatched = _current.where((c) => c.stage.isHatched).length;
    final newBadgeIds = await ref.read(badgesProvider.notifier).detect(
      creature: hatched,
      isFirstHatch: true,
      isComebackDay: false,
      justEvolved: false,
      todayCompletions: [],
      allCompletions: allCompletions,
      streakResult: const StreakResult(currentStreak: 0, longestStreak: 0, isComebackDay: false),
      totalHatched: totalHatched,
    );

    return CompletionResult(
      expGained: 0, streakBonus: 0,
      didLevelUp: false, newLevel: hatched.level,
      didEvolve: false,
      newBadgeIds: newBadgeIds,
      isFirstHatch: true,
    );
  }

  // ── 미션 완료 ───────────────────────────────────────────────────────────────
  Future<CompletionResult> completeMission(MissionModel mission) async {
    final activeId = ref.read(activeCreatureIdProvider);
    final list = _current;
    final creature = list.firstWhere(
      (c) => c.id == activeId,
      orElse: () => list.firstWhere((c) => c.stage.isHatched),
    );

    // ① 스트릭 / 활성 날짜
    final allCompletions = await DatabaseService.getAllCompletions();
    final activeDates = allCompletions
        .map((c) => DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day))
        .toSet().toList();
    final streakResult = StreakLogic.compute(activeDates);

    // ② 오늘 미션 완료 횟수 (콤보/첫미션 스킬용)
    final todayComps = await DatabaseService.getCompletionsForDate(AppClock.now());
    final todayCompletionCount = todayComps.length;

    // ② 스킬 EXP 배율 적용
    final multiplier = SkillEffectLogic.expMultiplier(
      skillIds: creature.skillIds,
      lineage: creature.lineage,
      category: mission.category,
      creatureLevel: creature.level,
      currentStreak: streakResult.currentStreak,
      todayCompletionCount: todayCompletionCount,
    );
    final firstMissionMult = SkillEffectLogic.firstMissionMultiplier(
      creature.skillIds, todayCompletionCount,
    );
    final baseExp = mission.expReward;
    final streakBonus = (ExpLogic.streakBonusExp(streakResult.currentStreak)
        * SkillEffectLogic.streakBonusMultiplier(creature.skillIds)).round();
    final totalExp = ((baseExp * firstMissionMult + streakBonus) * multiplier).round();

    // ③ 소환석 획득
    final baseStones = 1;
    final bonusStones = SkillEffectLogic.bonusStones(creature.skillIds);
    final stonesEarned = baseStones + bonusStones;
    await ref.read(summonStonesProvider.notifier).add(stonesEarned);

    // ③-b 코인 적립
    final coinPerMission = ref.read(coinPerMissionProvider);
    await ref.read(coinBalanceProvider.notifier).add(coinPerMission);

    // ④ 완료 기록 삽입
    final completion = CompletionModel(
      id: _uuid.v4(),
      missionId: mission.id,
      completedAt: AppClock.now(),
      category: mission.category,
      expAwarded: totalExp,
      wasStreakBonus: streakBonus > 0,
    );
    await DatabaseService.insertCompletion(completion);

    // ⑤ 신규 활성 날짜 여부
    final today = AppClock.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final isNewDay = !activeDates.contains(todayNorm);

    // ⑥ EXP 적용 + 레벨업
    final levelResult = ExpLogic.applyExp(
      currentLevel: creature.level,
      currentExp: creature.currentExp,
      expGained: totalExp,
      existingSkillIds: creature.skillIds,
    );

    // ⑦ 단계 업그레이드 판정
    final prevStage = creature.stage;
    CreatureStage newStage = prevStage;
    if (levelResult.newLevel >= 20 && prevStage != CreatureStage.evolved) {
      newStage = CreatureStage.evolved;
    } else if (levelResult.newLevel >= 10 && prevStage == CreatureStage.baby) {
      newStage = CreatureStage.adult;
    }
    final didEvolve = newStage == CreatureStage.evolved && prevStage != CreatureStage.evolved;
    final didStageUp = newStage != prevStage && !didEvolve;

    // ⑧ 카테고리 카운트 + 도미넌트 타입
    final catCounts = Map<String, int>.from(creature.categoryCompletionCount);
    catCounts[mission.category.name] = (catCounts[mission.category.name] ?? 0) + 1;
    final dominantType = _computeDominantType(catCounts);

    final updatedCompletions = [...allCompletions, completion];

    // ⑩ 스킬 선택 대기 + 계보 스킬 자동 습득
    final pendingTiers = [
      ...creature.pendingSkillTiers,
      ...levelResult.pendingSkillTiers,
    ];
    final autoSkills = <String>[];
    final pair = lineageSkillDefinitions[creature.lineage];
    if (pair != null) {
      // Lv10: 계보 스킬 1단계
      if (levelResult.newLevel >= 10 &&
          !creature.skillIds.contains(pair.stage1.id)) {
        autoSkills.add(pair.stage1.id);
      }
      // Lv20: 계보 스킬 2단계
      if (levelResult.newLevel >= 20 &&
          !creature.skillIds.contains(pair.stage2.id)) {
        autoSkills.add(pair.stage2.id);
      }
    }

    // ⑪ 레벨업 시 소환석 보너스 (스킬 효과)
    final levelUpStones = levelResult.didLevelUp
        ? SkillEffectLogic.levelUpStoneBonus(creature.skillIds)
        : 0;
    if (levelUpStones > 0) {
      await ref.read(summonStonesProvider.notifier).add(levelUpStones);
    }

    // 완벽한 하루 보너스
    final perfectBonus = SkillEffectLogic.perfectDayBonus(
      creature.skillIds, todayCompletionCount,
    );

    // ⑫ 활성 캐릭터 업데이트
    final updatedCreature = creature.copyWith(
      level: levelResult.newLevel,
      currentExp: levelResult.newCurrentExp + perfectBonus,
      totalExpEarned: creature.totalExpEarned + totalExp + perfectBonus,
      totalDaysActive: creature.totalDaysActive + (isNewDay ? 1 : 0),
      stage: newStage,
      evolvedAt: didEvolve ? AppClock.now() : creature.evolvedAt,
      skillIds: [...creature.skillIds, ...autoSkills],
      categoryCompletionCount: catCounts,
      dominantType: dominantType,
      pendingSkillTiers: pendingTiers,
    );
    _updateOne(updatedCreature);

    // ⑫ EXP 나눔 스킬: 다른 캐릭터에게 분배
    final shareRatio = SkillEffectLogic.expShareRatio(creature.skillIds);
    if (shareRatio > 0) {
      final shareExp = (totalExp * shareRatio).round();
      if (shareExp > 0) {
        final others = _current.where((c) => c.id != updatedCreature.id && c.stage.isHatched);
        for (final other in others) {
          final otherResult = ExpLogic.applyExp(
            currentLevel: other.level,
            currentExp: other.currentExp,
            expGained: shareExp,
            existingSkillIds: other.skillIds,
          );
          _updateOne(other.copyWith(
            level: otherResult.newLevel,
            currentExp: otherResult.newCurrentExp,
            totalExpEarned: other.totalExpEarned + shareExp,
          ));
        }
      }
    }

    // ⑬ 뱃지 감지
    final totalHatched = _current.where((c) => c.stage.isHatched).length;
    final newBadgeIds = await ref.read(badgesProvider.notifier).detect(
      creature: updatedCreature,
      isFirstHatch: false,
      isComebackDay: streakResult.isComebackDay,
      justEvolved: didEvolve,
      todayCompletions: [completion],
      allCompletions: updatedCompletions,
      streakResult: streakResult,
      totalHatched: totalHatched,
    );

    // ⑭ 스트릭 보상 소환석
    final streakStones = SummonLogic.streakStoneReward(streakResult.currentStreak);
    if (streakStones > 0) {
      await ref.read(summonStonesProvider.notifier).add(streakStones);
    }

    // ⑮ 프로바이더 갱신
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(todayCompletedIdsProvider);
    ref.invalidate(allCompletionsProvider);
    ref.invalidate(streakProvider);

    return CompletionResult(
      expGained: totalExp,
      streakBonus: streakBonus,
      didLevelUp: levelResult.didLevelUp,
      newLevel: levelResult.newLevel,
      didEvolve: didEvolve,
      didStageUp: didStageUp,
      pendingSkillTiers: pendingTiers,
      newBadgeIds: newBadgeIds,
      stonesEarned: stonesEarned + streakStones + levelUpStones,
    );
  }

  // ── 활성 캐릭터 변경 ────────────────────────────────────────────────────────
  void setActive(String id) {
    _setActiveId(id);
    ref.read(activeCreatureIdProvider.notifier).state = id;
  }

  void _setActiveId(String id) {
    HiveService.settings.put(_activeIdKey, id);
  }

  // ── 즐겨찾기 토글 ──────────────────────────────────────────────────────────
  void toggleFavorite(String id) {
    final creature = _current.firstWhere((c) => c.id == id);
    _updateOne(creature.copyWith(isFavorite: !creature.isFavorite));
  }

  // ── 이름 변경 ──────────────────────────────────────────────────────────────
  Future<void> rename(String id, String name) async {
    final creature = _current.firstWhere((c) => c.id == id);
    _updateOne(creature.copyWith(name: name));
  }

  // ── 놓아주기 ───────────────────────────────────────────────────────────────
  /// isFavorite이면 null 반환 (실패). 성공 시 획득 소환석 수 반환.
  Future<int?> release(String id) async {
    final creature = _current.firstWhere((c) => c.id == id);
    if (creature.isFavorite) return null;

    final stones = SummonLogic.releaseReward(creature.level);
    await ref.read(summonStonesProvider.notifier).add(stones);

    final updated = _current.where((c) => c.id != id).toList();
    _updateState(updated);

    // 놓아준 것이 활성이었다면 다른 캐릭터로 전환
    final activeId = ref.read(activeCreatureIdProvider);
    if (activeId == id) {
      final next = updated.firstWhere((c) => c.stage.isHatched, orElse: () => updated.first);
      setActive(next.id);
    }

    // 놓아주기 뱃지 감지
    final newActive = updated.firstWhere(
      (c) => c.id == ref.read(activeCreatureIdProvider),
      orElse: () => creature,
    );
    final allCompletions = await DatabaseService.getAllCompletions();
    await ref.read(badgesProvider.notifier).detect(
      creature: newActive,
      isFirstHatch: false,
      isComebackDay: false,
      justEvolved: false,
      todayCompletions: [],
      allCompletions: allCompletions,
      streakResult: const StreakResult(currentStreak: 0, longestStreak: 0, isComebackDay: false),
      totalHatched: updated.where((c) => c.stage.isHatched).length,
      justReleased: true,
    );

    return stones;
  }

  // ── 소환으로 알 추가 ────────────────────────────────────────────────────────
  Future<CreatureModel?> addEgg(Lineage lineage) async {
    final list = _current;
    if (list.length >= maxSlots) return null; // 슬롯 꽉 참

    final egg = CreatureModel.newEgg(id: _uuid.v4(), lineage: lineage);
    _updateState([...list, egg]);
    return egg;
  }

  // ── Debug: EXP 직접 주입 ────────────────────────────────────────────────────
  Future<CompletionResult> debugAddExp(int exp) async {
    final activeId = ref.read(activeCreatureIdProvider);
    final creature = _current.firstWhere(
      (c) => c.id == activeId,
      orElse: () => _current.firstWhere((c) => c.stage.isHatched),
    );

    final levelResult = ExpLogic.applyExp(
      currentLevel: creature.level,
      currentExp: creature.currentExp,
      expGained: exp,
      existingSkillIds: creature.skillIds,
    );

    CreatureStage newStage = creature.stage;
    if (levelResult.newLevel >= 20 && creature.stage != CreatureStage.evolved) {
      newStage = CreatureStage.evolved;
    } else if (levelResult.newLevel >= 10 && creature.stage == CreatureStage.baby) {
      newStage = CreatureStage.adult;
    }
    final didEvolve = newStage == CreatureStage.evolved && creature.stage != CreatureStage.evolved;

    final pendingTiers = [
      ...creature.pendingSkillTiers,
      ...levelResult.pendingSkillTiers,
    ];
    final debugAutoSkills = <String>[];
    final debugPair = lineageSkillDefinitions[creature.lineage];
    if (debugPair != null) {
      if (levelResult.newLevel >= 10 &&
          !creature.skillIds.contains(debugPair.stage1.id)) {
        debugAutoSkills.add(debugPair.stage1.id);
      }
      if (levelResult.newLevel >= 20 &&
          !creature.skillIds.contains(debugPair.stage2.id)) {
        debugAutoSkills.add(debugPair.stage2.id);
      }
    }

    final updated = creature.copyWith(
      level: levelResult.newLevel,
      currentExp: levelResult.newCurrentExp,
      totalExpEarned: creature.totalExpEarned + exp,
      stage: newStage,
      evolvedAt: didEvolve ? AppClock.now() : creature.evolvedAt,
      skillIds: [...creature.skillIds, ...debugAutoSkills],
      pendingSkillTiers: pendingTiers,
    );
    _updateOne(updated);

    return CompletionResult(
      expGained: exp, streakBonus: 0,
      didLevelUp: levelResult.didLevelUp,
      newLevel: levelResult.newLevel,
      didEvolve: didEvolve,
      pendingSkillTiers: pendingTiers,
      newBadgeIds: [],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  CreatureType _computeDominantType(Map<String, int> counts) {
    if (counts.isEmpty) return CreatureType.none;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    try {
      return CreatureType.values.firstWhere((t) => t.name == top.key);
    } catch (_) {
      return CreatureType.none;
    }
  }

  // ── 스킬 선택 확정 ──────────────────────────────────────────────────────────
  void confirmSkillSelection(String creatureId, String skillId) {
    final creature = _current.firstWhere((c) => c.id == creatureId);
    final remaining = List<int>.from(creature.pendingSkillTiers)..removeAt(0);
    _updateOne(creature.copyWith(
      skillIds: [...creature.skillIds, skillId],
      pendingSkillTiers: remaining,
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class BadgesNotifier extends AsyncNotifier<List<BadgeRecord>> {
  static const _key = 'list';

  @override
  Future<List<BadgeRecord>> build() async {
    final raw = HiveService.badges.get(_key);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => BadgeRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist(List<BadgeRecord> badges) async {
    await HiveService.badges.put(_key, badges.map((b) => b.toJson()).toList());
  }

  Future<List<String>> detect({
    required CreatureModel creature,
    required bool isFirstHatch,
    required bool isComebackDay,
    required bool justEvolved,
    required List<CompletionModel> todayCompletions,
    required List<CompletionModel> allCompletions,
    required StreakResult streakResult,
    int totalHatched = 0,
    bool justReleased = false,
  }) async {
    final existing = state.valueOrNull ?? [];
    final existingIds = existing.map((b) => b.badgeId).toList();

    final newIds = BadgeLogic.detectNewBadges(
      existingBadgeIds: existingIds,
      level: creature.level,
      totalDaysActive: creature.totalDaysActive,
      currentStreak: streakResult.currentStreak,
      isFirstHatch: isFirstHatch,
      isComebackDay: isComebackDay,
      justEvolved: justEvolved,
      todayCompletions: todayCompletions,
      allCompletions: allCompletions,
      totalHatched: totalHatched,
      justReleased: justReleased,
    );

    if (newIds.isNotEmpty) {
      final newRecords = newIds
          .map((id) => BadgeRecord(badgeId: id, earnedAt: AppClock.now()))
          .toList();
      final updated = [...existing, ...newRecords];
      await _persist(updated);
      state = AsyncValue.data(updated);

      // 뱃지 획득 소환석 지급
      final stoneReward = newIds
          .map((id) => getBadgeById(id)?.stoneReward ?? 0)
          .fold(0, (sum, v) => sum + v);
      if (stoneReward > 0) {
        await ref.read(summonStonesProvider.notifier).add(stoneReward);
      }
    }
    return newIds;
  }
}
