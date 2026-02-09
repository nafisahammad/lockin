import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileRepository {
  UserProfileRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection('users').doc(userId);

  Future<void> incrementDisciplineScore(String userId, int delta) async {
    if (delta == 0) return;
    await _doc(userId).update({
      'disciplineScore': FieldValue.increment(delta),
    });
  }

  Future<void> updateStreaks({
    required String userId,
    required int currentStreak,
    required int longestStreak,
  }) async {
    await _doc(userId).update({
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    });
  }

  Future<void> updateEmail({
    required String userId,
    required String email,
  }) async {
    await _doc(userId).update({
      'email': email,
    });
  }
}
