import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/focus_session.dart';

class FocusSessionRepository {
  FocusSessionRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('focus_sessions');

  Future<void> addSession(FocusSession session) async {
    await _collection(session.userId).add(session.toJson());
  }

  Stream<List<FocusSession>> watchSessions(String userId) {
    return _collection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FocusSession.fromJson(doc.id, doc.data()))
            .toList());
  }
}
