import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants.dart';
import '../../../core/discipline_logic.dart';
import '../../../core/leveling.dart';
import '../../../core/theme_extensions.dart';
import '../../../services/ai_coach_service.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers.dart';
import '../../habits/models/habit.dart';
import '../../missions/models/mission.dart';
import '../../reflection/models/daily_log.dart';

final _habitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(user.uid);
});

final _missionsProvider = StreamProvider.autoDispose<List<Mission>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(missionRepositoryProvider).watchMissions(user.uid);
});

final _dailyLogsProvider = StreamProvider.autoDispose<List<DailyLog>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(dailyLogRepositoryProvider).watchLogs(user.uid);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _coachService = const AiCoachService();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LockIn'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to unlock your dashboard.'))
          : _DashboardBody(userId: user.uid, coachService: _coachService),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.missionForm),
        child: const Icon(Icons.add_task),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _HomeBottomNav(
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.habits);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.lockMode);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.progress);
              break;
          }
        },
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: context.lockInSurface,
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () => onTap(0),
            icon: const Icon(Icons.dashboard),
          ),
          IconButton(
            onPressed: () => onTap(1),
            icon: const Icon(Icons.assignment_turned_in),
          ),
          const SizedBox(width: 40),
          IconButton(
            onPressed: () => onTap(2),
            icon: const Icon(Icons.timer),
          ),
          IconButton(
            onPressed: () => onTap(3),
            icon: const Icon(Icons.show_chart),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.userId,
    required this.coachService,
  });

  final String userId;
  final AiCoachService coachService;

  List<DateTime> _lastWeek() {
    final today = DateTime.now();
    return List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - index)),
    );
  }

  int _completedHabitsToday({required List<DailyLog> logs}) {
    final todayId = DisciplineLogic.formatDay(DateTime.now());
    final log = logs.firstWhere(
      (entry) => entry.id == todayId,
      orElse: () => DisciplineLogic.createEmptyLog(DateTime.now(), ''),
    );
    return log.completedHabits.length;
  }

  int _completedMissionsToday(List<Mission> missions) {
    final today = DateTime.now();
    return missions
        .where((mission) =>
            !mission.isAnytime &&
            mission.completedAt != null &&
            _isSameDay(mission.completedAt!, today))
        .length;
  }

  int _overdueMissions(List<Mission> missions) {
    final today = DateTime.now();
    return missions
        .where((mission) =>
            !mission.isAnytime &&
            !mission.completed &&
            !mission.targetDate
                .isAfter(DateTime(today.year, today.month, today.day)))
        .length;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final habitsAsync = ref.watch(_habitsProvider);
    final missionsAsync = ref.watch(_missionsProvider);
    final logsAsync = ref.watch(_dailyLogsProvider);
    final week = _lastWeek();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        profileAsync.when(
          data: (profile) => _LevelHeader(profile: profile),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        _DailyLoadSection(
          habitsAsync: habitsAsync,
          missionsAsync: missionsAsync,
          logsAsync: logsAsync,
        ),
        const SizedBox(height: 16),
        habitsAsync.when(
          data: (habits) => logsAsync.when(
            data: (logs) => missionsAsync.when(
              data: (missions) => _CoachCard(
                message: coachService.message(
                  level: profileAsync.value?.level ?? 1,
                  currentStreak: profileAsync.value?.currentStreak ?? 0,
                  completionRatio: _completionRatio(
                    logs: logs,
                    habits: habits,
                  ),
                  completedHabits: _completedHabitsToday(logs: logs),
                  totalHabits: habits.length,
                  completedMissions: _completedMissionsToday(missions),
                  overdueMissions: _overdueMissions(missions),
                ),
              ),
              loading: () =>
                  const _CoachCard(message: 'Syncing mission intel...'),
              error: (_, _) => const _CoachCard(message: 'Intel unavailable.'),
            ),
            loading: () => const _CoachCard(message: 'Syncing mission intel...'),
            error: (_, _) => const _CoachCard(message: 'Intel unavailable.'),
          ),
          loading: () => const _CoachCard(message: 'Syncing mission intel...'),
          error: (_, _) => const _CoachCard(message: 'Intel unavailable.'),
        ),
        const SizedBox(height: 16),
        habitsAsync.when(
          data: (habits) => logsAsync.when(
            data: (logs) => _MomentumGrid(
              habits: habits,
              logs: logs,
              week: week,
              userId: userId,
            ),
            loading: () => const _SectionLoading(),
            error: (error, _) => Text('Error: $error'),
          ),
          loading: () => const _SectionLoading(),
          error: (error, _) => Text('Error: $error'),
        ),
        const SizedBox(height: 16),
        habitsAsync.when(
          data: (habits) => _TimeBlockSection(habits: habits),
          loading: () => const _SectionLoading(),
          error: (error, _) => Text('Error: $error'),
        ),
        const SizedBox(height: 16),
        missionsAsync.when(
          data: (missions) => _MissionSection(missions: missions),
          loading: () => const _SectionLoading(),
          error: (error, _) => Text('Error: $error'),
        ),
        const SizedBox(height: 16),
        logsAsync.when(
          data: (logs) => habitsAsync.when(
            data: (habits) => _VelocitySection(
              logs: logs,
              habits: habits,
              week: week,
            ),
            loading: () => const _SectionLoading(),
            error: (error, _) => Text('Error: $error'),
          ),
          loading: () => const _SectionLoading(),
          error: (error, _) => Text('Error: $error'),
        ),
        const SizedBox(height: 16),
        _FocusCallout(
          onStart: () => Navigator.pushNamed(context, AppRoutes.lockMode),
        ),
      ],
    );
  }

  double _completionRatio({
    required List<DailyLog> logs,
    required List<Habit> habits,
  }) {
    if (habits.isEmpty) return 0;
    final todayId = DisciplineLogic.formatDay(DateTime.now());
    final log = logs.firstWhere(
      (entry) => entry.id == todayId,
      orElse: () => DisciplineLogic.createEmptyLog(DateTime.now(), ''),
    );
    return DisciplineLogic.completionRate(
      completed: log.completedHabits.length,
      total: habits.length,
    );
  }
}

class _DailyLoadSection extends StatelessWidget {
  const _DailyLoadSection({
    required this.habitsAsync,
    required this.missionsAsync,
    required this.logsAsync,
  });

  final AsyncValue<List<Habit>> habitsAsync;
  final AsyncValue<List<Mission>> missionsAsync;
  final AsyncValue<List<DailyLog>> logsAsync;

  @override
  Widget build(BuildContext context) {
    return habitsAsync.when(
      data: (habits) => missionsAsync.when(
        data: (missions) => logsAsync.when(
          data: (logs) {
            final today = DateTime.now();
            final todayId = DisciplineLogic.formatDay(today);
            final log = logs.firstWhere(
              (entry) => entry.id == todayId,
              orElse: () => DisciplineLogic.createEmptyLog(today, ''),
            );
            final completedHabits = log.completedHabits.length;
            final todaysMissions = missions
                .where((mission) =>
                    !mission.isAnytime &&
                    mission.targetDate.year == today.year &&
                    mission.targetDate.month == today.month &&
                    mission.targetDate.day == today.day)
                .toList();
            final completedMissions =
                todaysMissions.where((mission) => mission.completed).length;
            final total = habits.length + todaysMissions.length;
            final completed = completedHabits + completedMissions;
            final ratio = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
            return _DailyLoadCard(
              ratio: ratio,
              completed: completed,
              total: total,
            );
          },
          loading: () => const _DailyLoadCard(
            ratio: 0,
            completed: 0,
            total: 0,
          ),
          error: (_, _) => const _DailyLoadCard(
            ratio: 0,
            completed: 0,
            total: 0,
          ),
        ),
        loading: () => const _DailyLoadCard(
          ratio: 0,
          completed: 0,
          total: 0,
        ),
        error: (_, _) => const _DailyLoadCard(
          ratio: 0,
          completed: 0,
          total: 0,
        ),
      ),
      loading: () => const _DailyLoadCard(ratio: 0, completed: 0, total: 0),
      error: (_, _) => const _DailyLoadCard(ratio: 0, completed: 0, total: 0),
    );
  }
}

class _DailyLoadCard extends StatelessWidget {
  const _DailyLoadCard({
    required this.ratio,
    required this.completed,
    required this.total,
  });

  final double ratio;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.lockInAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  color: context.lockInAccent,
                  backgroundColor: context.lockInSurface,
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Load',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed / $total completed today',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: context.lockInMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final score = profile?.disciplineScore ?? 0;
    final level = profile?.level ?? Leveling.levelForPoints(score);
    final title = Leveling.titleForLevel(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discipline XP',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: context.lockInMuted),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '$score',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 16),
            _StatPill(label: 'LVL $level', value: title),
            const SizedBox(width: 8),
            _StatPill(
              label: 'STREAK',
              value: '${profile?.currentStreak ?? 0}d',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.lockInAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.lockInMuted),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.lockInAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mission Status - Gemini 3 Flash',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: context.lockInMuted),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MomentumGrid extends StatelessWidget {
  const _MomentumGrid({
    required this.habits,
    required this.logs,
    required this.week,
    required this.userId,
  });

  final List<Habit> habits;
  final List<DailyLog> logs;
  final List<DateTime> week;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final logMap = {
      for (final log in logs) log.id: log,
    };
    final today = DateTime.now();
    final todayId = DisciplineLogic.formatDay(today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '7-Day Momentum Grid',
          actionLabel: 'Protocols',
          onTap: () => Navigator.pushNamed(context, AppRoutes.habits),
        ),
        const SizedBox(height: 12),
        if (habits.isNotEmpty)
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox.shrink()),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: week
                      .map(
                        (day) => SizedBox(
                          width: 14,
                          child: Text(
                            _weekdayLetter(day),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: context.lockInMuted),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        if (habits.isEmpty)
          const Text('No protocols yet. Add one to see momentum.')
        else
          Column(
            children: habits.take(6).map((habit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            _domainIcon(habit.category),
                            size: 16,
                            color: context.lockInMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              habit.title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: context.lockInMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: week.map((day) {
                          final id = DisciplineLogic.formatDay(day);
                          final log = logMap[id];
                          final completed =
                              log?.completedHabits.contains(habit.id) ?? false;
                          final missed =
                              log?.missedHabits.contains(habit.id) ?? false;
                          final isToday = id == todayId;
                          final tile = Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: completed
                                  ? context.lockInAccent
                                  : context.lockInSurface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: missed
                                    ? Colors.redAccent
                                    : context.lockInAccent.withValues(alpha: 0.2),
                              ),
                            ),
                          );
                          if (!isToday) return tile;
                          return GestureDetector(
                            onTap: () => _toggleToday(
                              context,
                              habit,
                              log,
                              userId,
                            ),
                            child: tile,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _weekdayLetter(DateTime day) {
    switch (day.weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
    }
    return '';
  }

  IconData _domainIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'study':
        return Icons.menu_book;
      case 'work':
        return Icons.work_outline;
      case 'mindset':
        return Icons.self_improvement;
      case 'custom':
        return Icons.grid_view;
    }
    return Icons.track_changes;
  }

  Future<void> _toggleToday(
    BuildContext context,
    Habit habit,
    DailyLog? log,
    String userId,
  ) async {
    final repo = ProviderScope.containerOf(context)
        .read(dailyLogRepositoryProvider);
    final profileRepo = ProviderScope.containerOf(context)
        .read(userProfileRepositoryProvider);
    final today = DateTime.now();
    final current = log ?? DisciplineLogic.createEmptyLog(today, userId);
    final completed = List<String>.from(current.completedHabits);
    final missed = List<String>.from(current.missedHabits);
    final alreadyDone = completed.contains(habit.id);
    if (alreadyDone) {
      completed.remove(habit.id);
      if (!missed.contains(habit.id)) missed.add(habit.id);
    } else {
      completed.add(habit.id);
      missed.remove(habit.id);
    }
    final updated = DailyLog(
      id: DisciplineLogic.formatDay(today),
      userId: userId,
      date: today,
      completedHabits: completed,
      missedHabits: missed,
      reflectionAnswers: current.reflectionAnswers,
    );
    await repo.upsertLog(updated);
    final delta = DisciplineLogic.pointsForDifficulty(habit.difficulty);
    await profileRepo.incrementDisciplineScore(
      userId,
      alreadyDone ? -delta : delta,
    );
    final logs = await repo.fetchRecentLogs(userId, limit: 90);
    final stats = DisciplineLogic.computeStreaks(logs);
    await profileRepo.updateStreaks(
      userId: userId,
      currentStreak: stats.current,
      longestStreak: stats.longest,
    );
  }
}

class _TimeBlockSection extends StatelessWidget {
  const _TimeBlockSection({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final morning = habits.where((h) => h.timeOfDay == HabitTimeOfDay.morning);
    final afternoon =
        habits.where((h) => h.timeOfDay == HabitTimeOfDay.afternoon);
    final night = habits.where((h) => h.timeOfDay == HabitTimeOfDay.night);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Time-Block Allocation',
          actionLabel: 'Manage',
          onTap: () => Navigator.pushNamed(context, AppRoutes.habits),
        ),
        const SizedBox(height: 12),
        _TimeBlockRow(label: 'Morning', habits: morning.toList()),
        const SizedBox(height: 8),
        _TimeBlockRow(label: 'Afternoon', habits: afternoon.toList()),
        const SizedBox(height: 8),
        _TimeBlockRow(label: 'Night', habits: night.toList()),
      ],
    );
  }
}

class _TimeBlockRow extends StatelessWidget {
  const _TimeBlockRow({required this.label, required this.habits});

  final String label;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: habits.isEmpty
                  ? [
                      Text(
                        'None',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: context.lockInMuted),
                      ),
                    ]
                  : habits
                      .map(
                        (habit) => Chip(
                          label: Text(habit.title),
                          backgroundColor: context.lockInSurface,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection({required this.missions});

  final List<Mission> missions;

  Color _priorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.low:
        return Colors.blueGrey;
      case MissionPriority.medium:
        return Colors.amber;
      case MissionPriority.high:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final active = missions.where((mission) => !mission.completed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Active Missions',
          actionLabel: 'View All',
          onTap: () => Navigator.pushNamed(context, AppRoutes.missions),
        ),
        const SizedBox(height: 12),
        if (active.isEmpty)
          const Text('No missions deployed yet.')
        else
          Column(
            children: active.take(3).map((mission) {
              final overdue = !mission.isAnytime &&
                  DateTime(
                    mission.targetDate.year,
                    mission.targetDate.month,
                    mission.targetDate.day,
                  ).isBefore(DateTime(today.year, today.month, today.day));
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.lockInSurfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: overdue ? Colors.redAccent : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: mission.completed,
                      onChanged: (value) async {
                        final completed = value ?? false;
                        final updated = mission.copyWith(
                          completed: completed,
                          completedAt: completed ? DateTime.now() : null,
                        );
                        await ProviderScope.containerOf(context)
                            .read(missionRepositoryProvider)
                            .updateMission(updated);
                        final delta = mission.isAnytime
                            ? DisciplineLogic.pointsForAnytimeMission()
                            : DisciplineLogic.pointsForMissionPriority(
                                mission.priority,
                              );
                        await ProviderScope.containerOf(context)
                            .read(userProfileRepositoryProvider)
                            .incrementDisciplineScore(
                              mission.userId,
                              completed ? delta : -delta,
                            );
                      },
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _priorityColor(mission.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mission.isAnytime
                                ? 'ANYTIME • EXTRA XP'
                                : '${mission.priority.name.toUpperCase()} - ${mission.targetDate.month}/${mission.targetDate.day}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: context.lockInMuted),
                          ),
                          if (overdue) ...[
                            const SizedBox(height: 4),
                            Text(
                              'CRITICAL OVERDUE',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.missionForm,
                        arguments: mission,
                      ),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _VelocitySection extends StatelessWidget {
  const _VelocitySection({
    required this.logs,
    required this.habits,
    required this.week,
  });

  final List<DailyLog> logs;
  final List<Habit> habits;
  final List<DateTime> week;

  @override
  Widget build(BuildContext context) {
    final logMap = {for (final log in logs) log.id: log};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consistency Velocity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.lockInSurfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: week.map((day) {
              final id = DisciplineLogic.formatDay(day);
              final log = logMap[id];
              final ratio = DisciplineLogic.completionRate(
                completed: log?.completedHabits.length ?? 0,
                total: habits.length,
              );
              final height = 24 + (ratio * 60);
              final hit = ratio >= kDisciplineDailyThreshold;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: height,
                  decoration: BoxDecoration(
                    color: hit ? context.lockInAccent : context.lockInSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FocusCallout extends StatelessWidget {
  const _FocusCallout({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.lockInAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Mode',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Link a session to a protocol and claim XP.',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: context.lockInMuted),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStart,
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator();
  }
}
