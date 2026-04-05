import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import '../../data/models/creature_model.dart';
import '../../data/providers/collection_provider.dart';
import '../../domain/enums/lineage.dart';
import '../../domain/logic/summon_logic.dart';

const _stonesKey = 'summon_stones';

// ── 소환석 ────────────────────────────────────────────────────────────────────
final summonStonesProvider =
    NotifierProvider<SummonStonesNotifier, int>(SummonStonesNotifier.new);

class SummonStonesNotifier extends Notifier<int> {
  @override
  int build() {
    return HiveService.settings.get(_stonesKey, defaultValue: 0) as int;
  }

  Future<void> add(int amount) async {
    state = state + amount;
    await HiveService.settings.put(_stonesKey, state);
  }

  Future<bool> spend(int amount) async {
    if (state < amount) return false;
    state = state - amount;
    await HiveService.settings.put(_stonesKey, state);
    return true;
  }
}

// ── 소환 결과 ─────────────────────────────────────────────────────────────────
class SummonResult {
  final CreatureModel egg;
  final bool isRare;

  const SummonResult({required this.egg, required this.isRare});
}

// ── 소환 액션 ─────────────────────────────────────────────────────────────────
final summonProvider = Provider((ref) => _Summoner(ref));

class _Summoner {
  final Ref _ref;
  const _Summoner(this._ref);

  /// 10석 소비해 알 1개 소환. 슬롯 부족 또는 석 부족 시 null 반환.
  Future<SummonResult?> summon() async {
    final collection = _ref.read(collectionProvider).valueOrNull ?? [];
    if (collection.length >= maxSlots) return null;

    final spent = await _ref.read(summonStonesProvider.notifier).spend(SummonLogic.stoneCost);
    if (!spent) return null;

    final lineage = SummonLogic.roll();
    final egg = await _ref.read(collectionProvider.notifier).addEgg(lineage);
    if (egg == null) {
      // 슬롯 부족 — 환불
      await _ref.read(summonStonesProvider.notifier).add(SummonLogic.stoneCost);
      return null;
    }

    return SummonResult(egg: egg, isRare: lineage == Lineage.rare);
  }
}
