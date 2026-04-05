import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/mission_model.dart';

class MissionTile extends StatelessWidget {
  final MissionModel mission;
  final bool isCompleted;
  final VoidCallback? onComplete;

  const MissionTile({
    super.key,
    required this.mission,
    required this.isCompleted,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = mission.category;
    final color = cat.color;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCompleted ? 0.55 : 1.0,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isCompleted
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onComplete?.call();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      mission.iconEmoji ?? cat.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cat.nameKo,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${mission.expReward} EXP',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Completion indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isCompleted
                      ? Container(
                          key: const ValueKey('done'),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20),
                        ).animate().scale(duration: 250.ms, curve: Curves.elasticOut)
                      : Container(
                          key: const ValueKey('todo'),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: color.withOpacity(0.5), width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_rounded,
                              color: color.withOpacity(0.7), size: 20),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
