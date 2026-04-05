import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/creature_model.dart';
import '../../data/providers/collection_provider.dart';
import '../../data/providers/summon_provider.dart';
import '../../domain/enums/creature_stage.dart';
import '../../shared/widgets/creature_avatar.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);
    final activeId = ref.watch(activeCreatureIdProvider);
    final stones = ref.watch(summonStonesProvider);
    final collection = ref.watch(collectionProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('보관함'),
        actions: [
          // 소환석 표시
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: const Text('💎', style: TextStyle(fontSize: 14)),
              label: Text('$stones석',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              backgroundColor: Colors.blue.shade50,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: '소환',
            onPressed: () => context.push('/summon'),
          ),
        ],
      ),
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (_) {
          if (collection.isEmpty) {
            return const Center(child: Text('보관함이 비어있어요.'));
          }
          return Column(
            children: [
              // 슬롯 현황
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${collection.length} / ${maxSlots}',
                      style: TextStyle(
                          color: collection.length >= maxSlots
                              ? Colors.red
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: collection.length / maxSlots,
                        backgroundColor: AppTheme.divider,
                        color: collection.length >= maxSlots
                            ? Colors.red
                            : AppTheme.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: collection.length,
                  itemBuilder: (context, i) {
                    final c = collection[i];
                    return _CreatureCard(
                      creature: c,
                      isActive: c.id == activeId,
                      onTap: () => _onCardTap(context, ref, c),
                      onLongPress: () => _showOptions(context, ref, c),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onCardTap(BuildContext context, WidgetRef ref, CreatureModel c) {
    if (c.stage == CreatureStage.egg) {
      // 알 → 부화 화면으로
      context.push('/hatch/${c.id}');
    } else {
      // 부화된 캐릭터 → 활성으로 설정
      ref.read(collectionProvider.notifier).setActive(c.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${c.name}을(를) 활성 캐릭터로 설정했어요!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showOptions(BuildContext context, WidgetRef ref, CreatureModel c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreatureOptionsSheet(creature: c),
    );
  }
}

// ── 캐릭터 카드 ────────────────────────────────────────────────────────────────
class _CreatureCard extends StatelessWidget {
  final CreatureModel creature;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CreatureCard({
    required this.creature,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.divider,
            width: isActive ? 2.0 : 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                CreatureAvatar(creature: creature, size: 62),
                if (creature.isFavorite)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Text('⭐', style: TextStyle(fontSize: 14)),
                  ),
                if (isActive)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ON',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              creature.stage == CreatureStage.egg ? '알' : creature.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              creature.stage == CreatureStage.egg
                  ? creature.lineage.nameKo
                  : 'Lv.${creature.level} ${creature.stage.nameKo}',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 옵션 바텀시트 ──────────────────────────────────────────────────────────────
class _CreatureOptionsSheet extends ConsumerWidget {
  final CreatureModel creature;
  const _CreatureOptionsSheet({required this.creature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEgg = creature.stage == CreatureStage.egg;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CreatureAvatar(creature: creature, size: 56),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEgg ? '${creature.lineage.nameKo} 알' : creature.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      isEgg
                          ? '부화 대기 중'
                          : 'Lv.${creature.level} · ${creature.stage.nameKo}',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isEgg) ...[
              _OptionTile(
                icon: Icons.info_outline_rounded,
                label: '상세 보기 (스킬 · 특성 · 통계)',
                onTap: () {
                  Navigator.pop(context);
                  ref.read(collectionProvider.notifier).setActive(creature.id);
                  context.push('/creature');
                },
              ),
              _OptionTile(
                icon: Icons.star_outline_rounded,
                label: creature.isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
                onTap: () {
                  ref.read(collectionProvider.notifier).toggleFavorite(creature.id);
                  Navigator.pop(context);
                },
              ),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: '이름 변경',
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, ref);
                },
              ),
            ],
            if (isEgg)
              _OptionTile(
                icon: Icons.egg_alt_outlined,
                label: '부화시키기',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/hatch/${creature.id}');
                },
              ),
            _OptionTile(
              icon: Icons.logout_rounded,
              label: creature.isFavorite
                  ? '즐겨찾기 해제 후 놓아주기 가능'
                  : '놓아주기 (Lv.${creature.level} × 2 = ${creature.level * 2}석)',
              color: creature.isFavorite ? AppTheme.textHint : Colors.redAccent,
              onTap: creature.isFavorite
                  ? null
                  : () => _confirmRelease(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: creature.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '새 이름'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이름을 입력해주세요!')),
                );
                return;
              }
              ref.read(collectionProvider.notifier).rename(creature.id, name);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _confirmRelease(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('놓아주기'),
        content: Text(
          '"${creature.name}"을(를) 자연으로 돌려보낼까요?\n'
          '${creature.level * 2}개의 소환석을 받을 수 있어요.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 바텀시트 닫기
              final stones = await ref
                  .read(collectionProvider.notifier)
                  .release(creature.id);
              if (context.mounted && stones != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('💎 소환석 $stones개를 받았어요!')),
                );
              }
            },
            child: const Text('놓아주기'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (onTap == null ? AppTheme.textHint : AppTheme.textPrimary);
    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(label, style: TextStyle(color: effectiveColor)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
