import '../../domain/enums/mission_category.dart';

class MissionModel {
  final String id;
  final String title;
  final MissionCategory category;
  final int expReward;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final String? parentNote;
  final String? iconEmoji;

  const MissionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.expReward,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    this.parentNote,
    this.iconEmoji,
  });

  MissionModel copyWith({
    String? id,
    String? title,
    MissionCategory? category,
    int? expReward,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    String? parentNote,
    String? iconEmoji,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      expReward: expReward ?? this.expReward,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      parentNote: parentNote ?? this.parentNote,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'expReward': expReward,
    'isActive': isActive,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'parentNote': parentNote,
    'iconEmoji': iconEmoji,
  };

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: MissionCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => MissionCategory.water,
      ),
      expReward: json['expReward'] as int? ?? 10,
      isActive: json['isActive'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentNote: json['parentNote'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
    );
  }
}

// Default missions loaded on first launch
List<MissionModel> get defaultMissions => [
  MissionModel(
    id: 'default_1',
    title: '스스로 가방 챙기기',
    category: MissionCategory.electric,
    expReward: 15,
    isActive: true,
    isDefault: true,
    createdAt: DateTime.now(),
    iconEmoji: '🎒',
  ),
  MissionModel(
    id: 'default_2',
    title: '스스로 옷 입기',
    category: MissionCategory.electric,
    expReward: 10,
    isActive: true,
    isDefault: true,
    createdAt: DateTime.now(),
    iconEmoji: '👕',
  ),
  MissionModel(
    id: 'default_3',
    title: '책 읽기',
    category: MissionCategory.grass,
    expReward: 15,
    isActive: true,
    isDefault: true,
    createdAt: DateTime.now(),
    iconEmoji: '📚',
  ),
  MissionModel(
    id: 'default_4',
    title: '잠자리 전 이 닦기',
    category: MissionCategory.water,
    expReward: 10,
    isActive: true,
    isDefault: true,
    createdAt: DateTime.now(),
    iconEmoji: '🦷',
  ),
  MissionModel(
    id: 'default_5',
    title: '정리정돈',
    category: MissionCategory.water,
    expReward: 10,
    isActive: true,
    isDefault: true,
    createdAt: DateTime.now(),
    iconEmoji: '🧹',
  ),
];
