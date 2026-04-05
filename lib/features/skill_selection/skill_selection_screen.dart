import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/collection_provider.dart';
import '../../domain/definitions/skill_definitions.dart';

class SkillSelectionScreen extends ConsumerStatefulWidget {
  const SkillSelectionScreen({super.key});

  @override
  ConsumerState<SkillSelectionScreen> createState() =>
      _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends ConsumerState<SkillSelectionScreen> {
  late final ConfettiController _confetti;
  int? _selectedIndex;
  bool _confirmed = false;
  List<SkillDefinition>? _cachedChoices;
  int? _cachedTier;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creature = ref.watch(activeCreatureProvider);
    if (creature == null || creature.pendingSkillTiers.isEmpty) {
      // 선택할 스킬이 없으면 홈으로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tier = creature.pendingSkillTiers.first;
    // 티어가 바뀔 때만 새로 뽑고, 같은 티어면 캐시 유지
    if (_cachedChoices == null || _cachedTier != tier) {
      _cachedTier = tier;
      _cachedChoices = getSkillChoices(
        tier: tier,
        existingSkillIds: creature.skillIds,
        lineage: creature.lineage,
        level: creature.level,
      );
    }
    final choices = _cachedChoices!;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // 헤더
                  Text(
                    '새로운 스킬! 🎁',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    '${creature.name}에게 가르칠 스킬을 골라주세요!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  _TierBadge(tier: tier),
                  const SizedBox(height: 28),

                  // 스킬 카드 목록
                  Expanded(
                    child: ListView.separated(
                      itemCount: choices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final skill = choices[index];
                        final selected = _selectedIndex == index;
                        return _SkillCard(
                          skill: skill,
                          selected: selected,
                          confirmed: _confirmed,
                          onTap: _confirmed
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedIndex = index);
                                },
                        ).animate(delay: (100 * index).ms).fadeIn().slideX(
                              begin: 0.1,
                              curve: Curves.easeOutCubic,
                            );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 확정 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedIndex != null && !_confirmed)
                          ? () => _confirm(creature.id, choices[_selectedIndex!])
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF2D3436),
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(_selectedIndex == null
                          ? '스킬을 선택해주세요'
                          : '이 스킬 배우기!'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(String creatureId, SkillDefinition skill) async {
    setState(() => _confirmed = true);
    HapticFeedback.heavyImpact();
    _confetti.play();

    ref.read(collectionProvider.notifier).confirmSkillSelection(
      creatureId,
      skill.id,
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // 아직 선택할 스킬이 더 있으면 화면 리셋, 아니면 홈으로
    final updated = ref.read(activeCreatureProvider);
    if (updated != null && updated.pendingSkillTiers.isNotEmpty) {
      setState(() {
        _selectedIndex = null;
        _confirmed = false;
        _cachedChoices = null;
        _cachedTier = null;
      });
    } else {
      context.go('/home');
    }
  }
}

// ── 티어 뱃지 ────────────────────────────────────────────────────────────────
class _TierBadge extends StatelessWidget {
  final int tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tier) {
      1 => ('기본 스킬', Colors.green),
      2 => ('고급 스킬', Colors.blue),
      3 => ('전설 스킬', Colors.purple),
      _ => ('스킬', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '⭐ $label (티어 $tier)',
        style: TextStyle(
          color: color.shade200,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── 스킬 카드 ─────────────────────────────────────────────────────────────────
class _SkillCard extends StatelessWidget {
  final SkillDefinition skill;
  final bool selected;
  final bool confirmed;
  final VoidCallback? onTap;

  const _SkillCard({
    required this.skill,
    required this.selected,
    required this.confirmed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isChosen = selected && confirmed;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isChosen
              ? AppTheme.accent.withValues(alpha: 0.25)
              : selected
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isChosen
                ? AppTheme.accent
                : selected
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 이모지
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(skill.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.nameKo,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill.descriptionKo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // 체크 아이콘
            if (selected)
              Icon(
                isChosen ? Icons.check_circle : Icons.radio_button_checked,
                color: isChosen ? AppTheme.accent : Colors.white70,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
