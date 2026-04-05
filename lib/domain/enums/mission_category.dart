import 'package:flutter/material.dart';
import 'creature_type.dart';

enum MissionCategory {
  fire,
  water,
  grass,
  electric,
  moon;

  String get nameKo {
    switch (this) {
      case MissionCategory.fire:
        return '도전';
      case MissionCategory.water:
        return '청결';
      case MissionCategory.grass:
        return '독서';
      case MissionCategory.electric:
        return '집중';
      case MissionCategory.moon:
        return '생활';
    }
  }

  String get emoji {
    switch (this) {
      case MissionCategory.fire:
        return '🔥';
      case MissionCategory.water:
        return '💧';
      case MissionCategory.grass:
        return '🌿';
      case MissionCategory.electric:
        return '⚡';
      case MissionCategory.moon:
        return '🌙';
    }
  }

  Color get color {
    return toCreatureType().primaryColor;
  }

  Color get lightColor {
    return toCreatureType().lightColor;
  }

  CreatureType toCreatureType() {
    switch (this) {
      case MissionCategory.fire:
        return CreatureType.fire;
      case MissionCategory.water:
        return CreatureType.water;
      case MissionCategory.grass:
        return CreatureType.grass;
      case MissionCategory.electric:
        return CreatureType.electric;
      case MissionCategory.moon:
        return CreatureType.moon;
    }
  }
}
