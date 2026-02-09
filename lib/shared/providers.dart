import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/habits/data/habit_repository.dart';
import '../features/lock_mode/data/focus_session_repository.dart';
import '../features/missions/data/mission_repository.dart';
import '../features/reflection/data/daily_log_repository.dart';
import 'data/user_profile_repository.dart';
import 'models/user_profile.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final analyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).userChanges();
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return FocusSessionRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, userId) {
  final doc =
      ref.watch(firestoreProvider).collection('users').doc(userId).snapshots();
  return doc.map((snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    return UserProfile.fromJson(snapshot.id, data);
  });
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
