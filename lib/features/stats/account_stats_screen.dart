import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/collection_provider.dart';
import '../../data/providers/completions_provider.dart';

class AccountStatsScreen extends ConsumerWidget {
  const AccountStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCompletionsAsync = ref.watch(allCompletionsProvider);
    final streakAsync = ref.watch(streakProvider);
    final badgeRecords = ref.watch(badgesProvider).valueOrNull ?? [];
    final collection = ref.watch(collectionProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('📊 계정 통계')),
      body: allCompletionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (completions) {
          // 카테고리별 집계
          final catCounts = <String, int>{};
          for (final c in completions) {
            catCounts[c.category.name] =
                (catCounts[c.category.name] ?? 0) + 1;
          }

          // 활동 일수 (unique dates)
          final uniqueDays = completions
              .map((c) => DateTime(
                  c.completedAt.year, c.completedAt.month, c.completedAt.day))
              .toSet();

          final hatchedCount =
              collection.where((c) => c.stage.isHatched).length;
          final totalExpEarned = collection.fold(
              0, (sum, c) => sum + c.totalExpEarned);

          return CustomScrollView(
            slivers: [
              // ── 요약 카드 ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _SummaryGrid(
                    totalMissions: completions.length,
                    totalDays: uniqueDays.length,
                    totalBadges: badgeRecords.length,
                    totalCreatures: hatchedCount,
                    totalExpEarned: totalExpEarned,
                    streak: streakAsync.valueOrNull?.currentStreak ?? 0,
                    longestStreak:
                        streakAsync.valueOrNull?.longestStreak ?? 0,
                  ),
                ),
              ),

              // ── 카테고리별 미션 현황 ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text('카테고리별 누적 미션',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _CategoryBars(catCounts: catCounts),
                ),
              ),

              // ── 보유 캐릭터 EXP 현황 ───────────────────────────────────
              if (collection.any((c) => c.stage.isHatched)) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Text('캐릭터별 총 EXP',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverList.builder(
                  itemCount: collection
                      .where((c) => c.stage.isHatched)
                      .length,
                  itemBuilder: (_, i) {
                    final hatched = collection
                        .where((c) => c.stage.isHatched)
                        .toList()
                      ..sort((a, b) =>
                          b.totalExpEarned.compareTo(a.totalExpEarned));
                    final c = hatched[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          'Lv.${c.level} · ${c.stage.nameKo} · ${c.lineage.nameKo}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                      trailing: Text(
                        '${c.totalExpEarned} EXP',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.primary),
                      ),
                    );
                  },
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

// ── 요약 그리드 ────────────────────────────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  final int totalMissions;
  final int totalDays;
  final int totalBadges;
  final int totalCreatures;
  final int totalExpEarned;
  final int streak;
  final int longestStreak;

  const _SummaryGrid({
    required this.totalMissions,
    required this.totalDays,
    required this.totalBadges,
    required this.totalCreatures,
    required this.totalExpEarned,
    required this.streak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🎯', '$totalMissions회', '총 미션'),
      ('📅', '$totalDays일', '활동 일수'),
      ('🔥', '${streak}일', '현재 스트릭'),
      ('🏆', '${longestStreak}일', '최장 스트릭'),
      ('⚡', '$totalExpEarned', '총 EXP'),
      ('🏅', '$totalBadges개', '뱃지'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: items.map((item) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
                BorderSide(color: AppTheme.divider, width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(item.$2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              Text(item.$3,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 카테고리 바 차트 ───────────────────────────────────────────────────────────
class _CategoryBars extends StatelessWidget {
  final Map<String, int> catCounts;
  const _CategoryBars({required this.catCounts});

  static const _meta = {
    'fire':     ('🔥', '도전',  Color(0xFFFF6B35)),
    'water':    ('💧', '청결',  Color(0xFF42A5F5)),
    'grass':    ('📖', '독서',  Color(0xFF66BB6A)),
    'electric': ('⚡', '집중',  Color(0xFFFFCA28)),
    'moon':     ('🌙', '생활',  Color(0xFF7E57C2)),
  };

  @override
  Widget build(BuildContext context) {
    if (catCounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text('아직 완료한 미션이 없어요.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final maxVal = catCounts.values.fold(0, (m, v) => v > m ? v : m);

    return Column(
      children: _meta.entries.map((entry) {
        final key = entry.key;
        final (emoji, label, color) = entry.value;
        final count = catCounts[key] ?? 0;
        final fraction = maxVal > 0 ? count / maxVal : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(children: [
                  Container(
                    height: 12,
                    color: color.withValues(alpha: 0.15),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(height: 12, color: color),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              child: Text('$count회',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
