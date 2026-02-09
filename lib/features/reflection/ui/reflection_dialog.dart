import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers.dart';
import '../../../core/discipline_logic.dart';
import '../models/daily_log.dart';

class DailyReflectionDialog extends ConsumerStatefulWidget {
  const DailyReflectionDialog({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<DailyReflectionDialog> createState() =>
      _DailyReflectionDialogState();
}

class _DailyReflectionDialogState extends ConsumerState<DailyReflectionDialog> {
  String _lockedIn = 'Yes';
  final _distractedController = TextEditingController();
  final _proudController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _distractedController.dispose();
    _proudController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final log = DailyLog(
      id: DisciplineLogic.formatDay(DateTime.now()),
      userId: widget.userId,
      date: DateTime.now(),
      completedHabits: const [],
      missedHabits: const [],
      reflectionAnswers: {
        'lockedIn': _lockedIn,
        'distractedBy': _distractedController.text,
        'proudOf': _proudController.text,
      },
    );
    await ref.read(dailyLogRepositoryProvider).upsertLog(log);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Night Reflection'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Did you lock in today?'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _lockedIn,
              items: const [
                DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                DropdownMenuItem(value: 'No', child: Text('No')),
              ],
              onChanged: (value) => setState(() => _lockedIn = value ?? 'Yes'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _distractedController,
              decoration:
                  const InputDecoration(labelText: 'What distracted you?'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _proudController,
              decoration:
                  const InputDecoration(labelText: 'What are you proud of?'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
