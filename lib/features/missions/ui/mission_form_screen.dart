import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/providers.dart';
import '../models/mission.dart';

class MissionFormScreen extends ConsumerStatefulWidget {
  const MissionFormScreen({super.key});

  @override
  ConsumerState<MissionFormScreen> createState() => _MissionFormScreenState();
}

class _MissionFormScreenState extends ConsumerState<MissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _targetDate = DateTime.now();
  bool _isAnytime = false;
  MissionPriority _priority = MissionPriority.medium;
  Mission? _editing;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Mission && _editing == null) {
      _editing = args;
      _titleController.text = args.title;
      _targetDate = args.targetDate;
      _isAnytime = args.isAnytime;
      _priority = args.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _loading = true);
    final mission = Mission(
      id: _editing?.id ?? const Uuid().v4(),
      userId: user.uid,
      title: _titleController.text.trim(),
      targetDate: _targetDate,
      priority: _priority,
      completed: _editing?.completed ?? false,
      createdAt: _editing?.createdAt ?? DateTime.now(),
      isAnytime: _isAnytime,
      completedAt: _editing?.completedAt,
    );
    final repo = ref.read(missionRepositoryProvider);
    if (_editing == null) {
      await repo.addMission(mission);
    } else {
      await repo.updateMission(mission);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Mission' : 'New Mission')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Mission'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter mission' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target date'),
                subtitle: Text(
                  _isAnytime
                      ? 'No date (shows daily)'
                      : '${_targetDate.year}-${_targetDate.month.toString().padLeft(2, '0')}-${_targetDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: TextButton(
                  onPressed: _isAnytime ? null : _pickDate,
                  child: const Text('Pick'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAnytime,
                onChanged: (value) {
                  setState(() {
                    _isAnytime = value;
                    if (value) {
                      _targetDate = DateTime.now();
                    }
                  });
                },
                title: const Text('No date (daily task)'),
                subtitle: const Text('Appears every day until completed'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MissionPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: MissionPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _priority = value ?? MissionPriority.medium),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: Text(_loading ? 'Saving...' : 'Save Mission'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
