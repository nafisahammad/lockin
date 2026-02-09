import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/theme_extensions.dart';
import '../../../core/discipline_logic.dart';
import '../../../shared/providers.dart';
import '../../reflection/models/daily_log.dart';
import '../models/habit.dart';

final _habitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(user.uid);
});

final _todayLogProvider = StreamProvider.autoDispose<DailyLog?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(dailyLogRepositoryProvider)
      .watchLogs(user.uid)
      .map((logs) {
    final todayId = DisciplineLogic.formatDay(DateTime.now());
    return logs.firstWhere(
      (log) => log.id == todayId,
      orElse: () => DisciplineLogic.createEmptyLog(DateTime.now(), user.uid),
    );
  });
});

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  final Set<String> _completedToday = {};
  ProviderSubscription<AsyncValue<DailyLog?>>? _todayLogSub;

  @override
  void initState() {
    super.initState();
    _todayLogSub = ref.listenManual<AsyncValue<DailyLog?>>(
      _todayLogProvider,
      (previous, next) {
        final log = next.value;
        if (log == null) return;
        if (!mounted) return;
        setState(() {
          _completedToday
            ..clear()
            ..addAll(log.completedHabits);
        });
      },
    );
  }

  @override
  void dispose() {
    _todayLogSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(_habitsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Protocols'),
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('Create your first protocol.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: habits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.lockInSurfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _completedToday.contains(habit.id),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _completedToday.add(habit.id);
                          } else {
                            _completedToday.remove(habit.id);
                          }
                        });
                        _syncDailyLog(habits);
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _domainIcon(habit.category),
                      size: 18,
                      color: context.lockInMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${habit.category} - ${habit.difficulty.name} - ${habit.timeOfDay.name}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: context.lockInMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            habit.identityTag.isEmpty
                                ? 'Identity: Unassigned'
                                : 'Identity: ${habit.identityTag}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: context.lockInMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.habitForm,
                        arguments: habit,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, habit),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.habitForm),
        child: const Icon(Icons.add),
      ),
    );
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

  Future<void> _syncDailyLog(List<Habit> habits) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final completed = _completedToday.toList();
    final missed = habits
        .where((habit) => !_completedToday.contains(habit.id))
        .map((habit) => habit.id)
        .toList();
    final log = DailyLog(
      id: DisciplineLogic.formatDay(DateTime.now()),
      userId: user.uid,
      date: DateTime.now(),
      completedHabits: completed,
      missedHabits: missed,
      reflectionAnswers: const {},
    );
    await ref.read(dailyLogRepositoryProvider).upsertLog(log);
    await _refreshStreaks(user.uid);
  }

  Future<void> _refreshStreaks(String userId) async {
    final logs = await ref
        .read(dailyLogRepositoryProvider)
        .fetchRecentLogs(userId, limit: 90);
    final stats = DisciplineLogic.computeStreaks(logs);
    await ref.read(userProfileRepositoryProvider).updateStreaks(
          userId: userId,
          currentStreak: stats.current,
          longestStreak: stats.longest,
        );
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true) {
      await ref.read(habitRepositoryProvider).deleteHabit(habit);
    }
  }
}
