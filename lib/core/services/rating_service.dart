import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/rating_model.dart';
import '../../models/user_model.dart';
import 'firebase_service.dart';
import 'kkosunnae_service.dart';

/// ============================================================
/// 평가 서비스
/// 사용자 평가 CRUD 및 꼬순내 지수 업데이트
/// ============================================================

class RatingService {
  final FirebaseService _firebase = FirebaseService();

  /// 평가 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _ratingsCollection =>
      _firebase.firestore.collection('ratings');

  /// 거래 상태 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firebase.firestore.collection('transactions');

  // ===== 평가 CRUD =====

  /// 평가 생성
  Future<String> createRating({
    required String raterId,
    required String targetId,
    required RatingType type,
    String? relatedId,
    required ActivityResult result,
    required int score,
    List<String> tags = const [],
    String? comment,
  }) async {
    final docRef = _ratingsCollection.doc();
    
    final rating = RatingModel(
      id: docRef.id,
      raterId: raterId,
      targetId: targetId,
      type: type,
      relatedId: relatedId,
      result: result,
      score: score,
      tags: tags,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await docRef.set(rating.toFirestore());

    // 대상자의 꼬순내 지수 업데이트
    await _updateTargetUserStats(targetId, result, score);

    return docRef.id;
  }

  /// 대상자 통계 업데이트
  Future<void> _updateTargetUserStats(
    String targetId,
    ActivityResult result,
    int score,
  ) async {
    final userRef = _firebase.usersCollection.doc(targetId);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) return;

    final user = UserModel.fromFirestore(userDoc.data()!, id: userDoc.id);

    // 평가 통계 계산
    final ratingsSnapshot = await _ratingsCollection
        .where('targetId', isEqualTo: targetId)
        .where('result', isEqualTo: ActivityResult.completed.name)
        .get();

    final completedRatings = ratingsSnapshot.docs
        .map((doc) => RatingModel.fromFirestore(doc.data(), id: doc.id))
        .toList();

    // 평균 평점 계산
    double avgRating = 0;
    if (completedRatings.isNotEmpty) {
      avgRating = completedRatings.map((r) => r.score).reduce((a, b) => a + b) /
          completedRatings.length;
    }

    // 노쇼 횟수 계산
    final noShowCount = (await _ratingsCollection
        .where('targetId', isEqualTo: targetId)
        .where('result', isEqualTo: ActivityResult.noShow.name)
        .get()).docs.length;

    // 사용자 통계 업데이트
    await userRef.update({
      'ratingCount': completedRatings.length,
      'averageRating': avgRating,
      'noShowCount': noShowCount,
    });

    // 꼬순내 지수 재계산
    await KkosunnaeService.updateScore(targetId);
  }

  /// 특정 사용자가 받은 평가 목록
  Stream<List<RatingModel>> getReceivedRatings(String userId) {
    return _ratingsCollection
        .where('targetId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }

  /// 특정 사용자가 작성한 평가 목록
  Stream<List<RatingModel>> getGivenRatings(String userId) {
    return _ratingsCollection
        .where('raterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }

  /// 특정 관련 ID에 대한 평가 조회
  Future<RatingModel?> getRatingByRelatedId(String raterId, String relatedId) async {
    final snapshot = await _ratingsCollection
        .where('raterId', isEqualTo: raterId)
        .where('relatedId', isEqualTo: relatedId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return RatingModel.fromFirestore(snapshot.docs.first.data(), id: snapshot.docs.first.id);
  }

  /// 이미 평가했는지 확인
  Future<bool> hasRated(String raterId, String relatedId) async {
    final rating = await getRatingByRelatedId(raterId, relatedId);
    return rating != null;
  }

  // ===== 거래 상태 관리 =====

  /// 거래 상태 생성
  Future<String> createTransaction({
    required String chatRoomId,
    required String type,
    String? relatedId,
    required String sellerId,
    required String buyerId,
  }) async {
    // 기존 거래 상태 확인
    final existing = await getTransactionByChatRoom(chatRoomId);
    if (existing != null) return existing.id;

    final docRef = _transactionsCollection.doc();
    
    final transaction = TransactionStatusModel(
      id: docRef.id,
      chatRoomId: chatRoomId,
      type: type,
      relatedId: relatedId,
      sellerId: sellerId,
      buyerId: buyerId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(transaction.toFirestore());
    return docRef.id;
  }

  /// 채팅방의 거래 상태 조회
  Future<TransactionStatusModel?> getTransactionByChatRoom(String chatRoomId) async {
    final snapshot = await _transactionsCollection
        .where('chatRoomId', isEqualTo: chatRoomId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return TransactionStatusModel.fromFirestore(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  /// 거래 상태 스트림
  Stream<TransactionStatusModel?> watchTransaction(String chatRoomId) {
    return _transactionsCollection
        .where('chatRoomId', isEqualTo: chatRoomId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return TransactionStatusModel.fromFirestore(
            snapshot.docs.first.data(),
            id: snapshot.docs.first.id,
          );
        });
  }

  /// 거래 완료 처리
  Future<void> completeTransaction(String transactionId, String status) async {
    await _transactionsCollection.doc(transactionId).update({
      'status': status,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 평가 완료 표시
  Future<void> markAsRated(String transactionId, bool isSeller) async {
    await _transactionsCollection.doc(transactionId).update({
      isSeller ? 'sellerRated' : 'buyerRated': true,
    });
  }

  /// 활동 통계 증가
  Future<void> incrementActivityCount(String userId, RatingType type) async {
    final field = _getActivityField(type);
    if (field == null) return;

    await _firebase.usersCollection.doc(userId).update({
      field: FieldValue.increment(1),
    });

    // 꼬순내 지수 재계산
    await KkosunnaeService.updateScore(userId);
  }

  String? _getActivityField(RatingType type) {
    switch (type) {
      case RatingType.dating:
        return 'matchCount';
      case RatingType.marketplace:
        return 'transactionCount';
      case RatingType.breeding:
        return 'matchCount';
      case RatingType.community:
        return 'groupCount';
    }
  }

  /// 신고하기
  Future<void> reportUser(String reporterId, String targetId, String reason) async {
    // 신고 기록 저장
    await _firebase.firestore.collection('reports').add({
      'reporterId': reporterId,
      'targetId': targetId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'status': 'pending',
    });

    // 신고 횟수 증가
    await _firebase.usersCollection.doc(targetId).update({
      'reportCount': FieldValue.increment(1),
    });

    // 꼬순내 지수 재계산
    await KkosunnaeService.updateScore(targetId);
  }
}
