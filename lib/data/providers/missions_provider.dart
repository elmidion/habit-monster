import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/hive_service.dart';
import '../../data/models/mission_model.dart';
import '../../domain/enums/mission_category.dart';

final _uuid = const Uuid();

final missionsProvider =
    AsyncNotifierProvider<MissionsNotifier, List<MissionModel>>(
  MissionsNotifier.new,
);

class MissionsNotifier extends AsyncNotifier<List<MissionModel>> {
  static const _key = 'list';

  @override
  Future<List<MissionModel>> build() async {
    final raw = HiveService.missions.get(_key);
    if (raw == null) {
      // First launch — seed defaults
      final defaults = defaultMissions;
      await _persist(defaults);
      return defaults;
    }
    final list = raw as List;
    return list
        .map((e) => MissionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist(List<MissionModel> missions) async {
    await HiveService.missions.put(_key, missions.map((m) => m.toJson()).toList());
  }

  Future<void> addMission({
    required String title,
    required MissionCategory category,
    required int expReward,
    String? iconEmoji,
    String? parentNote,
  }) async {
    final current = state.valueOrNull ?? [];
    final mission = MissionModel(
      id: _uuid.v4(),
      title: title,
      category: category,
      expReward: expReward,
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
      iconEmoji: iconEmoji,
      parentNote: parentNote,
    );
    final updated = [...current, mission];
    await _persist(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> setActive(String id, {required bool active}) async {
    final current = state.valueOrNull ?? [];
    final updated = current
        .map((m) => m.id == id ? m.copyWith(isActive: active) : m)
        .toList();
    await _persist(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((m) => m.id != id).toList();
    await _persist(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateMission(MissionModel updated) async {
    final current = state.valueOrNull ?? [];
    final list =
        current.map((m) => m.id == updated.id ? updated : m).toList();
    await _persist(list);
    state = AsyncValue.data(list);
  }

  List<MissionModel> get activeMissions =>
      (state.valueOrNull ?? []).where((m) => m.isActive).toList();
}
