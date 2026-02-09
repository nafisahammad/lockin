import 'package:intl/intl.dart';

import 'constants.dart';
import '../features/habits/models/habit.dart';
import '../features/missions/models/mission.dart';
import '../features/reflection/models/daily_log.dart';

class DisciplineLogic {
  static int pointsForDifficulty(HabitDifficulty difficulty) {
    switch (difficulty) {
      case HabitDifficulty.easy:
        return 5;
      case HabitDifficulty.medium:
        return 10;
      case HabitDifficulty.hard:
        return 20;
    }
  }

  static int pointsForMissionPriority(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.low:
        return 10;
      case MissionPriority.medium:
        return 20;
      case MissionPriority.high:
        return 35;
    }
  }

  static int pointsForAnytimeMission() {
    return 3;
  }

  static double completionRate({
    required int completed,
    required int total,
  }) {
    if (total == 0) return 0;
    return completed / total;
  }

  static bool qualifiesForStreak({
    required int completed,
    required int total,
  }) {
    if (total == 0) return false;
    return completionRate(completed: completed, total: total) >= 0.7;
  }

  static String formatDay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static int updateDisciplineScore({
    required int current,
    required HabitDifficulty difficulty,
    int multiplier = 1,
  }) {
    return current + pointsForDifficulty(difficulty) * multiplier;
  }

  static DailyLog createEmptyLog(DateTime date, String userId) {
    return DailyLog(
      id: formatDay(date),
      userId: userId,
      date: date,
      completedHabits: const [],
      missedHabits: const [],
      reflectionAnswers: const {},
    );
  }

  static StreakStats computeStreaks(List<DailyLog> logs) {
    if (logs.isEmpty) {
      return const StreakStats(current: 0, longest: 0);
    }
    final logMap = {for (final log in logs) log.id: log};
    final sorted = logs.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final today = DateTime.now();
    final start = DateTime(sorted.last.date.year, sorted.last.date.month,
        sorted.last.date.day);
    final end = DateTime(today.year, today.month, today.day);

    int current = 0;
    int longest = 0;
    int run = 0;
    bool currentDone = false;

    for (var day = end;
        !day.isBefore(start);
        day = day.subtract(const Duration(days: 1))) {
      final id = formatDay(day);
      final log = logMap[id];
      final total =
          (log?.completedHabits.length ?? 0) + (log?.missedHabits.length ?? 0);
      final qualifies = total > 0 &&
          completionRate(
                completed: log?.completedHabits.length ?? 0,
                total: total,
              ) >=
              kDisciplineDailyThreshold;
      if (qualifies) {
        run += 1;
        if (!currentDone) {
          current = run;
        }
      } else {
        if (!currentDone) {
          currentDone = true;
        }
        run = 0;
      }
      if (run > longest) longest = run;
    }

    return StreakStats(current: current, longest: longest);
  }
}

class StreakStats {
  const StreakStats({required this.current, required this.longest});

  final int current;
  final int longest;
}
