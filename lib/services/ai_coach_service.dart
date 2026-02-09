import 'dart:math';

class AiCoachService {
  const AiCoachService();

  String message({
    required int level,
    required int currentStreak,
    required double completionRatio,
    required int completedHabits,
    required int totalHabits,
    required int completedMissions,
    required int overdueMissions,
  }) {
    final ratio = (completionRatio * 100).round();
    if (totalHabits > 0 &&
        completedHabits == totalHabits &&
        overdueMissions > 0) {
      return 'Protocols cleared. Missions overdue: $overdueMissions. Stop avoiding the hard work.';
    }
    if (overdueMissions > 0) {
      return 'Critical backlog detected. Neutralize $overdueMissions mission(s) now.';
    }
    if (completedMissions > 0 && completionRatio < 0.7) {
      return 'You handled pressure, but protocols are lagging ($ratio%). Finish the identity work.';
    }
    if (completionRatio >= 0.85) {
      return 'Velocity high ($ratio%). Keep the streak alive. Level $level is within reach.';
    }
    if (completionRatio >= 0.7) {
      return 'You are barely above threshold ($ratio%). Push one more protocol to lock the day.';
    }
    if (currentStreak >= 7) {
      return 'Streak at $currentStreak days. Don’t let a soft day break it. Execute one mission now.';
    }
    final prompts = [
      'Discipline isn’t a mood. It’s a move. Finish one protocol before noon.',
      'Momentum is fragile. Complete a high-priority mission to reset the tone.',
      'You’re under 70% today. Fix it with one focused block.',
      'No excuses. Do the next action on the list and earn the right to rest.',
    ];
    return prompts[Random().nextInt(prompts.length)];
  }
}
