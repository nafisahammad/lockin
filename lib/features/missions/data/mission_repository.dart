import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mission.dart';

class MissionRepository {
  MissionRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('missions');

  Stream<List<Mission>> watchMissions(String userId) {
    return _collection(userId)
        .orderBy('targetDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Mission.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> addMission(Mission mission) async {
    await _collection(mission.userId).doc(mission.id).set(mission.toJson());
  }

  Future<void> updateMission(Mission mission) async {
    await _collection(mission.userId).doc(mission.id).update(mission.toJson());
  }

  Future<void> deleteMission(Mission mission) async {
    await _collection(mission.userId).doc(mission.id).delete();
  }
}
