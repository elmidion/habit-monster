import 'package:flutter/material.dart';

enum CreatureType {
  none,
  fire,
  water,
  grass,
  electric,
  moon;

  String get nameKo {
    switch (this) {
      case CreatureType.none:
        return '미정';
      case CreatureType.fire:
        return '불꽃';
      case CreatureType.water:
        return '물';
      case CreatureType.grass:
        return '풀';
      case CreatureType.electric:
        return '번개';
      case CreatureType.moon:
        return '달빛';
    }
  }

  String get emoji {
    switch (this) {
      case CreatureType.none:
        return '✨';
      case CreatureType.fire:
        return '🔥';
      case CreatureType.water:
        return '💧';
      case CreatureType.grass:
        return '🌿';
      case CreatureType.electric:
        return '⚡';
      case CreatureType.moon:
        return '🌙';
    }
  }

  Color get primaryColor {
    switch (this) {
      case CreatureType.none:
        return const Color(0xFFB0BEC5);
      case CreatureType.fire:
        return const Color(0xFFFF6B35);
      case CreatureType.water:
        return const Color(0xFF42A5F5);
      case CreatureType.grass:
        return const Color(0xFF66BB6A);
      case CreatureType.electric:
        return const Color(0xFFFFCA28);
      case CreatureType.moon:
        return const Color(0xFF7E57C2);
    }
  }

  Color get lightColor {
    switch (this) {
      case CreatureType.none:
        return const Color(0xFFECEFF1);
      case CreatureType.fire:
        return const Color(0xFFFFE0CC);
      case CreatureType.water:
        return const Color(0xFFBBDEFB);
      case CreatureType.grass:
        return const Color(0xFFC8E6C9);
      case CreatureType.electric:
        return const Color(0xFFFFF9C4);
      case CreatureType.moon:
        return const Color(0xFFEDE7F6);
    }
  }

  Color get darkColor {
    switch (this) {
      case CreatureType.none:
        return const Color(0xFF78909C);
      case CreatureType.fire:
        return const Color(0xFFE64A19);
      case CreatureType.water:
        return const Color(0xFF1565C0);
      case CreatureType.grass:
        return const Color(0xFF2E7D32);
      case CreatureType.electric:
        return const Color(0xFFF57F17);
      case CreatureType.moon:
        return const Color(0xFF4527A0);
    }
  }
}
