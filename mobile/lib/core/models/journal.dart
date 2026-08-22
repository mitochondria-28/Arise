class JournalEntry {
  final String id;
  final String userId;
  final String entryDate;   // YYYY-MM-DD
  final String content;
  final int? mood;           // 1–5 or null
  final String? aiReflection;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.content,
    this.mood,
    this.aiReflection,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id:           json['id'] as String,
        userId:       json['user_id'] as String,
        entryDate:    json['entry_date'] as String,
        content:      json['content'] as String,
        mood:         json['mood'] as int?,
        aiReflection: json['ai_reflection'] as String?,
        createdAt:    DateTime.parse(json['created_at'] as String),
        updatedAt:    DateTime.parse(json['updated_at'] as String),
      );

  bool get hasReflection => aiReflection != null && aiReflection!.isNotEmpty;

  JournalEntry copyWith({String? aiReflection, int? mood, String? content}) =>
      JournalEntry(
        id:           id,
        userId:       userId,
        entryDate:    entryDate,
        content:      content ?? this.content,
        mood:         mood ?? this.mood,
        aiReflection: aiReflection ?? this.aiReflection,
        createdAt:    createdAt,
        updatedAt:    updatedAt,
      );
}

class JournalListResult {
  final List<JournalEntry> entries;
  final int total;
  final int streak;

  const JournalListResult({
    required this.entries,
    required this.total,
    required this.streak,
  });

  factory JournalListResult.fromJson(Map<String, dynamic> json) =>
      JournalListResult(
        entries: (json['entries'] as List)
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        total:  json['total'] as int,
        streak: json['streak'] as int,
      );
}
