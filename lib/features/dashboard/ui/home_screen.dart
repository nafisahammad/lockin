import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants.dart';
import '../../../core/discipline_logic.dart';
import '../../../shared/providers.dart';
import '../../../services/quote_service.dart';
import '../../habits/models/habit.dart';
import '../../reflection/ui/reflection_dialog.dart';

final _todayHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) {
    return const Stream.empty();
  }
  return ref.watch(habitRepositoryProvider).watchHabits(auth.uid);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _quoteService = QuoteService();
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final quotes = await _quoteService.loadQuotes();
    if (quotes.isNotEmpty) {
      setState(() => _quote = quotes.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LockIn'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.progress),
            icon: const Icon(Icons.show_chart),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: user == null
                ? null
                : () => showDialog(
                      context: context,
                      builder: (_) => DailyReflectionDialog(userId: user.uid),
                    ),
            icon: const Icon(Icons.nightlight_round),
          ),
        ],
      ),
      body: _buildDashboard(context, user?.uid),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.lockMode),
        label: const Text('Lock In'),
        icon: const Icon(Icons.timer),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, String? userId) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MotivationCard(quote: _quote),
          const SizedBox(height: 20),
          _TodayHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: userId == null
                ? const Center(child: Text('Sign in to start.'))
                : Consumer(builder: (context, ref, _) {
                    final habitsAsync = ref.watch(_todayHabitsProvider);
                    return habitsAsync.when(
                      data: (habits) => _HabitsList(habits: habits),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) =>
                          Center(child: Text('Error: $error')),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kLockInSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLockInAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motivation',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: kLockInMuted),
          ),
          const SizedBox(height: 12),
          Text(
            quote.isEmpty ? 'Discipline > Motivation' : quote,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.habits),
          child: const Text('Manage'),
        ),
      ],
    );
  }
}

class _HabitsList extends StatelessWidget {
  const _HabitsList({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(
        child: Text('No habits yet. Add one to start.'),
      );
    }
    return ListView.separated(
      itemCount: habits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final habit = habits[index];
        final points = DisciplineLogic.pointsForDifficulty(habit.difficulty);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kLockInSurfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      habit.identityTag,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: kLockInMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kLockInAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('+$points'),
              ),
            ],
          ),
        );
      },
    );
  }
}
