import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/theme_extensions.dart';
import '../../../core/discipline_logic.dart';
import '../../../shared/providers.dart';
import '../models/mission.dart';

final _missionsProvider = StreamProvider.autoDispose<List<Mission>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(missionRepositoryProvider).watchMissions(user.uid);
});

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(_missionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Missions'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.missionForm),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: missionsAsync.when(
        data: (missions) {
          if (missions.isEmpty) {
            return const Center(child: Text('Deploy your first mission.'));
          }
          final today = DateTime.now();
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: missions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final mission = missions[index];
              final overdue = !mission.completed &&
                  !mission.isAnytime &&
                  DateTime(mission.targetDate.year, mission.targetDate.month,
                          mission.targetDate.day)
                      .isBefore(DateTime(today.year, today.month, today.day));
              return Container(
                padding: const EdgeInsets.all(16),
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
                        await ref
                            .read(missionRepositoryProvider)
                            .updateMission(updated);
                        final delta = mission.isAnytime
                            ? DisciplineLogic.pointsForAnytimeMission()
                            : DisciplineLogic.pointsForMissionPriority(
                                mission.priority,
                              );
                        await ref
                            .read(userProfileRepositoryProvider)
                            .incrementDisciplineScore(
                              mission.userId,
                              completed ? delta : -delta,
                            );
                      },
                    ),
                    const SizedBox(width: 8),
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
                          const SizedBox(height: 6),
                          Text(
                            mission.isAnytime
                                ? 'ANYTIME • EXTRA XP'
                                : '${mission.priority.name.toUpperCase()} • ${mission.targetDate.month}/${mission.targetDate.day}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: context.lockInMuted),
                          ),
                          if (overdue) ...[
                            const SizedBox(height: 6),
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
                    if (overdue)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.missionForm,
                        arguments: mission,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, mission),
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
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Mission mission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete mission?'),
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
      await ref.read(missionRepositoryProvider).deleteMission(mission);
    }
  }
}


