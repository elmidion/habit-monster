import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const _creatureBoxName = 'creature_box';
  static const _missionsBoxName = 'missions_box';
  static const _badgesBoxName = 'badges_box';
  static const _settingsBoxName = 'settings_box';

  static late Box creature;
  static late Box missions;
  static late Box badges;
  static late Box settings;

  static Future<void> init() async {
    creature = await Hive.openBox(_creatureBoxName);
    missions = await Hive.openBox(_missionsBoxName);
    badges = await Hive.openBox(_badgesBoxName);
    settings = await Hive.openBox(_settingsBoxName);
  }
}
