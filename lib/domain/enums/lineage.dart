import 'package:flutter/material.dart';

enum Lineage {
  dragon,
  plant,
  machine,
  fairy,
  rare;

  String get nameKo {
    switch (this) {
      case Lineage.dragon:  return '드래곤';
      case Lineage.plant:   return '식물';
      case Lineage.machine: return '기계';
      case Lineage.fairy:   return '요정';
      case Lineage.rare:    return '신비';
    }
  }

  String get emoji {
    switch (this) {
      case Lineage.dragon:  return '🐉';
      case Lineage.plant:   return '🌿';
      case Lineage.machine: return '⚙️';
      case Lineage.fairy:   return '🧚';
      case Lineage.rare:    return '✨';
    }
  }

  /// 계통 고유의 카테고리 부스트 대상
  String get boostCategory {
    switch (this) {
      case Lineage.dragon:  return 'fire';
      case Lineage.plant:   return 'grass';
      case Lineage.machine: return 'electric';
      case Lineage.fairy:   return 'moon';
      case Lineage.rare:    return 'water';
    }
  }

  /// 플레이스홀더 색상
  Color get placeholderColor {
    switch (this) {
      case Lineage.dragon:  return const Color(0xFFE57373);
      case Lineage.plant:   return const Color(0xFF81C784);
      case Lineage.machine: return const Color(0xFF64B5F6);
      case Lineage.fairy:   return const Color(0xFFBA68C8);
      case Lineage.rare:    return const Color(0xFFFFD54F);
    }
  }

  /// 일반 소환 가중치 (rare 제외, 일반 4종 균등)
  static List<Lineage> get commonPool =>
      [Lineage.dragon, Lineage.plant, Lineage.machine, Lineage.fairy];
}
