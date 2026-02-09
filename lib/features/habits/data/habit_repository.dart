import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habit.dart';

class HabitRepository {
  HabitRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('habits');

  Stream<List<Habit>> watchHabits(String userId) {
    return _collection(userId)
        .orderBy('timeOfDay')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Habit.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> addHabit(Habit habit) async {
    await _collection(habit.userId).doc(habit.id).set(habit.toJson());
  }

  Future<void> updateHabit(Habit habit) async {
    await _collection(habit.userId).doc(habit.id).update(habit.toJson());
  }

  Future<void> deleteHabit(Habit habit) async {
    await _collection(habit.userId).doc(habit.id).delete();
  }
}
