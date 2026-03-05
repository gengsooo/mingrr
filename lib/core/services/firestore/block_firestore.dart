import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_base.dart';

/// 차단(Block) 도메인 Firestore mixin
mixin BlockFirestore on FirestoreBase {

  /// 사용자 차단
  /// [blockerId] 차단하는 사용자 ID
  /// [blockedId] 차단당하는 사용자 ID
  /// [reason] 차단 사유 (선택)
  Future<void> blockUser(String blockerId, String blockedId, {String? reason}) async {
    try {
      final blockId = '${blockerId}_$blockedId';
      await firebase.blocksCollection.doc(blockId).set({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자 차단 해제
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final blockId = '${blockerId}_$blockedId';
      await firebase.blocksCollection.doc(blockId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// 차단 여부 확인
  Future<bool> isUserBlocked(String blockerId, String blockedId) async {
    try {
      final blockId = '${blockerId}_$blockedId';
      final doc = await firebase.blocksCollection.doc(blockId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 내가 차단한 사용자 목록 조회
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final snapshot = await firebase.blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data()['blockedId'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// 차단한 사용자 목록 스트림
  Stream<List<String>> watchBlockedUserIds(String userId) {
    return firebase.blocksCollection
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['blockedId'] as String)
            .toList());
  }
}
