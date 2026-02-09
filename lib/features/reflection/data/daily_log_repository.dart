import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_log.dart';

class DailyLogRepository {
  DailyLogRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('daily_logs');

  Future<void> upsertLog(DailyLog log) async {
    await _collection(log.userId).doc(log.id).set(log.toJson());
  }

  Stream<List<DailyLog>> watchLogs(String userId) {
    return _collection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyLog.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<List<DailyLog>> fetchRecentLogs(String userId, {int limit = 60}) async {
    final snapshot =
        await _collection(userId).orderBy('date', descending: true).limit(limit).get();
    return snapshot.docs
        .map((doc) => DailyLog.fromJson(doc.id, doc.data()))
        .toList();
  }
}
