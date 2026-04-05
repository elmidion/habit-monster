import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Conditional import for file I/O
import 'image_gen_io.dart'
    if (dart.library.html) 'image_gen_stub.dart' as file_io;

import '../../domain/enums/creature_stage.dart';
import '../../domain/enums/lineage.dart';
import '../storage/hive_service.dart';

/// 이미지 생성 결과: 파일 경로 (native) + Base64 데이터 (web/native 공통)
class ImageGenResult {
  final Map<String, String> paths;  // stage → file path (native only)
  final Map<String, String> data;   // stage → base64 string

  const ImageGenResult({this.paths = const {}, this.data = const {}});
}

class ImageGenService {
  static const _apiKeyHiveKey = 'openai_api_key';

  static String? get apiKey =>
      HiveService.settings.get(_apiKeyHiveKey) as String?;

  static Future<void> setApiKey(String key) =>
      HiveService.settings.put(_apiKeyHiveKey, key.trim());

  /// 부화 시점에 baby / adult / evolved 이미지를 병렬 생성.
  static Future<ImageGenResult> generateAllStages({
    required String creatureId,
    required Lineage lineage,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) return const ImageGenResult();

    final stages = [CreatureStage.baby, CreatureStage.adult, CreatureStage.evolved];

    final futures = stages.map(
      (stage) => _generateOne(
        apiKey: key,
        creatureId: creatureId,
        lineage: lineage,
        stage: stage,
      ),
    );

    final results = await Future.wait(futures);

    final paths = <String, String>{};
    final data = <String, String>{};
    for (var i = 0; i < stages.length; i++) {
      final r = results[i];
      if (r == null) continue;
      if (r.path != null) paths[stages[i].name] = r.path!;
      data[stages[i].name] = r.base64;
    }
    return ImageGenResult(paths: paths, data: data);
  }

  // ── 단계별 단일 이미지 생성 ────────────────────────────────────────────────
  static Future<_StageResult?> _generateOne({
    required String apiKey,
    required String creatureId,
    required Lineage lineage,
    required CreatureStage stage,
  }) async {
    try {
      final prompt = _buildPrompt(lineage: lineage, stage: stage);

      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/images/generations'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'dall-e-3',
              'prompt': prompt,
              'n': 1,
              'size': '1024x1024',
              'quality': 'standard',
              'response_format': 'b64_json',
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        debugPrint('DALL-E [${stage.name}] error ${response.statusCode}');
        return null;
      }

      final resData = jsonDecode(response.body) as Map<String, dynamic>;
      final b64 = (resData['data'] as List).first['b64_json'] as String;
      final bytes = base64Decode(b64);

      // Native: 파일로도 저장
      String? filePath;
      if (!kIsWeb) {
        final fileName = 'creature_${creatureId}_${stage.name}.png';
        filePath = await file_io.saveImageBytes(bytes, fileName);
        if (filePath != null) debugPrint('Saved [${stage.name}]: $filePath');
      }

      return _StageResult(path: filePath, base64: b64);
    } catch (e) {
      debugPrint('ImageGenService [${stage.name}] error: $e');
      return null;
    }
  }

  // ── 프롬프트 빌더 ──────────────────────────────────────────────────────────
  static const _suffix =
      'Pure white background. Exactly one character centered in frame. '
      'Full body visible from head to toe. Square 1:1 format. '
      'No other characters, no text, no watermark, no drop shadow, no border.';

  static String _buildPrompt({
    required Lineage lineage,
    required CreatureStage stage,
  }) {
    const style =
        'Cute chibi character art for a children\'s mobile game, '
        'vibrant clean digital illustration. ';
    return style + _characterDesc(lineage, stage) + ' ' + _suffix;
  }

  static String _characterDesc(Lineage lineage, CreatureStage stage) {
    switch (lineage) {
      case Lineage.dragon:
        switch (stage) {
          case CreatureStage.baby:
          case CreatureStage.egg:
            return 'A tiny baby dragon. Plump round crimson-red body covered in '
                'small golden scales, tiny folded golden wing stubs, large '
                'sparkly emerald-green eyes, stubby arms and legs, a short tail '
                'with a tiny orange flame at the tip. Very round and chubby shape.';
          case CreatureStage.adult:
            return 'A young dragon. Medium crimson-red scaled body with golden '
                'wing membranes, wings half-spread showing gold veins, bright '
                'emerald-green eyes, longer tail with a medium orange flame, '
                'more defined muscular limbs, small golden chest scales.';
          case CreatureStage.evolved:
            return 'A majestic evolved dragon. Powerful crimson-red body with '
                'brilliant golden scales, large magnificent golden wings fully '
                'spread, crown-like golden horns on head, intense glowing '
                'emerald-green eyes, long tail ending in a blazing flame crown, '
                'golden claws.';
        }

      case Lineage.machine:
        switch (stage) {
          case CreatureStage.baby:
          case CreatureStage.egg:
            return 'A tiny baby robot monster. Round silver-gray spherical body '
                'with hexagonal panel details, one large circular blue LED eye '
                'in center, small rounded antenna on top with a blue glowing tip, '
                'tiny stubby metallic arm nubs, small round wheel feet.';
          case CreatureStage.adult:
            return 'A young robot monster. Compact humanoid silver body with '
                'blue glowing chest reactor core, articulated arm and leg joints '
                'with blue light trim, two round blue LED eyes, small shoulder '
                'pauldrons, sleek metallic finish.';
          case CreatureStage.evolved:
            return 'A majestic evolved robot monster. Advanced sleek silver mech '
                'body with four glowing blue energy wings extended outward, '
                'large blue crystal reactor core fully illuminated in chest, '
                'segmented armor plating with blue neon light edges, two '
                'powerful glowing blue eyes, commanding stance.';
        }

      case Lineage.plant:
        switch (stage) {
          case CreatureStage.baby:
          case CreatureStage.egg:
            return 'A tiny baby plant monster. Small round bright-green mossy '
                'body, a single large curled fresh leaf growing upward from its '
                'head, a tiny white flower bud near the leaf, large round shiny '
                'black eyes, small root-like feet on the ground.';
          case CreatureStage.adult:
            return 'A young plant monster. Taller leafy green body with a '
                'blooming pink flower crown on its head, vine-like arms ending '
                'in small leaf hands, bark-textured torso, cheerful round eyes, '
                'leafy skirt, small green curling tail.';
          case CreatureStage.evolved:
            return 'A majestic evolved plant monster. Ancient tree spirit form, '
                'rich emerald-green bark body, a magnificent crown of flowers '
                'and luminous leaves on its head, graceful branch-like arms '
                'with glowing green leaves, warm amber glowing eyes, roots '
                'flowing as feet, soft green aura.';
        }

      case Lineage.fairy:
        switch (stage) {
          case CreatureStage.baby:
          case CreatureStage.egg:
            return 'A tiny baby fairy monster. Soft pastel pink puffball body, '
                'large rosy cheeks with blush marks, a tiny curved antenna with '
                'a golden star tip growing from the head, very small rounded '
                'wing stubs on the back, shiny violet eyes, small delicate feet.';
          case CreatureStage.adult:
            return 'A young fairy monster. Petite pastel pink and lavender body, '
                'small elegant butterfly-style wings with pink shimmer, holding '
                'a tiny glowing star wand in one hand, large violet eyes, '
                'wearing a flower petal skirt, pink blush cheeks.';
          case CreatureStage.evolved:
            return 'A majestic evolved fairy monster. Radiant fairy queen, '
                'large ornate translucent wings with flowing golden sparkle '
                'dust trail, flowing pink and lavender gown with star patterns, '
                'ethereal starlight crown on head, glowing violet eyes filled '
                'with warm light, elegant graceful pose.';
        }

      case Lineage.rare:
        switch (stage) {
          case CreatureStage.baby:
          case CreatureStage.egg:
            return 'A tiny baby mystical monster. Small round floating crystal '
                'geode creature, outer shell of deep purple and teal crystalline '
                'facets, a single large luminous pale-blue eye at center, soft '
                'iridescent inner glow visible through crystal gaps, two tiny '
                'crystal stub arms.';
          case CreatureStage.adult:
            return 'A young mystical monster. Crystal-armored creature with '
                'deep purple outer shell and teal crystal spines along its back, '
                'glowing iridescent core visible through a transparent chest '
                'panel, two pale-blue glowing eyes, elegant crystal tail, '
                'small crystal wings.';
          case CreatureStage.evolved:
            return 'A legendary evolved mystical monster. Powerful body encased '
                'in deep purple and teal prism armor, multiple large prismatic '
                'crystal wings spreading outward refracting rainbow light, '
                'full body aurora glow, commanding pale-blue glowing eyes, '
                'crystal crown on head, awe-inspiring stance.';
        }
    }
  }
}

class _StageResult {
  final String? path;
  final String base64;
  const _StageResult({this.path, required this.base64});
}
