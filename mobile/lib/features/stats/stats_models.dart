class MissionStreakEntry {
  final String title;
  final int currentStreak;
  final int longestStreak;
  final int completionCount;
  final String frequency;

  const MissionStreakEntry({
    required this.title,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionCount,
    required this.frequency,
  });

  factory MissionStreakEntry.fromJson(Map<String, dynamic> json) =>
      MissionStreakEntry(
        title:           json['title'] as String,
        currentStreak:   json['current_streak'] as int,
        longestStreak:   json['longest_streak'] as int,
        completionCount: json['completion_count'] as int,
        frequency:       json['frequency'] as String,
      );
}

class StatsSummary {
  final int totalXp;
  final int currentLevel;
  final String rank;
  final int goalsCompleted;
  final Map<String, int> goalsByDifficulty;
  final Map<String, int> goalsByCategory;
  final int missionsActive;
  final int totalCheckins;
  final int bestStreak;
  final int currentStreakMax;
  final List<MissionStreakEntry> topMissions;

  const StatsSummary({
    required this.totalXp,
    required this.currentLevel,
    required this.rank,
    required this.goalsCompleted,
    required this.goalsByDifficulty,
    required this.goalsByCategory,
    required this.missionsActive,
    required this.totalCheckins,
    required this.bestStreak,
    required this.currentStreakMax,
    required this.topMissions,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) => StatsSummary(
        totalXp:         json['total_xp'] as int,
        currentLevel:    json['current_level'] as int,
        rank:            json['rank'] as String,
        goalsCompleted:  json['goals_completed'] as int,
        goalsByDifficulty: Map<String, int>.from(
            json['goals_by_difficulty'] as Map),
        goalsByCategory: Map<String, int>.from(
            json['goals_by_category'] as Map),
        missionsActive:  json['missions_active'] as int,
        totalCheckins:   json['total_checkins'] as int,
        bestStreak:      json['best_streak'] as int,
        currentStreakMax: json['current_streak_max'] as int,
        topMissions: (json['top_missions'] as List)
            .map((e) => MissionStreakEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class XPDayEntry {
  final String date;
  final int xp;
  final int goalXp;
  final int missionXp;

  const XPDayEntry({
    required this.date,
    required this.xp,
    required this.goalXp,
    required this.missionXp,
  });

  factory XPDayEntry.fromJson(Map<String, dynamic> json) => XPDayEntry(
        date:      json['date'] as String,
        xp:        json['xp'] as int,
        goalXp:    json['goal_xp'] as int,
        missionXp: json['mission_xp'] as int,
      );
}

class XPHistory {
  final List<XPDayEntry> entries;
  final int totalXpInPeriod;
  final int days;

  const XPHistory({
    required this.entries,
    required this.totalXpInPeriod,
    required this.days,
  });

  factory XPHistory.fromJson(Map<String, dynamic> json) => XPHistory(
        entries: (json['entries'] as List)
            .map((e) => XPDayEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalXpInPeriod: json['total_xp_in_period'] as int,
        days:            json['days'] as int,
      );

  int get maxXp =>
      entries.isEmpty ? 1 : entries.map((e) => e.xp).reduce((a, b) => a > b ? a : b);
}
