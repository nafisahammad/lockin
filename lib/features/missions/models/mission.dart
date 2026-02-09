enum MissionPriority { low, medium, high }

class Mission {
  const Mission({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetDate,
    required this.priority,
    required this.completed,
    required this.createdAt,
    required this.isAnytime,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime targetDate;
  final MissionPriority priority;
  final bool completed;
  final DateTime createdAt;
  final bool isAnytime;
  final DateTime? completedAt;

  Mission copyWith({
    String? title,
    DateTime? targetDate,
    MissionPriority? priority,
    bool? completed,
    bool? isAnytime,
    DateTime? completedAt,
  }) {
    return Mission(
      id: id,
      userId: userId,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      isAnytime: isAnytime ?? this.isAnytime,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Mission.fromJson(String id, Map<String, dynamic> json) {
    return Mission(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      targetDate: DateTime.parse(json['targetDate'] as String),
      priority: MissionPriority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => MissionPriority.medium,
      ),
      completed: json['completed'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAnytime: json['isAnytime'] ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'targetDate': targetDate.toIso8601String(),
      'priority': priority.name,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'isAnytime': isAnytime,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
