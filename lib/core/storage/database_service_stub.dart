// Web stub — all work is handled in DatabaseService via Hive.
// These functions are never called on web but must exist for compilation.

import '../../data/models/completion_model.dart';

Future<void> initNativeDb() async {}

Future<void> insertCompletion(CompletionModel c) async {}

Future<List<CompletionModel>> getCompletionsForDate(DateTime date) async => [];

Future<List<CompletionModel>> getAllCompletions() async => [];

Future<void> clearAll() async {}
