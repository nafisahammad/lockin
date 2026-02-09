import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme_extensions.dart';
import '../../../core/discipline_logic.dart';
import '../../../shared/providers.dart';
import '../../habits/models/habit.dart';
import '../../reflection/models/daily_log.dart';

final _progressHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(user.uid);
});

final _progressLogsProvider = StreamProvider.autoDispose<List<DailyLog>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(dailyLogRepositoryProvider).watchLogs(user.uid);
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profileAsync =
        user == null ? null : ref.watch(userProfileProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatCard(
            title: 'Current Streak',
            value: '${profileAsync?.value?.currentStreak ?? 0} days',
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Longest Streak',
            value: '${profileAsync?.value?.longestStreak ?? 0} days',
          ),
          const SizedBox(height: 12),
          Consumer(builder: (context, ref, _) {
            final logsAsync = ref.watch(_progressLogsProvider);
            final habitsAsync = ref.watch(_progressHabitsProvider);
            return logsAsync.when(
              data: (logs) => habitsAsync.when(
                data: (habits) {
                  final ratio =
                      _weeklyConsistency(logs: logs, habits: habits);
                  return _StatCard(
                    title: 'Consistency (7 days)',
                    value: '${(ratio * 100).round()}%',
                  );
                },
                loading: () =>
                    const _StatCard(title: 'Consistency (7 days)', value: '...'),
                error: (_, _) =>
                  const _StatCard(title: 'Consistency (7 days)', value: '--'),
              ),
              loading: () =>
                  const _StatCard(title: 'Consistency (7 days)', value: '...'),
              error: (_, _) =>
                const _StatCard(title: 'Consistency (7 days)', value: '--'),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Weekly Completion',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _WeeklyChart(),
          const SizedBox(height: 24),
          Text(
            'Calendar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CalendarConsistency(),
        ],
      ),
    );
  }

  double _weeklyConsistency({
    required List<DailyLog> logs,
    required List<Habit> habits,
  }) {
    if (habits.isEmpty) return 0;
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: index)),
    );
    final logMap = {for (final log in logs) log.id: log};
    final ratios = days.map((day) {
      final id = DisciplineLogic.formatDay(day);
      final log = logMap[id];
      return DisciplineLogic.completionRate(
        completed: log?.completedHabits.length ?? 0,
        total: habits.length,
      );
    }).toList();
    final total = ratios.fold<double>(0, (sum, value) => sum + value);
    return total / ratios.length;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
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

class _PlaceholderChart extends StatelessWidget {
  const _PlaceholderChart({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.lockInSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.lockInAccent.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: context.lockInMuted),
        ),
      ),
    );
  }
}

class _CalendarConsistency extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_progressLogsProvider);
    final habitsAsync = ref.watch(_progressHabitsProvider);
    return logsAsync.when(
      data: (logs) => habitsAsync.when(
        data: (habits) {
          final today = DateTime.now();
          final firstDay = DateTime(today.year, today.month, 1);
          final nextMonth = DateTime(today.year, today.month + 1, 1);
          final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
          final leadingEmpty = (firstDay.weekday % 7);
          final totalCells = leadingEmpty + daysInMonth;
          final trailingEmpty = (7 - (totalCells % 7)) % 7;
          final logMap = {for (final log in logs) log.id: log};

          final days = List<DateTime?>.generate(
            leadingEmpty,
            (_) => null,
          )
            ..addAll(
              List.generate(
                daysInMonth,
                (index) => DateTime(today.year, today.month, index + 1),
              ),
            )
            ..addAll(List<DateTime?>.generate(trailingEmpty, (_) => null));

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.lockInSurfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthName(today.month)} ${today.year}',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: _WeekdayLabel('S')),
                    Expanded(child: _WeekdayLabel('M')),
                    Expanded(child: _WeekdayLabel('T')),
                    Expanded(child: _WeekdayLabel('W')),
                    Expanded(child: _WeekdayLabel('T')),
                    Expanded(child: _WeekdayLabel('F')),
                    Expanded(child: _WeekdayLabel('S')),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    if (day == null) {
                      return const _CalendarCell(
                        label: '',
                        color: Colors.transparent,
                        showBorder: false,
                      );
                    }
                    final id = DisciplineLogic.formatDay(day);
                    final log = logMap[id];
                    final ratio = DisciplineLogic.completionRate(
                      completed: log?.completedHabits.length ?? 0,
                      total: habits.length,
                    );
                    final color =
                        context.lockInAccent.withValues(alpha: ratio);
                    return _CalendarCell(
                      label: '${day.day}',
                      color: color,
                      showBorder: true,
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const _PlaceholderChart(label: 'Loading...'),
        error: (_, _) => const _PlaceholderChart(label: 'Unavailable'),
      ),
      loading: () => const _PlaceholderChart(label: 'Loading...'),
      error: (_, _) => const _PlaceholderChart(label: 'Unavailable'),
    );
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
    }
    return '';
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: context.lockInMuted),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.label,
    required this.color,
    required this.showBorder,
  });

  final String label;
  final Color color;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final borderColor = showBorder
        ? context.lockInSurface.withValues(alpha: 0.6)
        : Colors.transparent;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.opacity <= 0.35
                  ? context.lockInMuted
                  : Colors.white,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _WeeklyChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_progressLogsProvider);
    final habitsAsync = ref.watch(_progressHabitsProvider);
    return logsAsync.when(
      data: (logs) => habitsAsync.when(
        data: (habits) {
          final today = DateTime.now();
          final days = List.generate(
            7,
            (index) => DateTime(today.year, today.month, today.day)
                .subtract(Duration(days: 6 - index)),
          );
          final logMap = {for (final log in logs) log.id: log};
          return Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.lockInSurfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final id = DisciplineLogic.formatDay(day);
                final log = logMap[id];
                final ratio = DisciplineLogic.completionRate(
                  completed: log?.completedHabits.length ?? 0,
                  total: habits.length,
                );
                final height = 24 + ratio * 90;
                return Expanded(
                  child: Container(
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ratio >= kDisciplineDailyThreshold
                          ? context.lockInAccent
                          : context.lockInSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const _PlaceholderChart(label: 'Loading...'),
        error: (_, _) => const _PlaceholderChart(label: 'Unavailable'),
      ),
      loading: () => const _PlaceholderChart(label: 'Loading...'),
      error: (_, _) => const _PlaceholderChart(label: 'Unavailable'),
    );
  }
}
