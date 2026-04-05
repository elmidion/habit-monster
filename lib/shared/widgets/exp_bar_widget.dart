import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ExpBarWidget extends StatelessWidget {
  final int level;
  final int currentExp;
  final int requiredExp;
  final bool compact;

  const ExpBarWidget({
    super.key,
    required this.level,
    required this.currentExp,
    required this.requiredExp,
    // ignore type for backwards compat
    dynamic type,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentExp / requiredExp.clamp(1, 99999)).clamp(0.0, 1.0);
    final barColor = AppTheme.primary;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lv.$level',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: barColor,
                        fontSize: 13,
                      )),
              Text('$currentExp / $requiredExp EXP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      )),
            ],
          ),
          const SizedBox(height: 4),
          _Bar(progress: progress, color: barColor, height: 8),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Lv.$level',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
            ]),
            Text('$currentExp / $requiredExp EXP',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    )),
          ],
        ),
        const SizedBox(height: 8),
        _Bar(progress: progress, color: barColor, height: 12),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const _Bar(
      {required this.progress, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            width: box.maxWidth * progress,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, Colors.white, 0.3)!],
              ),
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
