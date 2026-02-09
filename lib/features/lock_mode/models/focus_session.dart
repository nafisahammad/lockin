class FocusSession {
  const FocusSession({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.date,
    this.relatedHabitId,
  });

  final String id;
  final String userId;
  final int durationMinutes;
  final DateTime date;
  final String? relatedHabitId;

  factory FocusSession.fromJson(String id, Map<String, dynamic> json) {
    return FocusSession(
      id: id,
      userId: json['userId'] ?? '',
      durationMinutes: (json['durationMinutes'] ?? 0) as int,
      date: DateTime.parse(json['date'] as String),
      relatedHabitId: json['relatedHabitId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
      'relatedHabitId': relatedHabitId,
    };
  }
}
