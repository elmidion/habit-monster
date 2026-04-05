import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/mission_model.dart';
import '../../data/providers/coin_provider.dart';
import '../../data/providers/collection_provider.dart';
import '../../data/providers/completions_provider.dart';
import '../../data/providers/missions_provider.dart';
import '../../data/providers/summon_provider.dart';
import '../../shared/widgets/creature_avatar.dart';
import '../../shared/widgets/exp_bar_widget.dart';
import '../../shared/widgets/mission_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ConfettiController _confetti;
  _EventBanner? _banner;

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
    final missions = ref.watch(missionsProvider).valueOrNull
            ?.where((m) => m.isActive)
            .toList() ??
        [];
    final completedIds =
        ref.watch(todayCompletedIdsProvider).valueOrNull ?? {};
    final streak = ref.watch(streakProvider).valueOrNull;
    final stones = ref.watch(summonStonesProvider);
    final coins = ref.watch(coinBalanceProvider);

    if (creature == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final typeColor = AppTheme.primary;
    final doneCount = missions.where((m) => completedIds.contains(m.id)).length;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라데이션
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    typeColor.withValues(alpha: 0.12),
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
          ),

          // 컨페티
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFFFFD93D),
                Color(0xFFFF6B9D),
                Color(0xFF74B9FF),
              ],
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                title: Text(creature.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                actions: [
                  // 코인
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      avatar: const Text('🪙', style: TextStyle(fontSize: 13)),
                      label: Text('$coins',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 12)),
                      backgroundColor: Colors.amber.shade50,
                      padding: EdgeInsets.zero,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                  // 소환석
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => context.push('/summon'),
                      child: Chip(
                        avatar: const Text('💎', style: TextStyle(fontSize: 13)),
                        label: Text('$stones',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                        backgroundColor: Colors.blue.shade50,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                  // 스트릭
                  if ((streak?.currentStreak ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Chip(
                        avatar:
                            const Text('🔥', style: TextStyle(fontSize: 13)),
                        label: Text('${streak!.currentStreak}일',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                        backgroundColor:
                            const Color(0xFFFF6B35).withValues(alpha: 0.15),
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.lock_outline_rounded),
                    onPressed: () => context.push('/parent'),
                    tooltip: '부모 모드',
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 캐릭터
                    GestureDetector(
                      onTap: () => context.push('/collection'),
                      child: CreatureAvatar(creature: creature, size: 190),
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 8),

                    // 계통 + 타입 뱃지
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Badge(
                            label:
                                '${creature.lineage.emoji} ${creature.lineage.nameKo}',
                            color: creature.lineage.placeholderColor),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // EXP 바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ExpBarWidget(
                        level: creature.level,
                        currentExp: creature.currentExp,
                        requiredExp: creature.expForNextLevel,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 스킬 선택 대기
                    if (creature.pendingSkillTiers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/skill-selection'),
                            icon: const Text('🎁', style: TextStyle(fontSize: 20)),
                            label: const Text('새 스킬을 배울 수 있어요!'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD93D),
                              foregroundColor: const Color(0xFF2D3436),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3)),

                    // 이벤트 배너
                    if (_banner != null) _BannerCard(banner: _banner!),

                    // 미션 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('오늘의 미션',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text('$doneCount / ${missions.length}',
                              style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              SliverList.builder(
                itemCount: missions.length,
                itemBuilder: (_, i) {
                  final m = missions[i];
                  return MissionTile(
                    mission: m,
                    isCompleted: completedIds.contains(m.id),
                    onComplete: () => _completeMission(m),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ShortcutBtn(
                              icon: '🎒',
                              label: '보관함',
                              onTap: () => context.push('/collection')),
                          const SizedBox(width: 12),
                          _ShortcutBtn(
                              icon: '💎',
                              label: '소환',
                              onTap: () => context.push('/summon')),
                          const SizedBox(width: 12),
                          _ShortcutBtn(
                              icon: '🔍',
                              label: '상세',
                              onTap: () => context.push('/creature')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ShortcutBtn(
                              icon: '🏆',
                              label: '뱃지',
                              onTap: () => context.push('/achievements')),
                          const SizedBox(width: 12),
                          _ShortcutBtn(
                              icon: '📊',
                              label: '통계',
                              onTap: () => context.push('/stats')),
                          const SizedBox(width: 12),
                          _ShortcutBtn(
                              icon: '📅',
                              label: '기록',
                              onTap: () => context.push('/history')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completeMission(MissionModel mission) async {
    final result = await ref
        .read(collectionProvider.notifier)
        .completeMission(mission);
    if (!mounted) return;

    if (result.didEvolve) {
      _confetti.play();
      setState(() => _banner = _EventBanner(
            emoji: '✨',
            message: '진화했어요! 정말 대단해요!',
            color: Colors.purple.shade300,
          ));
    } else if (result.didStageUp) {
      _confetti.play();
      setState(() => _banner = _EventBanner(
            emoji: '🌱',
            message: '성장했어요! Lv.${result.newLevel}',
            color: Colors.green.shade400,
          ));
    } else if (result.didLevelUp) {
      _confetti.play();
      setState(() => _banner = _EventBanner(
            emoji: '🎉',
            message: 'Lv.${result.newLevel} 달성!',
            color: AppTheme.primary,
          ));
    } else if (result.newBadgeIds.isNotEmpty) {
      setState(() => _banner = _EventBanner(
            emoji: '🏅',
            message: '새 뱃지를 획득했어요!',
            color: Colors.amber.shade600,
          ));
    } else {
      setState(() => _banner = _EventBanner(
            emoji: '⚡',
            message: '+${result.expGained} EXP'
                '${result.stonesEarned > 0 ? '  💎+${result.stonesEarned}' : ''}',
            color: AppTheme.secondary,
            brief: true,
          ));
    }

  }
}

// ── 뱃지 칩 ───────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// ── 이벤트 배너 ────────────────────────────────────────────────────────────────
class _EventBanner {
  final String emoji;
  final String message;
  final Color color;
  final bool brief;
  _EventBanner(
      {required this.emoji,
      required this.message,
      required this.color,
      this.brief = false});
}

class _BannerCard extends StatefulWidget {
  final _EventBanner banner;
  const _BannerCard({required this.banner});

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  @override
  void initState() {
    super.initState();
    if (widget.banner.brief) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: widget.banner.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.banner.color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(children: [
          Text(widget.banner.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(widget.banner.message,
              style: TextStyle(
                  color: widget.banner.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ]),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.3, curve: Curves.easeOut);
  }
}

class _ShortcutBtn extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _ShortcutBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: const Border.fromBorderSide(
                BorderSide(color: AppTheme.divider, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
