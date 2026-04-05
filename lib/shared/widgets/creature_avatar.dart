import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/creature_model.dart';
import '../../domain/enums/creature_stage.dart';
import '../../domain/enums/creature_type.dart';

// Conditional import for File
import 'creature_avatar_io.dart'
    if (dart.library.html) 'creature_avatar_web.dart' as platform;

/// 캐릭터 이미지 위젯.
/// 우선순위: AI 생성 로컬 파일 → assets 이미지 → 플레이스홀더
class CreatureAvatar extends StatelessWidget {
  final CreatureModel creature;
  final double size;

  const CreatureAvatar({super.key, required this.creature, this.size = 120});

  String get _assetPath {
    final l = creature.lineage.name;
    final s = creature.stage.name;
    if (creature.stage == CreatureStage.evolved &&
        creature.dominantType != CreatureType.none) {
      return 'assets/creatures/${l}_evolved_${creature.dominantType.name}.png';
    }
    return 'assets/creatures/${l}_$s.png';
  }

  @override
  Widget build(BuildContext context) {
    // ① Base64 이미지 (web + native 공통)
    final b64 = creature.currentImageBase64;
    if (b64 != null && b64.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: Image.memory(
          base64Decode(b64),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(creature: creature, size: size),
        ),
      );
    }

    // ② AI 생성 로컬 파일 (native only, 레거시 호환)
    if (!kIsWeb) {
      final path = creature.currentImagePath;
      final fileWidget = platform.buildFileImage(path, size);
      if (fileWidget != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.15),
          child: fileWidget,
        );
      }
    }

    // ③ assets 이미지 (수동 삽입 시)
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _Placeholder(creature: creature, size: size),
      ),
    );
  }
}

// ── 플레이스홀더 ───────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final CreatureModel creature;
  final double size;

  const _Placeholder({required this.creature, required this.size});

  String get _emoji {
    if (creature.stage == CreatureStage.egg) return '🥚';
    return creature.lineage.emoji;
  }

  Color get _bgColor {
    if (creature.stage == CreatureStage.egg) return const Color(0xFFF5F0E8);
    if (creature.dominantType != CreatureType.none) {
      return creature.dominantType.primaryColor.withValues(alpha: 0.15);
    }
    return creature.lineage.placeholderColor.withValues(alpha: 0.2);
  }

  Color get _borderColor {
    if (creature.dominantType != CreatureType.none) {
      return creature.dominantType.primaryColor.withValues(alpha: 0.5);
    }
    return creature.lineage.placeholderColor.withValues(alpha: 0.6);
  }

  String get _stageLabel => creature.stage.nameKo;

  @override
  Widget build(BuildContext context) {
    final emojiSize = size * 0.45;
    final labelSize = size * 0.12;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_emoji, style: TextStyle(fontSize: emojiSize)),
          if (creature.stage != CreatureStage.egg) ...[
            const SizedBox(height: 2),
            Text(
              _stageLabel,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w700,
                color: _borderColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
