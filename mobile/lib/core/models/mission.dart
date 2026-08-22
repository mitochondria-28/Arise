class MissionResponse {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String frequency;
  final String difficulty;
  final String status;
  final int targetCount;
  final int completionCount;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedAt;
  final bool canCheckinNow;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MissionResponse({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    required this.difficulty,
    required this.status,
    required this.targetCount,
    required this.completionCount,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedAt,
    required this.canCheckinNow,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MissionResponse.fromJson(Map<String, dynamic> json) => MissionResponse(
        id:               json['id'] as String,
        userId:           json['user_id'] as String,
        title:            json['title'] as String,
        description:      json['description'] as String?,
        category:         json['category'] as String,
        frequency:        json['frequency'] as String,
        difficulty:       json['difficulty'] as String,
        status:           json['status'] as String,
        targetCount:      json['target_count'] as int,
        completionCount:  json['completion_count'] as int,
        currentStreak:    json['current_streak'] as int,
        longestStreak:    json['longest_streak'] as int,
        lastCompletedAt:  json['last_completed_at'] != null
            ? DateTime.parse(json['last_completed_at'] as String)
            : null,
        canCheckinNow:    (json['can_checkin_now'] as bool?) ?? true,
        createdAt:        DateTime.parse(json['created_at'] as String),
        updatedAt:        DateTime.parse(json['updated_at'] as String),
      );

  bool get isActive => status == 'active';
}

class MissionTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String frequency;
  final String emoji;
  final int sortOrder;

  const MissionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.frequency,
    required this.emoji,
    required this.sortOrder,
  });

  factory MissionTemplate.fromJson(Map<String, dynamic> json) => MissionTemplate(
        id:          json['id'] as String,
        title:       json['title'] as String,
        description: json['description'] as String,
        category:    json['category'] as String,
        difficulty:  json['difficulty'] as String,
        frequency:   json['frequency'] as String,
        emoji:       json['emoji'] as String,
        sortOrder:   json['sort_order'] as int,
      );
}

class CreateMissionRequest {
  final String title;
  final String? description;
  final String category;
  final String frequency;
  final String difficulty;

  const CreateMissionRequest({
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description?.isNotEmpty == true) 'description': description,
        'category': category,
        'frequency': frequency,
        'difficulty': difficulty,
        'target_count': 0,
      };
}

class CheckinRequest {
  final String evidenceText;
  final String? reflection;
  final int effortLevel;

  const CheckinRequest({
    required this.evidenceText,
    this.reflection,
    required this.effortLevel,
  });

  Map<String, dynamic> toJson() => {
        'evidence_text': evidenceText,
        if (reflection?.isNotEmpty == true) 'reflection': reflection,
        'effort_level': effortLevel,
      };
}

class CheckinResponse {
  final MissionResponse mission;
  final int xpAwarded;
  final int newStreak;
  final List<int> levelsGained;

  const CheckinResponse({
    required this.mission,
    required this.xpAwarded,
    required this.newStreak,
    required this.levelsGained,
  });

  factory CheckinResponse.fromJson(Map<String, dynamic> json) => CheckinResponse(
        mission:     MissionResponse.fromJson(json['mission'] as Map<String, dynamic>),
        xpAwarded:   json['xp_awarded'] as int,
        newStreak:   json['new_streak'] as int,
        levelsGained:(json['levels_gained'] as List).cast<int>(),
      );

  bool get leveledUp => levelsGained.isNotEmpty;
}
