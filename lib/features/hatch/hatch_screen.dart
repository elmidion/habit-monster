import 'dart:convert';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/image_gen_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/collection_provider.dart';
import '../../shared/widgets/creature_avatar_io.dart'
    if (dart.library.html) '../../shared/widgets/creature_avatar_web.dart'
    as platform;

enum _Phase { idle, generating, preview }

class HatchScreen extends ConsumerStatefulWidget {
  final String eggId;
  const HatchScreen({super.key, required this.eggId});

  @override
  ConsumerState<HatchScreen> createState() => _HatchScreenState();
}

class _HatchScreenState extends ConsumerState<HatchScreen> {
  late final ConfettiController _confetti;
  final _nameCtrl = TextEditingController();
  _Phase _phase = _Phase.idle;
  Map<String, String> _stageImagePaths = {};
  Map<String, String> _stageImageData = {};

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── 단계 1: 이미지 생성 ──────────────────────────────────────────────────
  Future<void> _startGeneration() async {
    final egg = (ref.read(collectionProvider).valueOrNull ?? [])
        .where((c) => c.id == widget.eggId)
        .firstOrNull;
    if (egg == null) return;

    // API 키가 없으면 생성 단계를 건너뛰고 바로 이름 짓기로
    if (ImageGenService.apiKey?.isNotEmpty != true) {
      setState(() {
        _stageImagePaths = {};
        _stageImageData = {};
        _phase = _Phase.preview;
      });
      return;
    }

    setState(() => _phase = _Phase.generating);

    final result = await ImageGenService.generateAllStages(
      creatureId: egg.id,
      lineage: egg.lineage,
    );

    if (mounted) {
      setState(() {
        _stageImagePaths = result.paths;
        _stageImageData = result.data;
        _phase = _Phase.preview;
      });
    }
  }

  // ── 단계 2: 부화 확정 ───────────────────────────────────────────────────
  Future<void> _confirmHatch() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요!')),
      );
      return;
    }

    await ref.read(collectionProvider.notifier).hatch(
      widget.eggId,
      name,
      stageImagePaths: _stageImagePaths,
      stageImageData: _stageImageData,
    );
    _confetti.play();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final collection = ref.watch(collectionProvider).valueOrNull ?? [];
    final egg = collection.where((c) => c.id == widget.eggId).firstOrNull;
    if (egg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFFFFD93D), Color(0xFFFF6B9D),
                  Color(0xFF74B9FF), Color(0xFF81C784),
                ],
              ),
            ),
            switch (_phase) {
              _Phase.idle      => _buildIdle(egg),
              _Phase.generating => _buildGenerating(egg),
              _Phase.preview   => _buildPreview(egg),
            },
          ],
        ),
      ),
    );
  }

  // ── Idle: 알 표시 + 부화 버튼 ──────────────────────────────────────────
  Widget _buildIdle(dynamic egg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${egg.lineage.nameKo} 알을\n부화시켜요! 🥚',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w900),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 40),
          Text(egg.lineage.emoji, style: const TextStyle(fontSize: 100))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.08, 1.08),
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 48),
          if (ImageGenService.apiKey?.isNotEmpty == true)
            Text(
              '🎨 AI가 3단계 이미지를 모두 그려드려요\n(약 20~30초 소요)',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            )
          else
            Text(
              '부모 모드에서 API 키를 설정하면\nAI 이미지를 자동 생성해요',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.8), fontSize: 13),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGeneration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: const Color(0xFF2D3436),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: const Text('부화하기! 🌟'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('나중에',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  // ── Generating: 로딩 ────────────────────────────────────────────────────
  Widget _buildGenerating(dynamic egg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(egg.lineage.emoji, style: const TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 2000.ms, curve: Curves.easeInOut)
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 1000.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 40),
          Text(
            '🎨 AI가 몬스터를 그리는 중이에요...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800),
          ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
          const SizedBox(height: 12),
          Text(
            'baby · adult · evolved 3장을 동시에 생성 중',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white24,
              color: AppTheme.accent,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview: 이미지 확인 + 이름 짓기 ────────────────────────────────────
  Widget _buildPreview(dynamic egg) {
    final babyB64 = _stageImageData['baby'];
    final babyPath = _stageImagePaths['baby'];
    final hasB64 = babyB64 != null && babyB64.isNotEmpty;
    final fileImage = (!hasB64 && !kIsWeb) ? platform.buildFileImage(babyPath, 220) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Text(
            '몬스터가 태어났어요! 👀',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w900),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // 이미지 미리보기 (baby)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: hasB64
                ? Image.memory(base64Decode(babyB64),
                    width: 220, height: 220, fit: BoxFit.cover)
                : fileImage != null
                ? fileImage
                : Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      color: egg.lineage.placeholderColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(egg.lineage.emoji,
                          style: const TextStyle(fontSize: 80)),
                    ),
                  ),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.85, 0.85),
                curve: Curves.easeOutBack),

          const SizedBox(height: 12),

          // 생성 결과 요약
          if (_stageImageData.isNotEmpty || _stageImagePaths.isNotEmpty)
            Text(
              '✅ ${_stageImageData.isNotEmpty ? _stageImageData.length : _stageImagePaths.length}단계 이미지 생성 완료',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
            )
          else
            Text(
              'API 키 없이 플레이스홀더로 진행합니다',
              style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.8), fontSize: 13),
            ),

          const SizedBox(height: 28),

          // 이름 입력
          Text(
            '이름을 지어줘요!',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 12,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            onSubmitted: (_) => _confirmHatch(),
            decoration: InputDecoration(
              hintText: '이름 입력...',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              fillColor: Colors.white.withValues(alpha: 0.1),
              filled: true,
              counterStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppTheme.accent, width: 2)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmHatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: const Color(0xFF2D3436),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: const Text('이름 짓기! 🌟'),
            ),
          ),
        ],
      ),
    );
  }
}
