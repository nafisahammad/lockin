class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.disciplineScore,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalFocusMinutes,
  });

  final String id;
  final String name;
  final String email;
  final int disciplineScore;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalFocusMinutes;

  UserProfile copyWith({
    String? name,
    String? email,
    int? disciplineScore,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? totalFocusMinutes,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      disciplineScore: disciplineScore ?? this.disciplineScore,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
    );
  }

  factory UserProfile.fromJson(String id, Map<String, dynamic> json) {
    return UserProfile(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      disciplineScore: (json['disciplineScore'] ?? 0) as int,
      level: (json['level'] ?? 1) as int,
      currentStreak: (json['currentStreak'] ?? 0) as int,
      longestStreak: (json['longestStreak'] ?? 0) as int,
      totalFocusMinutes: (json['totalFocusMinutes'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'disciplineScore': disciplineScore,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalFocusMinutes': totalFocusMinutes,
    };
  }
}
