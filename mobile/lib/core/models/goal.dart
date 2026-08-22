class GoalResponse {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final String status;
  final DateTime? targetDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalResponse({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    required this.status,
    this.targetDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalResponse.fromJson(Map<String, dynamic> json) => GoalResponse(
        id:          json['id'] as String,
        userId:      json['user_id'] as String,
        title:       json['title'] as String,
        description: json['description'] as String?,
        category:    json['category'] as String,
        difficulty:  json['difficulty'] as String,
        status:      json['status'] as String,
        targetDate:  json['target_date'] != null
            ? DateTime.parse(json['target_date'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt:   DateTime.parse(json['created_at'] as String),
        updatedAt:   DateTime.parse(json['updated_at'] as String),
      );

  bool get isActive    => status == 'active';
  bool get isCompleted => status == 'completed';
}

class CreateGoalRequest {
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final String? targetDate;

  const CreateGoalRequest({
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    this.targetDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description?.isNotEmpty == true) 'description': description,
        'category': category,
        'difficulty': difficulty,
        if (targetDate != null) 'target_date': targetDate,
      };
}

class CompleteGoalRequest {
  final String evidenceText;
  final String? reflection;
  final int effortLevel;

  const CompleteGoalRequest({
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

class GoalTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String emoji;
  final int sortOrder;

  const GoalTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.emoji,
    required this.sortOrder,
  });

  factory GoalTemplate.fromJson(Map<String, dynamic> json) => GoalTemplate(
        id:          json['id'] as String,
        title:       json['title'] as String,
        description: json['description'] as String,
        category:    json['category'] as String,
        difficulty:  json['difficulty'] as String,
        emoji:       json['emoji'] as String,
        sortOrder:   json['sort_order'] as int,
      );
}

class GoalMilestone {
  final String id;
  final String goalId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int sortOrder;

  const GoalMilestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.sortOrder,
  });

  factory GoalMilestone.fromJson(Map<String, dynamic> json) => GoalMilestone(
        id:          json['id'] as String,
        goalId:      json['goal_id'] as String,
        title:       json['title'] as String,
        description: json['description'] as String?,
        isCompleted: json['is_completed'] as bool,
        sortOrder:   json['sort_order'] as int,
      );

  GoalMilestone copyWith({bool? isCompleted}) => GoalMilestone(
        id:          id,
        goalId:      goalId,
        title:       title,
        description: description,
        isCompleted: isCompleted ?? this.isCompleted,
        sortOrder:   sortOrder,
      );
}

class CompleteGoalResponse {
  final GoalResponse goal;
  final int xpAwarded;
  final List<int> levelsGained;

  const CompleteGoalResponse({
    required this.goal,
    required this.xpAwarded,
    required this.levelsGained,
  });

  factory CompleteGoalResponse.fromJson(Map<String, dynamic> json) =>
      CompleteGoalResponse(
        goal:         GoalResponse.fromJson(json['goal'] as Map<String, dynamic>),
        xpAwarded:    json['xp_awarded'] as int,
        levelsGained: (json['levels_gained'] as List).cast<int>(),
      );

  bool get leveledUp => levelsGained.isNotEmpty;
}
