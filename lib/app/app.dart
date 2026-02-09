import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/auth/ui/auth_gate.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/signup_screen.dart';
import '../features/dashboard/ui/home_screen.dart';
import '../features/habits/ui/habit_form_screen.dart';
import '../features/habits/ui/habits_screen.dart';
import '../features/lock_mode/ui/lock_mode_screen.dart';
import '../features/missions/ui/mission_form_screen.dart';
import '../features/missions/ui/missions_screen.dart';
import '../features/progress/ui/progress_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../shared/providers.dart';
import 'routes.dart';

class LockInApp extends ConsumerWidget {
  const LockInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'LockIn',
      theme: buildLockInLightTheme(),
      darkTheme: buildLockInTheme(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.root,
      routes: {
        AppRoutes.root: (_) => const AuthGate(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignupScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.habits: (_) => const HabitsScreen(),
        AppRoutes.habitForm: (_) => const HabitFormScreen(),
        AppRoutes.lockMode: (_) => const LockModeScreen(),
        AppRoutes.progress: (_) => const ProgressScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.missions: (_) => const MissionsScreen(),
        AppRoutes.missionForm: (_) => const MissionFormScreen(),
      },
    );
  }
}
