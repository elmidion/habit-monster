import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  await HiveService.init();

  // Initialize SQLite
  await DatabaseService.init();

  // Initialize Korean locale for intl (history screen date formatting)
  await initializeDateFormatting('ko', null);

  runApp(
    const ProviderScope(
      child: HabitMonsterApp(),
    ),
  );
}
