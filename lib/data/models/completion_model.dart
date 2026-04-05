import '../../domain/enums/mission_category.dart';

class CompletionModel {
  final String id;
  final String missionId;
  final DateTime completedAt;
  final MissionCategory category;
  final int expAwarded;
  final bool wasStreakBonus;

  const CompletionModel({
    required this.id,
    required this.missionId,
    required this.completedAt,
    required this.category,
    required this.expAwarded,
    required this.wasStreakBonus,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mission_id': missionId,
    'completed_at': completedAt.millisecondsSinceEpoch,
    'category': category.name,
    'exp_awarded': expAwarded,
    'streak_bonus': wasStreakBonus ? 1 : 0,
  };

  factory CompletionModel.fromMap(Map<String, dynamic> map) {
    return CompletionModel(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
      category: MissionCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => MissionCategory.water,
      ),
      expAwarded: map['exp_awarded'] as int? ?? 0,
      wasStreakBonus: (map['streak_bonus'] as int? ?? 0) == 1,
    );
  }
}
