import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_clock.dart';
import '../../data/models/completion_model.dart';
import '../../data/providers/completions_provider.dart';
import '../../domain/enums/mission_category.dart';

enum _Period { week, month }

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allCompletionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📈 습관 리포트')),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (all) => _buildBody(context, all),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<CompletionModel> all) {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);

    late DateTime rangeStart;
    late String rangeLabel;
    late int totalDaysInRange;

    if (_period == _Period.week) {
      // 이번 주 (월~일)
      rangeStart = today.subtract(Duration(days: today.weekday - 1));
      final rangeEnd = rangeStart.add(const Duration(days: 6));
      rangeLabel =
          '${DateFormat('M/d').format(rangeStart)} ~ ${DateFormat('M/d').format(rangeEnd)}';
      totalDaysInRange = 7;
    } else {
      // 이번 달
      rangeStart = DateTime(today.year, today.month, 1);
      final lastDay = DateTime(today.year, today.month + 1, 0).day;
      rangeLabel = DateFormat('yyyy년 M월').format(today);
      totalDaysInRange = lastDay;
    }

    final rangeEnd = rangeStart.add(Duration(days: totalDaysInRange));

    // 기간 내 완�� 기록 필터
    final filtered = all.where((c) {
      final d = DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day);
      return !d.isBefore(rangeStart) && d.isBefore(rangeEnd);
    }).toList();

    // 활동 일수
    final activeDays = filtered
        .map((c) => DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day))
        .toSet();

    // 일별 미션 수
    final dailyCounts = <DateTime, int>{};
    for (final c in filtered) {
      final d = DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day);
      dailyCounts[d] = (dailyCounts[d] ?? 0) + 1;
    }

    // 카테고리별 집계
    final catCounts = <MissionCategory, int>{};
    for (final c in filtered) {
      catCounts[c.category] = (catCounts[c.category] ?? 0) + 1;
    }

    // 일 평균
    final avgPerDay = activeDays.isEmpty
        ? 0.0
        : filtered.length / activeDays.length;

    // 달성률 (활동일수 / 기간일수, 미래 날짜 제외)
    final elapsedDays = today.difference(rangeStart).inDays + 1;
    final effectiveDays = elapsedDays.clamp(1, totalDaysInRange);
    final achievementRate = (activeDays.length / effectiveDays * 100).clamp(0, 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 선택
          _PeriodToggle(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(rangeLabel,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 20),

          // 요약 카드
          _SummaryRow(
            totalMissions: filtered.length,
            activeDays: activeDays.length,
            avgPerDay: avgPerDay,
            achievementRate: achievementRate.toDouble(),
          ),
          const SizedBox(height: 24),

          // 일별 차트
          Text('일별 미션 완료',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _DailyChart(
            rangeStart: rangeStart,
            totalDays: _period == _Period.week ? 7 : effectiveDays,
            dailyCounts: dailyCounts,
            today: today,
          ),
          const SizedBox(height: 24),

          // 카테고리별
          Text('카테고리별 현황',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _CategoryBreakdown(catCounts: catCounts, total: filtered.length),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── 기간 토글 ─────────────────────────────────────────────────────────────────
class _PeriodToggle extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;
  const _PeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _toggleBtn('이번 주', _Period.week, period, onChanged),
        const SizedBox(width: 8),
        _toggleBtn('이번 달', _Period.month, period, onChanged),
      ],
    );
  }

  Widget _toggleBtn(String label, _Period value, _Period current, ValueChanged<_Period> cb) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => cb(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
      ),
    );
  }
}

// ── 요약 �� ───────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final int totalMissions;
  final int activeDays;
  final double avgPerDay;
  final double achievementRate;

  const _SummaryRow({
    required this.totalMissions,
    required this.activeDays,
    required this.avgPerDay,
    required this.achievementRate,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🎯', '$totalMissions회', '총 미션'),
      ('📅', '$activeDays일', '활동 일수'),
      ('📊', avgPerDay.toStringAsFixed(1), '일 평균'),
      ('✅', '${achievementRate.toStringAsFixed(0)}%', '달성률'),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(
                  BorderSide(color: AppTheme.divider, width: 1.5)),
            ),
            child: Column(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(item.$2,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                Text(item.$3,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 일별 바 차트 ──────────────────────────────────────────────────────────────
class _DailyChart extends StatelessWidget {
  final DateTime rangeStart;
  final int totalDays;
  final Map<DateTime, int> dailyCounts;
  final DateTime today;

  const _DailyChart({
    required this.rangeStart,
    required this.totalDays,
    required this.dailyCounts,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = dailyCounts.values.fold(0, (m, v) => v > m ? v : m);
    final displayDays = totalDays.clamp(1, 31);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(displayDays, (i) {
          final date = rangeStart.add(Duration(days: i));
          final count = dailyCounts[date] ?? 0;
          final fraction = maxCount > 0 ? count / maxCount : 0.0;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isFuture = date.isAfter(today);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Text('$count',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? AppTheme.primary
                                : AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Flexible(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: double.infinity,
                      height: fraction * 80 + (count > 0 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? AppTheme.divider.withValues(alpha: 0.3)
                            : count > 0
                                ? (isToday
                                    ? AppTheme.primary
                                    : AppTheme.primary.withValues(alpha: 0.5))
                                : AppTheme.divider.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                      color: isToday
                          ? AppTheme.primary
                          : isFuture
                              ? AppTheme.textHint
                              : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 카테고리별 비율 ───────────────────────────────────────────────────────────
class _CategoryBreakdown extends StatelessWidget {
  final Map<MissionCategory, int> catCounts;
  final int total;
  const _CategoryBreakdown({required this.catCounts, required this.total});

  static const _meta = {
    MissionCategory.fire:     ('🔥', '도전',  Color(0xFFFF6B35)),
    MissionCategory.water:    ('💧', '청결',  Color(0xFF42A5F5)),
    MissionCategory.grass:    ('📖', '독서',  Color(0xFF66BB6A)),
    MissionCategory.electric: ('⚡', '집중',  Color(0xFFFFCA28)),
    MissionCategory.moon:     ('🌙', '생활',  Color(0xFF7E57C2)),
  };

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text('이 기간에 완료한 미션이 없어요.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return Column(
      children: _meta.entries.map((entry) {
        final cat = entry.key;
        final (emoji, label, color) = entry.value;
        final count = catCounts[cat] ?? 0;
        final fraction = total > 0 ? count / total : 0.0;
        final percent = (fraction * 100).toStringAsFixed(0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(children: [
                  Container(height: 14, color: color.withValues(alpha: 0.12)),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text('$count ($percent%)',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
