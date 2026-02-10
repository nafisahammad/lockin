import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/providers.dart';
import '../models/habit.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _identityController = TextEditingController();
  String _category = 'Custom';
  HabitDifficulty _difficulty = HabitDifficulty.easy;
  HabitTimeOfDay _timeOfDay = HabitTimeOfDay.morning;
  bool _reminderEnabled = false;
  Habit? _editing;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Habit && _editing == null) {
      _editing = args;
      _titleController.text = args.title;
      _identityController.text = args.identityTag;
      _category = args.category;
      _difficulty = args.difficulty;
      _timeOfDay = args.timeOfDay;
      _reminderEnabled = args.reminderEnabled;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _loading = true);
    final habit = Habit(
      id: _editing?.id ?? const Uuid().v4(),
      userId: user.uid,
      title: _titleController.text.trim(),
      category: _category,
      difficulty: _difficulty,
      timeOfDay: _timeOfDay,
      identityTag: _identityController.text.trim(),
      reminderEnabled: _reminderEnabled,
    );
    final repo = ref.read(habitRepositoryProvider);
    if (_editing == null) {
      await repo.addHabit(habit);
    } else {
      await repo.updateHabit(habit);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Habit' : 'New Habit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  'Fitness',
                  'Study',
                  'Work',
                  'Mindset',
                  'Custom',
                ].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value ?? 'Custom'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitDifficulty>(
                initialValue: _difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: HabitDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _difficulty = value ?? HabitDifficulty.easy),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitTimeOfDay>(
                initialValue: _timeOfDay,
                decoration: const InputDecoration(labelText: 'Preferred Time'),
                items: HabitTimeOfDay.values.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time.name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _timeOfDay = value ?? HabitTimeOfDay.morning),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identityController,
                decoration: const InputDecoration(
                  labelText: 'Identity Tag (I am...)',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _reminderEnabled,
                onChanged: (value) =>
                    setState(() => _reminderEnabled = value),
                title: const Text('Enable Reminder'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: Text(_loading ? 'Saving...' : 'Save Habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
