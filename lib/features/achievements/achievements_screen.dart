import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/badge_model.dart';
import '../../data/providers/collection_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeRecords =
        ref.watch(badgesProvider).valueOrNull ?? [];
    final earnedIds = badgeRecords.map((b) => b.badgeId).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('🏆 업적')),
      body: CustomScrollView(
        slivers: [
          // Badges section
          _sectionHeader(context, '🏅 뱃지'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: allBadgeDefinitions.map((def) {
                final earned = earnedIds.contains(def.id);
                final record =
                    earned ? badgeRecords.firstWhere((b) => b.badgeId == def.id) : null;
                return _BadgeTile(
                    def: def, earned: earned, record: record);
              }).toList(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
        child: Text(title,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDefinition def;
  final bool earned;
  final BadgeRecord? record;

  const _BadgeTile(
      {required this.def, required this.earned, this.record});

  Color get _rarityColor {
    switch (def.rarity) {
      case BadgeRarity.legendary:
        return const Color(0xFFE040FB);
      case BadgeRarity.rare:
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!earned) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('${def.emoji} ${def.nameKo}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(def.descriptionKo),
                if (record != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '획득: ${_fmt(record!.earnedAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (record!.parentComment != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${record!.parentComment}"',
                      style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기')),
            ],
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: earned ? 1.0 : 0.35,
        child: Container(
          decoration: BoxDecoration(
            color: earned
                ? _rarityColor.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: earned
                  ? _rarityColor.withOpacity(0.4)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(def.emoji,
                  style: TextStyle(
                      fontSize: earned ? 32 : 28)),
              const SizedBox(height: 6),
              Text(def.nameKo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: earned
                        ? AppTheme.textPrimary
                        : AppTheme.textHint,
                  )),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _rarityColor.withOpacity(earned ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _rarityLabel,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: earned ? _rarityColor : AppTheme.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _rarityLabel {
    switch (def.rarity) {
      case BadgeRarity.legendary:
        return 'LEGENDARY';
      case BadgeRarity.rare:
        return 'RARE';
      default:
        return 'COMMON';
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
