class DailyLog {
  const DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.completedHabits,
    required this.missedHabits,
    required this.reflectionAnswers,
  });

  final String id;
  final String userId;
  final DateTime date;
  final List<String> completedHabits;
  final List<String> missedHabits;
  final Map<String, String> reflectionAnswers;

  factory DailyLog.fromJson(String id, Map<String, dynamic> json) {
    return DailyLog(
      id: id,
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date'] as String),
      completedHabits: List<String>.from(json['completedHabits'] ?? []),
      missedHabits: List<String>.from(json['missedHabits'] ?? []),
      reflectionAnswers: Map<String, String>.from(
        json['reflectionAnswers'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'completedHabits': completedHabits,
      'missedHabits': missedHabits,
      'reflectionAnswers': reflectionAnswers,
    };
  }
}
