const _statOrder = [
  'vitality', 'strength', 'intelligence', 'wisdom', 'charisma', 'discipline'
];

class CharacterStats {
  final int vitality;
  final int strength;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final int discipline;

  const CharacterStats({
    required this.vitality,
    required this.strength,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.discipline,
  });

  factory CharacterStats.fromJson(Map<String, dynamic> json) => CharacterStats(
        vitality:     (json['vitality']     as int? ?? 0),
        strength:     (json['strength']     as int? ?? 0),
        intelligence: (json['intelligence'] as int? ?? 0),
        wisdom:       (json['wisdom']       as int? ?? 0),
        charisma:     (json['charisma']     as int? ?? 0),
        discipline:   (json['discipline']   as int? ?? 0),
      );

  int valueOf(String category) {
    switch (category) {
      case 'vitality':      return vitality;
      case 'strength':      return strength;
      case 'intelligence':  return intelligence;
      case 'wisdom':        return wisdom;
      case 'charisma':      return charisma;
      case 'discipline':    return discipline;
      default:              return 0;
    }
  }

  // Ordered list for display (preserves canonical order)
  List<MapEntry<String, int>> toOrderedList() =>
      _statOrder.map((k) => MapEntry(k, valueOf(k))).toList();
}

class CharacterResponse {
  final String id;
  final String userId;
  final String title;
  final int level;
  final String rank;
  final int totalXp;
  final int currentLevelXp;
  final int xpToNextLevel;
  final CharacterStats? stats;

  const CharacterResponse({
    required this.id,
    required this.userId,
    required this.title,
    required this.level,
    required this.rank,
    required this.totalXp,
    required this.currentLevelXp,
    required this.xpToNextLevel,
    this.stats,
  });

  factory CharacterResponse.fromJson(Map<String, dynamic> json) => CharacterResponse(
        id:             json['id'] as String,
        userId:         json['user_id'] as String,
        title:          json['title'] as String,
        level:          json['level'] as int,
        rank:           json['rank'] as String,
        totalXp:        json['total_xp'] as int,
        currentLevelXp: json['current_level_xp'] as int,
        xpToNextLevel:  json['xp_to_next_level'] as int,
        stats: json['stats'] != null
            ? CharacterStats.fromJson(json['stats'] as Map<String, dynamic>)
            : null,
      );

  double get xpProgress {
    if (xpToNextLevel <= 0) return 1.0;
    return (currentLevelXp / xpToNextLevel).clamp(0.0, 1.0);
  }
}
