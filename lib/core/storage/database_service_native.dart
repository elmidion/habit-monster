import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/models/completion_model.dart';

Database? _db;

Database get _database {
  assert(_db != null, 'DatabaseService.init() must be called first');
  return _db!;
}

Future<void> initNativeDb() async {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dbPath = await getDatabasesPath();
  _db = await openDatabase(
    '$dbPath/habit_monster.db',
    version: 1,
    onCreate: (db, version) => db.execute('''
      CREATE TABLE completions (
        id           TEXT PRIMARY KEY,
        mission_id   TEXT    NOT NULL,
        completed_at INTEGER NOT NULL,
        category     TEXT    NOT NULL,
        exp_awarded  INTEGER NOT NULL DEFAULT 0,
        streak_bonus INTEGER NOT NULL DEFAULT 0
      )
    '''),
  );
}

Future<void> insertCompletion(CompletionModel c) async {
  await _database.insert(
    'completions',
    c.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<CompletionModel>> getCompletionsForDate(DateTime date) async {
  final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;
  final rows = await _database.query(
    'completions',
    where: 'completed_at BETWEEN ? AND ?',
    whereArgs: [start, end],
    orderBy: 'completed_at ASC',
  );
  return rows.map(CompletionModel.fromMap).toList();
}

Future<List<CompletionModel>> getAllCompletions() async {
  final rows = await _database.query('completions', orderBy: 'completed_at ASC');
  return rows.map(CompletionModel.fromMap).toList();
}

Future<void> clearAll() async {
  await _database.delete('completions');
}
