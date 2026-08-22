class SkillResponse {
  final String id;
  final String name;
  final String description;
  final String category;
  final String emoji;
  final int sortOrder;

  const SkillResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
    required this.sortOrder,
  });

  factory SkillResponse.fromJson(Map<String, dynamic> json) => SkillResponse(
        id:          json['id'] as String,
        name:        json['name'] as String,
        description: json['description'] as String,
        category:    json['category'] as String,
        emoji:       json['emoji'] as String,
        sortOrder:   json['sort_order'] as int,
      );
}

class UserSkillResponse {
  final String id;
  final String userId;
  final String skillId;
  final int level;
  final int sessionCount;
  final int totalXpEarned;
  final String? lastPracticedAt;
  final SkillResponse skill;
  final int sessionsToNextLevel;
  final int xpPerSession;

  const UserSkillResponse({
    required this.id,
    required this.userId,
    required this.skillId,
    required this.level,
    required this.sessionCount,
    required this.totalXpEarned,
    this.lastPracticedAt,
    required this.skill,
    required this.sessionsToNextLevel,
    required this.xpPerSession,
  });

  factory UserSkillResponse.fromJson(Map<String, dynamic> json) => UserSkillResponse(
        id:                  json['id'] as String,
        userId:              json['user_id'] as String,
        skillId:             json['skill_id'] as String,
        level:               json['level'] as int,
        sessionCount:        json['session_count'] as int,
        totalXpEarned:       json['total_xp_earned'] as int,
        lastPracticedAt:     json['last_practiced_at'] as String?,
        skill:               SkillResponse.fromJson(json['skill'] as Map<String, dynamic>),
        sessionsToNextLevel: json['sessions_to_next_level'] as int,
        xpPerSession:        json['xp_per_session'] as int,
      );
}

class PracticeResult {
  final UserSkillResponse userSkill;
  final int xpAwarded;
  final List<int> levelsGained;
  final bool leveledUp;

  const PracticeResult({
    required this.userSkill,
    required this.xpAwarded,
    required this.levelsGained,
    required this.leveledUp,
  });

  factory PracticeResult.fromJson(Map<String, dynamic> json) => PracticeResult(
        userSkill:   UserSkillResponse.fromJson(json['user_skill'] as Map<String, dynamic>),
        xpAwarded:   json['xp_awarded'] as int,
        levelsGained:(json['levels_gained'] as List).cast<int>(),
        leveledUp:   json['leveled_up'] as bool,
      );
}
