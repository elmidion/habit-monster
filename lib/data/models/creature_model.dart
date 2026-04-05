import '../../domain/enums/creature_stage.dart';
import '../../domain/enums/creature_type.dart';
import '../../domain/enums/lineage.dart';
import '../../domain/logic/exp_logic.dart';

class CreatureModel {
  final String id;
  final String name;
  final Lineage lineage;
  final CreatureStage stage;
  final CreatureType dominantType;
  final int level;
  final int currentExp;
  final int totalExpEarned;
  final int totalDaysActive;
  final bool isFavorite;
  final List<String> skillIds;
  final Map<String, int> categoryCompletionCount;
  final DateTime createdAt;
  final DateTime? hatchedAt;
  final DateTime? evolvedAt;
  /// 단계별 AI 생성 이미지 로컬 경로. key = CreatureStage.name (native)
  final Map<String, String> stageImagePaths;
  /// 단계별 AI 생성 이미지 Base64. key = CreatureStage.name (web + native)
  final Map<String, String> stageImageData;
  /// 스킬 선택 대기 중인 티어 목록 (비어있으면 대기 없음)
  final List<int> pendingSkillTiers;

  const CreatureModel({
    required this.id,
    required this.name,
    required this.lineage,
    required this.stage,
    required this.dominantType,
    required this.level,
    required this.currentExp,
    required this.totalExpEarned,
    required this.totalDaysActive,
    this.isFavorite = false,
    required this.skillIds,
    required this.categoryCompletionCount,
    required this.createdAt,
    this.hatchedAt,
    this.evolvedAt,
    this.stageImagePaths = const {},
    this.stageImageData = const {},
    this.pendingSkillTiers = const [],
  });

  int get expForNextLevel => ExpLogic.expRequiredForLevel(level);

  /// 현재 단계의 이미지 경로 (native)
  String? get currentImagePath => stageImagePaths[stage.name];

  /// 현재 단계의 Base64 이미지 데이터
  String? get currentImageBase64 => stageImageData[stage.name];

  CreatureModel copyWith({
    String? id,
    String? name,
    Lineage? lineage,
    CreatureStage? stage,
    CreatureType? dominantType,
    int? level,
    int? currentExp,
    int? totalExpEarned,
    int? totalDaysActive,
    bool? isFavorite,
    List<String>? skillIds,
    Map<String, int>? categoryCompletionCount,
    DateTime? createdAt,
    DateTime? hatchedAt,
    DateTime? evolvedAt,
    Map<String, String>? stageImagePaths,
    Map<String, String>? stageImageData,
    List<int>? pendingSkillTiers,
  }) {
    return CreatureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lineage: lineage ?? this.lineage,
      stage: stage ?? this.stage,
      dominantType: dominantType ?? this.dominantType,
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      totalExpEarned: totalExpEarned ?? this.totalExpEarned,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      isFavorite: isFavorite ?? this.isFavorite,
      skillIds: skillIds ?? this.skillIds,
      categoryCompletionCount: categoryCompletionCount ?? this.categoryCompletionCount,
      createdAt: createdAt ?? this.createdAt,
      hatchedAt: hatchedAt ?? this.hatchedAt,
      evolvedAt: evolvedAt ?? this.evolvedAt,
      stageImagePaths: stageImagePaths ?? this.stageImagePaths,
      stageImageData: stageImageData ?? this.stageImageData,
      pendingSkillTiers: pendingSkillTiers ?? this.pendingSkillTiers,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lineage': lineage.name,
    'stage': stage.name,
    'dominantType': dominantType.name,
    'level': level,
    'currentExp': currentExp,
    'totalExpEarned': totalExpEarned,
    'totalDaysActive': totalDaysActive,
    'isFavorite': isFavorite,
    'skillIds': skillIds,
    'categoryCompletionCount': categoryCompletionCount,
    'createdAt': createdAt.toIso8601String(),
    'hatchedAt': hatchedAt?.toIso8601String(),
    'evolvedAt': evolvedAt?.toIso8601String(),
    'stageImagePaths': stageImagePaths,
    'stageImageData': stageImageData,
    'pendingSkillTiers': pendingSkillTiers,
  };

  factory CreatureModel.fromJson(Map<String, dynamic> json) {
    return CreatureModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '몬스터',
      lineage: Lineage.values.firstWhere(
        (l) => l.name == json['lineage'],
        orElse: () => Lineage.dragon,
      ),
      stage: CreatureStage.values.firstWhere(
        (s) => s.name == json['stage'],
        orElse: () => CreatureStage.egg,
      ),
      dominantType: CreatureType.values.firstWhere(
        (t) => t.name == json['dominantType'],
        orElse: () => CreatureType.none,
      ),
      level: json['level'] as int? ?? 1,
      currentExp: json['currentExp'] as int? ?? 0,
      totalExpEarned: json['totalExpEarned'] as int? ?? 0,
      totalDaysActive: json['totalDaysActive'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      skillIds: List<String>.from(json['skillIds'] as List? ?? []),
      categoryCompletionCount: Map<String, int>.from(
        json['categoryCompletionCount'] as Map? ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      hatchedAt: json['hatchedAt'] != null
          ? DateTime.parse(json['hatchedAt'] as String)
          : null,
      evolvedAt: json['evolvedAt'] != null
          ? DateTime.parse(json['evolvedAt'] as String)
          : null,
      stageImagePaths: Map<String, String>.from(
        json['stageImagePaths'] as Map? ?? {},
      ),
      stageImageData: Map<String, String>.from(
        json['stageImageData'] as Map? ?? {},
      ),
      pendingSkillTiers: List<int>.from(
        json['pendingSkillTiers'] as List? ?? [],
      ),
    );
  }

  factory CreatureModel.newEgg({required String id, required Lineage lineage}) {
    return CreatureModel(
      id: id,
      name: '알',
      lineage: lineage,
      stage: CreatureStage.egg,
      dominantType: CreatureType.none,
      level: 1,
      currentExp: 0,
      totalExpEarned: 0,
      totalDaysActive: 0,
      skillIds: [],
      categoryCompletionCount: {},
      createdAt: DateTime.now(),
    );
  }
}
