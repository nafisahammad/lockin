import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme_extensions.dart';
import '../../../core/discipline_logic.dart';
import '../../../shared/providers.dart';
import '../../habits/models/habit.dart';
import '../models/focus_session.dart';

final _lockModeHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(user.uid);
});

class LockModeScreen extends ConsumerStatefulWidget {
  const LockModeScreen({super.key});

  @override
  ConsumerState<LockModeScreen> createState() => _LockModeScreenState();
}

class _LockModeScreenState extends ConsumerState<LockModeScreen> {
  int _selectedMinutes = 25;
  Habit? _linkedHabit;
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _remaining = Duration(minutes: _selectedMinutes);
      _running = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        _completeSession();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  Future<void> _completeSession() async {
    setState(() => _running = false);
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final repo = ref.read(focusSessionRepositoryProvider);
      await repo.addSession(
        FocusSession(
          id: '',
          userId: user.uid,
          durationMinutes: _selectedMinutes,
          date: DateTime.now(),
          relatedHabitId: _linkedHabit?.id,
        ),
      );
    }
    if (mounted) {
      final bonus = DisciplineLogic.pointsForDifficulty(
            _linkedHabit?.difficulty ?? HabitDifficulty.medium,
          ) *
          (_selectedMinutes ~/ 15);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mission success. +$bonus XP'),
        ),
      );
    }
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lock Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are Locked In. Stay disciplined.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.lockInSurfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    _format(_remaining),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Focus session',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: context.lockInMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) {
                final habitsAsync = ref.watch(_lockModeHabitsProvider);
                return habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return Text(
                        'No protocols yet. Add one to link focus.',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: context.lockInMuted),
                      );
                    }
                    if (_linkedHabit == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _linkedHabit == null && !_running) {
                          setState(() => _linkedHabit = habits.first);
                        }
                      });
                    }
                    return DropdownButtonFormField<Habit>(
                      initialValue: _linkedHabit ?? habits.first,
                      decoration: const InputDecoration(
                        labelText: 'Link to protocol',
                      ),
                      items: habits.map((habit) {
                        return DropdownMenuItem(
                          value: habit,
                          child: Text(habit.title),
                        );
                      }).toList(),
                      onChanged: _running
                          ? null
                          : (value) => setState(() => _linkedHabit = value),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text('Error: $error'),
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [25, 45, 60].map((minutes) {
                final selected = _selectedMinutes == minutes;
                return ChoiceChip(
                  label: Text('$minutes min'),
                  selected: selected,
                  onSelected: _running
                      ? null
                      : (_) => setState(() => _selectedMinutes = minutes),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _running ? null : _startSession,
                child: Text(_running ? 'Locked In' : 'Start Session'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Background sound: (placeholder)',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: context.lockInMuted),
            ),
          ],
        ),
      ),
    );
  }
}
