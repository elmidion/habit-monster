import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/app_clock.dart';
import '../../data/models/completion_model.dart';

// Conditional import: sqflite only on non-web
import 'database_service_native.dart'
    if (dart.library.html) 'database_service_stub.dart' as native;

class DatabaseService {
  static late final bool _isWeb;
  static Box? _hiveBox;

  static Future<void> init() async {
    _isWeb = kIsWeb;
    if (_isWeb) {
      _hiveBox = await Hive.openBox('completions_box');
    } else {
      await native.initNativeDb();
    }
  }

  static Future<void> insertCompletion(CompletionModel c) async {
    if (_isWeb) {
      final list = _getHiveList();
      list.add(c.toMap());
      await _hiveBox!.put('list', list);
    } else {
      await native.insertCompletion(c);
    }
  }

  static Future<List<CompletionModel>> getCompletionsForDate(DateTime date) async {
    if (_isWeb) {
      final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;
      return _getAll().where((c) {
        final ms = c.completedAt.millisecondsSinceEpoch;
        return ms >= start && ms <= end;
      }).toList();
    }
    return native.getCompletionsForDate(date);
  }

  static Future<List<CompletionModel>> getAllCompletions() async {
    if (_isWeb) return _getAll();
    return native.getAllCompletions();
  }

  static Future<List<DateTime>> getActiveDates() async {
    final all = await getAllCompletions();
    return all
        .map((c) => DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day))
        .toSet()
        .toList()
      ..sort();
  }

  static Future<bool> isCompletedToday(String missionId) async {
    final today = AppClock.now();
    final comps = await getCompletionsForDate(today);
    return comps.any((c) => c.missionId == missionId);
  }

  // ── Hive helpers ──────────────────────────────────────────────────────────
  static List<Map> _getHiveList() {
    final raw = _hiveBox!.get('list');
    if (raw == null) return [];
    return List<Map>.from(raw as List);
  }

  static List<CompletionModel> _getAll() {
    return _getHiveList()
        .map((e) => CompletionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }

  // ── 백업/복원용 ────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> exportAll() async {
    final all = await getAllCompletions();
    return all.map((c) => c.toMap()).toList();
  }

  static Future<void> importAll(List<Map<String, dynamic>> data) async {
    for (final map in data) {
      await insertCompletion(CompletionModel.fromMap(map));
    }
  }

  static Future<void> clearAll() async {
    if (_isWeb) {
      await _hiveBox!.put('list', []);
    } else {
      await native.clearAll();
    }
  }
}
