enum HabitDifficulty { easy, medium, hard }

enum HabitTimeOfDay { morning, afternoon, night }

class Habit {
  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.timeOfDay,
    required this.identityTag,
    required this.reminderEnabled,
  });

  final String id;
  final String userId;
  final String title;
  final String category;
  final HabitDifficulty difficulty;
  final HabitTimeOfDay timeOfDay;
  final String identityTag;
  final bool reminderEnabled;

  Habit copyWith({
    String? title,
    String? category,
    HabitDifficulty? difficulty,
    HabitTimeOfDay? timeOfDay,
    String? identityTag,
    bool? reminderEnabled,
  }) {
    return Habit(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      identityTag: identityTag ?? this.identityTag,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  factory Habit.fromJson(String id, Map<String, dynamic> json) {
    return Habit(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Custom',
      difficulty: HabitDifficulty.values.firstWhere(
        (value) => value.name == json['difficulty'],
        orElse: () => HabitDifficulty.easy,
      ),
      timeOfDay: HabitTimeOfDay.values.firstWhere(
        (value) => value.name == json['timeOfDay'],
        orElse: () => HabitTimeOfDay.morning,
      ),
      identityTag: json['identityTag'] ?? '',
      reminderEnabled: json['reminderEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'difficulty': difficulty.name,
      'timeOfDay': timeOfDay.name,
      'identityTag': identityTag,
      'reminderEnabled': reminderEnabled,
    };
  }
}
