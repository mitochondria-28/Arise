class AchievementResponse {
  final String key;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int threshold;
  final DateTime? unlockedAt;

  const AchievementResponse({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.threshold,
    this.unlockedAt,
  });

  factory AchievementResponse.fromJson(Map<String, dynamic> json) =>
      AchievementResponse(
        key:         json['key'] as String,
        title:       json['title'] as String,
        description: json['description'] as String,
        icon:        json['icon'] as String,
        category:    json['category'] as String,
        threshold:   json['threshold'] as int,
        unlockedAt:  json['unlocked_at'] != null
            ? DateTime.parse(json['unlocked_at'] as String)
            : null,
      );

  bool get isUnlocked => unlockedAt != null;
}

class SyncResult {
  final List<AchievementResponse> newlyUnlocked;
  final int totalUnlocked;

  const SyncResult({
    required this.newlyUnlocked,
    required this.totalUnlocked,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        newlyUnlocked: (json['newly_unlocked'] as List)
            .map((e) => AchievementResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalUnlocked: json['total_unlocked'] as int,
      );
}
