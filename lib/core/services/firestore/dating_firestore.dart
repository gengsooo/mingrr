import '../../../models/dating_model.dart';
import '../../utils/app_logger.dart';
import 'firestore_base.dart';

/// 데이팅(Dating) 도메인 Firestore CRUD mixin
mixin DatingFirestore on FirestoreBase {

  Future<void> createDatingRequest(DatingRequestModel request) async {
    try {
      await firebase.datingRequestsCollection.doc(request.id).set(request.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createDatingRequest (requestId: ${request.id})', e);
      rethrow;
    }
  }
  
  Future<void> updateDatingRequest(DatingRequestModel request) async {
    try {
      await firebase.datingRequestsCollection.doc(request.id).update(request.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateDatingRequest (requestId: ${request.id})', e);
      rethrow;
    }
  }
  
  Future<List<DatingRequestModel>> getReceivedDatingRequests(String userId) async {
    try {
      final snapshot = await firebase.datingRequestsCollection
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getReceivedDatingRequests (userId: $userId)', e);
      rethrow;
    }
  }
  
  Stream<List<DatingRequestModel>> watchReceivedDatingRequests(String userId) {
    return firebase.datingRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  Future<void> createMatch(MatchModel match) async {
    try {
      await firebase.matchesCollection.doc(match.id).set(match.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createMatch (matchId: ${match.id})', e);
      rethrow;
    }
  }
  
  Future<List<MatchModel>> getUserMatches(String userId) async {
    try {
      final snapshot = await firebase.matchesCollection
          .where('userIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('matchedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserMatches (userId: $userId)', e);
      rethrow;
    }
  }
}
