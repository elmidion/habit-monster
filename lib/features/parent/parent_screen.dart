import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/storage/database_service.dart';
import '../../core/storage/hive_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/coin_provider.dart';
import '../../core/utils/app_clock.dart';
import '../../data/models/mission_model.dart';
import '../../data/providers/completions_provider.dart';
import '../../data/providers/collection_provider.dart';
import '../../data/providers/missions_provider.dart';
import '../../core/services/image_gen_service.dart';
import '../../domain/logic/exp_logic.dart';
import '../../domain/enums/mission_category.dart';

class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  bool _unlocked = false;
  final _pinController = TextEditingController();
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String get _savedPin =>
      HiveService.settings.get(AppConstants.keyParentPin,
          defaultValue: AppConstants.defaultParentPin) as String;

  void _tryUnlock() {
    if (_pinController.text == _savedPin) {
      setState(() {
        _unlocked = true;
        _pinError = null;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() => _pinError = '잘못된 PIN이에요.');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) return _buildPinScreen(context);
    return _buildManageScreen(context);
  }

  // ── PIN gate ──────────────────────────────────────────────────────────────
  Widget _buildPinScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부모 모드')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text('PIN을 입력해주세요',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_savedPin == AppConstants.defaultParentPin)
              Text('기본 PIN: ${AppConstants.defaultParentPin}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              onSubmitted: (_) => _tryUnlock(),
              decoration: InputDecoration(
                hintText: '••••',
                errorText: _pinError,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _tryUnlock,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _tryUnlock,
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main manage screen ────────────────────────────────────────────────────
  Widget _buildManageScreen(BuildContext context) {
    final missions = ref.watch(missionsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔓 부모 모드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/report'),
            tooltip: '습관 리포트',
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () => _showChangePinDialog(context),
            tooltip: 'PIN 변경',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddMissionDialog(context),
            tooltip: '미션 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          if (kDebugMode) _buildDebugDatePanel(),
          _buildApiKeyPanel(),
          const _CoinManagePanel(),
          const _DataManagePanel(),
          Expanded(
            child: missions.isEmpty
                ? const Center(child: Text('미션이 없어요.'))
                : ReorderableListView.builder(
                    itemCount: missions.length,
                    onReorder: (_, __) {},
                    itemBuilder: (_, i) {
                      final m = missions[i];
                      return _MissionManageTile(
                        key: ValueKey(m.id),
                        mission: m,
                        onToggle: (active) => ref
                            .read(missionsProvider.notifier)
                            .setActive(m.id, active: active),
                        onDelete: m.isDefault
                            ? null
                            : () => _confirmDelete(context, m),
                        onEdit: () => _showEditDialog(context, m),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── OpenAI API 키 설정 ────────────────────────────────────────────────────
  Widget _buildApiKeyPanel() => const _ApiKeyPanel();

  // ── Debug panel (debug mode only) ────────────────────────────────────────
  Widget _buildDebugDatePanel() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        final offset = AppClock.offsetDays;
        final date = AppClock.now();
        final label =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return Container(
          color: Colors.amber.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 조절
              Row(
                children: [
                  const Text('🗓 날짜', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 13)),
                  if (offset != 0)
                    Text(' (${offset > 0 ? '+$offset' : '$offset'}일)',
                        style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () { AppClock.subtractDay(); _invalidateProviders(); setLocal(() {}); },
                    tooltip: '하루 전',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () { AppClock.addDay(); _invalidateProviders(); setLocal(() {}); },
                    tooltip: '하루 후',
                  ),
                  if (offset != 0)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () { AppClock.reset(); _invalidateProviders(); setLocal(() {}); },
                      tooltip: '오늘로',
                    ),
                ],
              ),
              // EXP 주입
              Row(
                children: [
                  const Text('⚡ EXP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  for (final amount in [50, 100, 500])
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _addExp(context, amount),
                        child: Text('+$amount'),
                      ),
                    ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      final creature = ref.read(activeCreatureProvider);
                      if (creature == null) return;
                      final needed = ExpLogic.expRequiredForLevel(creature.level) - creature.currentExp;
                      await _addExp(context, needed.toInt());
                    },
                    child: const Text('레벨업'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addExp(BuildContext context, int amount) async {
    final result = await ref.read(collectionProvider.notifier).debugAddExp(amount);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.didEvolve
            ? '🎉 진화! +$amount EXP → Lv${result.newLevel}'
            : result.didLevelUp
                ? '🆙 레벨업! +$amount EXP → Lv${result.newLevel}'
                : '+$amount EXP 추가'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _invalidateProviders() {
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(todayCompletedIdsProvider);
    ref.invalidate(allCompletionsProvider);
    ref.invalidate(streakProvider);
  }

  void _confirmDelete(BuildContext context, MissionModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('미션 삭제'),
        content: Text('"${m.title}"을(를) 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () {
              ref.read(missionsProvider.notifier).delete(m.id);
              Navigator.pop(context);
            },
            child:
                const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('PIN 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '현재 PIN',
                  hintText: '••••',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '새 PIN',
                  hintText: '4~6자리 숫자',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '새 PIN 확인',
                  hintText: '다시 입력',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final currentPin = currentPinCtrl.text.trim();
                final newPin = newPinCtrl.text.trim();
                final confirmPin = confirmPinCtrl.text.trim();

                if (currentPin != _savedPin) {
                  setDialogState(() => error = '현재 PIN이 틀려요.');
                  return;
                }
                if (newPin.length < 4) {
                  setDialogState(() => error = '4자리 이상 입력해주세요.');
                  return;
                }
                if (newPin != confirmPin) {
                  setDialogState(() => error = '새 PIN이 일치하지 않아요.');
                  return;
                }

                HiveService.settings.put(AppConstants.keyParentPin, newPin);
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('PIN이 변경되었어요!')),
                );
              },
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMissionDialog(BuildContext context) {
    _MissionFormDialog.show(context, ref);
  }

  void _showEditDialog(BuildContext context, MissionModel m) {
    _MissionFormDialog.show(context, ref, existing: m);
  }
}

// ── Mission tile for parent management ────────────────────────────────────────
class _MissionManageTile extends StatelessWidget {
  final MissionModel mission;
  final void Function(bool) onToggle;
  final VoidCallback? onDelete;
  final VoidCallback onEdit;

  const _MissionManageTile({
    super.key,
    required this.mission,
    required this.onToggle,
    this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(mission.iconEmoji ?? mission.category.emoji,
            style: const TextStyle(fontSize: 24)),
        title: Text(mission.title,
            style: TextStyle(
                decoration:
                    mission.isActive ? null : TextDecoration.lineThrough,
                color: mission.isActive
                    ? AppTheme.textPrimary
                    : AppTheme.textHint)),
        subtitle: Text(
          '${mission.category.nameKo}  •  +${mission.expReward} EXP',
          style: TextStyle(
              color: mission.category.color,
              fontSize: 12,
              fontWeight: FontWeight.w700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: mission.isActive,
              onChanged: onToggle,
              activeThumbColor: AppTheme.primary,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppTheme.textSecondary, size: 20),
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit mission dialog ──────────────────────────────────────────────────
class _MissionFormDialog extends ConsumerStatefulWidget {
  final MissionModel? existing;
  const _MissionFormDialog({this.existing});

  static void show(BuildContext context, WidgetRef ref,
      {MissionModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _MissionFormDialog(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<_MissionFormDialog> createState() =>
      _MissionFormDialogState();
}

class _MissionFormDialogState extends ConsumerState<_MissionFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _exp;
  late MissionCategory _category;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _exp = TextEditingController(
        text: '${widget.existing?.expReward ?? 10}');
    _category = widget.existing?.category ?? MissionCategory.water;
  }

  @override
  void dispose() {
    _title.dispose();
    _exp.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final exp = int.tryParse(_exp.text) ?? 10;

    if (_isEdit) {
      ref.read(missionsProvider.notifier).updateMission(
            widget.existing!.copyWith(
              title: title,
              category: _category,
              expReward: exp.clamp(5, 50),
            ),
          );
    } else {
      ref.read(missionsProvider.notifier).addMission(
            title: title,
            category: _category,
            expReward: exp.clamp(5, 50),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEdit ? '미션 수정' : '미션 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: '미션 이름', hintText: '예: 책 읽기'),
              maxLength: 30,
            ),
            const SizedBox(height: 12),
            const Text('카테고리',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MissionCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? cat.color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text('${cat.emoji} ${cat.nameKo}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? cat.color
                                : AppTheme.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'EXP 보상',
                hintText: '5 ~ 50',
                suffixText: 'EXP',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? '저장' : '추가'),
        ),
      ],
    );
  }
}

// ── OpenAI API 키 패널 ─────────────────────────────────────────────────────────
class _ApiKeyPanel extends StatefulWidget {
  const _ApiKeyPanel();

  @override
  State<_ApiKeyPanel> createState() => _ApiKeyPanelState();
}

class _ApiKeyPanelState extends State<_ApiKeyPanel> {
  late final TextEditingController _ctrl;
  bool _obscure = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ImageGenService.apiKey ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎨 AI 이미지 생성 (DALL-E 3)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 2),
          const Text('부화 및 진화 시 캐릭터 이미지를 자동 생성합니다.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                obscureText: _obscure,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'sk-...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    iconSize: 18,
                  ),
                ),
                onChanged: (_) => setState(() => _saved = false),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                await ImageGenService.setApiKey(_ctrl.text);
                setState(() => _saved = true);
              },
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12)),
              child: const Text('저장'),
            ),
          ]),
          if (_saved)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('✅ 저장됐어요!',
                  style: TextStyle(fontSize: 11, color: Colors.green)),
            ),
        ],
      ),
    );
  }
}

// ── 코인 관리 패널 ────────────────────────────────────────────────────────────
class _CoinManagePanel extends ConsumerStatefulWidget {
  const _CoinManagePanel();

  @override
  ConsumerState<_CoinManagePanel> createState() => _CoinManagePanelState();
}

class _CoinManagePanelState extends ConsumerState<_CoinManagePanel> {
  bool _expanded = false;

  String _formatWon(int won) {
    return won.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(coinBalanceProvider);
    final rate = ref.watch(coinExchangeRateProvider);
    final coinPerMission = ref.watch(coinPerMissionProvider);
    final history = ref.watch(exchangeHistoryProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('🪙 용돈 코인',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(width: 8),
                  Text('$balance코인',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.amber.shade800)),
                  const SizedBox(width: 4),
                  Text('(${_formatWon(balance * rate)}원)',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade700)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: Colors.amber.shade700),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('미션당 코인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      _StepperButton(
                        value: coinPerMission,
                        min: 1, max: 10,
                        onChanged: (v) => ref.read(coinPerMissionProvider.notifier).set(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('코인 1개 = ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      _StepperButton(
                        value: rate,
                        min: 10, max: 1000, step: 10, suffix: '원',
                        onChanged: (v) => ref.read(coinExchangeRateProvider.notifier).setRate(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: balance > 0 ? () => _showExchangeDialog(context, balance, rate) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber.shade800,
                        side: BorderSide(color: Colors.amber.shade300),
                      ),
                      child: Text('용돈 교환하기 ($balance코인 → ${_formatWon(balance * rate)}원)'),
                    ),
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('교환 내역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...history.reversed.take(5).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('${r.date.month}/${r.date.day}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(width: 8),
                          Text('${r.coins}코인 → ${_formatWon(r.won)}원',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExchangeDialog(BuildContext context, int balance, int rate) {
    final ctrl = TextEditingController(text: '$balance');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('용돈 교환'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '교환할 코인 수',
                hintText: '최대 $balance',
                suffixText: '코인',
              ),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setLocal) {
                ctrl.addListener(() => setLocal(() {}));
                final coins = int.tryParse(ctrl.text) ?? 0;
                return Text(
                  '= ${_formatWon(coins * rate)}원',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Colors.amber.shade800),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final coins = int.tryParse(ctrl.text) ?? 0;
              if (coins <= 0 || coins > balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 코인 수를 입력해주세요.')),
                );
                return;
              }
              ref.read(exchangeHistoryProvider.notifier).exchange(coins);
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('${_formatWon(coins * rate)}원 교환 완료!')),
              );
            },
            child: const Text('교환'),
          ),
        ],
      ),
    );
  }
}

// ── 증감 버튼 ─────────────────────────────────────────────────────────────────
class _StepperButton extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  const _StepperButton({
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
          visualDensity: VisualDensity.compact,
        ),
        Text('$value${suffix ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── 데이터 관리 패널 ──────────────────────────────────────────────────────────
class _DataManagePanel extends ConsumerWidget {
  const _DataManagePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💾 데이터 관리',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportBackup(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('백업'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importBackup(context, ref),
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('복원'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, ref),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('초기화'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final data = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'creatures': HiveService.creature.get('collection'),
        'missions': HiveService.missions.toMap(),
        'badges': HiveService.badges.get('list'),
        'settings': HiveService.settings.toMap(),
        'completions': await DatabaseService.exportAll(),
      };
      final json = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: json));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('백업 데이터가 클립보드에 복사되었어요!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 실패: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('데이터 복원'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('백업 JSON을 붙여넣어주세요.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{"version":1, ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('복원')),
        ],
      ),
    );

    if (confirmed != true || ctrl.text.trim().isEmpty) return;

    try {
      final data = jsonDecode(ctrl.text.trim()) as Map<String, dynamic>;

      if (data['creatures'] != null) {
        await HiveService.creature.put('collection', data['creatures']);
      }
      if (data['missions'] != null) {
        final missions = Map<String, dynamic>.from(data['missions'] as Map);
        for (final entry in missions.entries) {
          await HiveService.missions.put(entry.key, entry.value);
        }
      }
      if (data['badges'] != null) {
        await HiveService.badges.put('list', data['badges']);
      }
      if (data['settings'] != null) {
        final settings = Map<String, dynamic>.from(data['settings'] as Map);
        for (final entry in settings.entries) {
          await HiveService.settings.put(entry.key, entry.value);
        }
      }
      if (data['completions'] != null) {
        final completions = (data['completions'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await DatabaseService.importAll(completions);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원 완료! 앱을 다시 시작해주세요.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원 실패: 올바른 JSON인지 확인해주세요.')),
        );
      }
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('데이터 초기화'),
        content: const Text(
          '모든 데이터가 삭제됩니다.\n크리처, 미션 기록, 뱃지, 코인이 모두 사라져요.\n\n정말 초기화할까요?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              await HiveService.creature.clear();
              await HiveService.missions.clear();
              await HiveService.badges.clear();
              await HiveService.settings.clear();
              await DatabaseService.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('초기화 완료! 앱을 다시 시작해주세요.')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}
