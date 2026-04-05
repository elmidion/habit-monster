import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/completion_model.dart';
import '../../data/providers/completions_provider.dart';
import '../../domain/enums/mission_category.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCompletions = ref.watch(allCompletionsProvider);
    final streak = ref.watch(streakProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('📅 미션 기록')),
      body: allCompletions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (completions) {
          if (completions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📭', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('아직 완료한 미션이 없어요.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          // Group by date (newest first)
          final grouped = _groupByDate(completions);
          final dates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return CustomScrollView(
            slivers: [
              // Streak summary
              if (streak != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      _StreakCard(
                          emoji: '🔥',
                          value: '${streak.currentStreak}',
                          label: '연속'),
                      const SizedBox(width: 12),
                      _StreakCard(
                          emoji: '🏆',
                          value: '${streak.longestStreak}',
                          label: '최고 기록'),
                      const SizedBox(width: 12),
                      _StreakCard(
                          emoji: '📅',
                          value: '${dates.length}',
                          label: '활동 일수'),
                    ]),
                  ),
                ),

              // Date groups
              for (final date in dates) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      _formatDate(date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: grouped[date]!.length,
                  itemBuilder: (_, i) =>
                      _CompletionTile(completion: grouped[date]![i]),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<CompletionModel>> _groupByDate(
      List<CompletionModel> all) {
    final map = <DateTime, List<CompletionModel>>{};
    for (final c in all) {
      final key = DateTime(
          c.completedAt.year, c.completedAt.month, c.completedAt.day);
      map.putIfAbsent(key, () => []).add(c);
    }
    return map;
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return '오늘';
    if (d == yesterday) return '어제';
    return DateFormat('yyyy년 M월 d일 (E)', 'ko').format(d);
  }
}

class _CompletionTile extends StatelessWidget {
  final CompletionModel completion;
  const _CompletionTile({required this.completion});

  @override
  Widget build(BuildContext context) {
    final catName = _catName(completion.category);
    final catColor = completion.category.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: Row(children: [
          Text(completion.category.emoji,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catName,
                    style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(
                  DateFormat('HH:mm').format(completion.completedAt),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${completion.expAwarded} EXP',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            if (completion.wasStreakBonus)
              const Text('🔥 보너스',
                  style: TextStyle(fontSize: 10, color: Color(0xFFFF6B35))),
          ]),
        ]),
      ),
    );
  }

  String _catName(MissionCategory cat) {
    const m = {
      MissionCategory.fire: '도전',
      MissionCategory.water: '청결',
      MissionCategory.grass: '독서',
      MissionCategory.electric: '집중',
      MissionCategory.moon: '생활',
    };
    return m[cat] ?? cat.name;
  }
}

class _StreakCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StreakCard(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: AppTheme.divider, width: 1.5)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}
