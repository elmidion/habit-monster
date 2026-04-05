import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/creature_model.dart';
import '../../data/providers/collection_provider.dart';
import '../../domain/definitions/skill_definitions.dart';
import '../../domain/enums/creature_stage.dart';
import '../../shared/widgets/creature_avatar.dart';
import '../../shared/widgets/exp_bar_widget.dart';

class CreatureDetailScreen extends ConsumerWidget {
  const CreatureDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creature = ref.watch(activeCreatureProvider);
    if (creature == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final typeColor = AppTheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(creature.name),
        backgroundColor: typeColor.withOpacity(0.1),
      ),
      body: CustomScrollView(
        slivers: [
          // Creature display
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    typeColor.withOpacity(0.15),
                    AppTheme.background,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(children: [
                CreatureAvatar(creature: creature, size: 180),
                const SizedBox(height: 12),
                // Stage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${creature.lineage.emoji} ${creature.stage.nameKo} 단계',
                    style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                if (creature.stage == CreatureStage.evolved)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('✨ 진화 완성!',
                        style: TextStyle(
                            color: Colors.purple.shade400,
                            fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  ExpBarWidget(
                    level: creature.level,
                    currentExp: creature.currentExp,
                    requiredExp: creature.expForNextLevel,
                  ),
                  const SizedBox(height: 20),
                  _statsRow(context, creature),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Skills
          if (creature.skillIds.isNotEmpty) ...[
            _sectionHeader(context, '💫 스킬'),
            SliverList.builder(
              itemCount: creature.skillIds.length,
              itemBuilder: (_, i) {
                final def = getSkillById(creature.skillIds[i]);
                if (def == null) return const SizedBox();
                return ListTile(
                  leading: Text(def.emoji,
                      style: const TextStyle(fontSize: 26)),
                  title: Text(def.nameKo,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(def.descriptionKo),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('T${def.tier}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                  ),
                );
              },
            ),
          ],

          // Category stats
          _sectionHeader(context, '📊 미션 현황'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _CategoryStats(counts: creature.categoryCompletionCount),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, CreatureModel creature) {
    return Row(
      children: [
        _StatCard(
            emoji: '📅',
            value: '${creature.totalDaysActive}',
            label: '활동 일수'),
        const SizedBox(width: 10),
        _StatCard(
            emoji: '⚡',
            value: '${creature.totalExpEarned}',
            label: '총 EXP'),
        const SizedBox(width: 10),
        _StatCard(
            emoji: '💫',
            value: '${creature.skillIds.length}',
            label: '스킬'),
      ],
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
        child: Text(title,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: AppTheme.divider, width: 1.5)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

class _CategoryStats extends StatelessWidget {
  final Map<String, int> counts;
  const _CategoryStats({required this.counts});

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text('아직 완료한 미션이 없어요.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    final maxVal = entries.first.value;
    return Column(
      children: entries.map((e) {
        final catEmoji = _catEmoji(e.key);
        final catName = _catName(e.key);
        final catColor = _catColor(e.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text(catEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            SizedBox(
                width: 48,
                child: Text(catName,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700))),
            Expanded(
              child: Stack(children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: e.value / maxVal,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Text('${e.value}회',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        );
      }).toList(),
    );
  }

  String _catEmoji(String name) {
    const m = {
      'fire': '🔥', 'water': '💧', 'grass': '🌿',
      'electric': '⚡', 'moon': '🌙'
    };
    return m[name] ?? '✨';
  }

  String _catName(String name) {
    const m = {
      'fire': '도전', 'water': '청결', 'grass': '독서',
      'electric': '집중', 'moon': '생활'
    };
    return m[name] ?? name;
  }

  Color _catColor(String name) {
    const m = {
      'fire': Color(0xFFFF6B35),
      'water': Color(0xFF42A5F5),
      'grass': Color(0xFF66BB6A),
      'electric': Color(0xFFFFCA28),
      'moon': Color(0xFF7E57C2),
    };
    return m[name] ?? AppTheme.primary;
  }
}
