import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/collection_provider.dart';
import '../../data/providers/summon_provider.dart';
import '../../domain/logic/summon_logic.dart';
import '../../shared/widgets/creature_avatar.dart';

class SummonScreen extends ConsumerStatefulWidget {
  const SummonScreen({super.key});

  @override
  ConsumerState<SummonScreen> createState() => _SummonScreenState();
}

class _SummonScreenState extends ConsumerState<SummonScreen> {
  bool _summoning = false;
  SummonResult? _result;

  @override
  Widget build(BuildContext context) {
    final stones = ref.watch(summonStonesProvider);
    final collection = ref.watch(collectionProvider).valueOrNull ?? [];
    final isFull = collection.length >= maxSlots;
    final canSummon = stones >= SummonLogic.stoneCost && !isFull;

    return Scaffold(
      appBar: AppBar(title: const Text('소환')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 소환석 현황
            _StoneBar(stones: stones, cost: SummonLogic.stoneCost),
            const SizedBox(height: 32),

            // 확률 안내
            _ProbabilityCard(),
            const SizedBox(height: 32),

            // 결과 표시 or 이모지
            Expanded(
              child: _result != null
                  ? _ResultView(result: _result!)
                  : Center(
                      child: Text(
                        '💎',
                        style: TextStyle(fontSize: 80),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1),
                            duration: 1200.ms, curve: Curves.easeInOut),
                    ),
            ),

            // 소환 버튼
            if (isFull)
              const Text('보관함이 꽉 찼어요. 캐릭터를 놓아주세요.',
                  style: TextStyle(color: Colors.redAccent))
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _summoning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('💎'),
                  label: Text(_summoning
                      ? '소환 중...'
                      : '소환하기 (${SummonLogic.stoneCost}석)'),
                  onPressed: canSummon && !_summoning ? _doSummon : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '보관함 ${collection.length} / $maxSlots',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doSummon() async {
    setState(() {
      _summoning = true;
      _result = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    final result = await ref.read(summonProvider).summon();
    if (!mounted) return;
    setState(() {
      _summoning = false;
      _result = result;
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('소환에 실패했어요. 소환석이나 슬롯을 확인하세요.')),
      );
    }
  }
}

// ── 소환석 바 ─────────────────────────────────────────────────────────────────
class _StoneBar extends StatelessWidget {
  final int stones;
  final int cost;
  const _StoneBar({required this.stones, required this.cost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('💎', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text('보유 소환석',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ]),
          Text('$stones 개',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20)),
        ],
      ),
    );
  }
}

// ── 확률 안내 ─────────────────────────────────────────────────────────────────
class _ProbabilityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('소환 확률',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ProbChip(emoji: '🐉', name: '드래곤', prob: '22.5%'),
              const SizedBox(width: 6),
              _ProbChip(emoji: '🌿', name: '식물', prob: '22.5%'),
              const SizedBox(width: 6),
              _ProbChip(emoji: '⚙️', name: '기계', prob: '22.5%'),
              const SizedBox(width: 6),
              _ProbChip(emoji: '🧚', name: '요정', prob: '22.5%'),
            ],
          ),
          const SizedBox(height: 6),
          _ProbChip(
              emoji: '✨', name: '신비 (희귀)', prob: '10%', isRare: true),
        ],
      ),
    );
  }
}

class _ProbChip extends StatelessWidget {
  final String emoji;
  final String name;
  final String prob;
  final bool isRare;

  const _ProbChip({
    required this.emoji,
    required this.name,
    required this.prob,
    this.isRare = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRare
            ? Colors.amber.shade50
            : AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isRare ? Colors.amber.shade300 : AppTheme.divider),
      ),
      child: Text('$emoji $name $prob',
          style: TextStyle(
              fontSize: 11,
              fontWeight: isRare ? FontWeight.w800 : FontWeight.w500,
              color: isRare ? Colors.amber.shade800 : AppTheme.textSecondary)),
    );
  }
}

// ── 소환 결과 ─────────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final SummonResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (result.isRare)
          const Text('✨ 희귀 소환! ✨',
              style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 18))
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.7, 0.7)),
        const SizedBox(height: 12),
        CreatureAvatar(creature: result.egg, size: 120)
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              curve: Curves.elasticOut,
              duration: 800.ms,
            ),
        const SizedBox(height: 16),
        Text(
          '${result.egg.lineage.nameKo} 알',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        const SizedBox(height: 6),
        Text(
          '보관함에 추가되었어요!\n탭해서 이름을 지어주세요 🥚',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
