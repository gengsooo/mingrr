import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/rating_model.dart';
import '../constants/rating_constants.dart';
import '../utils/app_logger.dart';
import 'firebase_service.dart';
import 'kkosunnae_service.dart';
import 'notification_service.dart';

/// ============================================================
/// 평가 서비스
/// 
/// 사용자 평가 CRUD 및 꼬순내 지수 업데이트
/// 
/// 평가 정책:
/// - 활동 기반 평가만 허용 (relatedId 필수)
/// - 동일 활동에 대해 1회만 평가 가능
/// - 동일 대상에게 동일 타입으로 30일 내 재평가 불가 (쿨다운)
/// - 활동 완료 후 14일 이내에만 평가 가능 (만료)
/// ============================================================

class RatingService {
  final FirebaseService _firebase = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  /// 상수는 RatingConstants 클래스에서 관리
  static int get cooldownDays => RatingConstants.cooldownDays;
  static int get expirationDays => RatingConstants.expirationDays;
  static int get maxRatingsPerHour => RatingConstants.maxRatingsPerHour;
  static int get maxRatingsPerDay => RatingConstants.maxRatingsPerDay;

  /// 평가 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _ratingsCollection =>
      _firebase.firestore.collection('ratings');

  /// 거래 상태 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firebase.firestore.collection('transactions');

  // ===== 평가 유효성 검사 =====

  /// 평가 가능 여부 확인
  /// 
  /// 반환값:
  /// - canRate: 평가 가능 여부
  /// - reason: 불가능한 경우 사유
  /// 
  /// [activityCompletedAt]이 제공되면 평가 만료 체크도 수행
  Future<RatingEligibility> checkRatingEligibility({
    required String raterId,
    required String targetId,
    required RatingType type,
    required String relatedId,
    DateTime? activityCompletedAt,
  }) async {
    // 1. 자기 자신 평가 불가
    if (raterId == targetId) {
      return RatingEligibility.notAllowed('자기 자신은 평가할 수 없어요');
    }

    // 2. 동일 활동(relatedId)에 대한 중복 평가 체크
    final existingRating = await getRatingByRelatedId(raterId, relatedId);
    if (existingRating != null) {
      return RatingEligibility.notAllowed('이미 이 활동에 대해 평가를 완료했어요');
    }

    // 3. 평가 만료 체크 (활동 완료 후 14일 이내만 평가 가능)
    if (activityCompletedAt != null) {
      final expirationResult = _checkExpiration(activityCompletedAt);
      if (!expirationResult.canRate) {
        return expirationResult;
      }
    }

    // 4. 동일 대상에게 동일 타입으로 쿨다운 기간 내 재평가 체크
    final cooldownResult = await _checkCooldown(raterId, targetId, type);
    if (!cooldownResult.canRate) {
      return cooldownResult;
    }

    // 5. 이상 탐지 체크 (짧은 시간 내 과다 평가 방지)
    final anomalyResult = await _checkAnomalyDetection(raterId);
    if (!anomalyResult.canRate) {
      return anomalyResult;
    }

    return RatingEligibility.allowed();
  }
  
  /// 평가 만료 체크 (활동 완료 후 14일 이내만 평가 가능)
  RatingEligibility _checkExpiration(DateTime activityCompletedAt) {
    final expirationDate = activityCompletedAt.add(Duration(days: expirationDays));
    final now = DateTime.now();
    
    if (now.isAfter(expirationDate)) {
      return RatingEligibility.notAllowed('평가 기간이 만료되었어요 (활동 후 $expirationDays일 이내)');
    }
    
    return RatingEligibility.allowed();
  }

  /// 쿨다운 체크 (동일 대상 + 동일 타입)
  Future<RatingEligibility> _checkCooldown(
    String raterId,
    String targetId,
    RatingType type,
  ) async {
    final cooldownDate = DateTime.now().subtract(Duration(days: cooldownDays));
    
    final snapshot = await _ratingsCollection
        .where('raterId', isEqualTo: raterId)
        .where('targetId', isEqualTo: targetId)
        .where('type', isEqualTo: type.name)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cooldownDate))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final lastRating = RatingModel.fromFirestore(
        snapshot.docs.first.data(),
        id: snapshot.docs.first.id,
      );
      final daysRemaining = cooldownDays - DateTime.now().difference(lastRating.createdAt).inDays;
      return RatingEligibility.notAllowed(
        '$daysRemaining일 후에 다시 평가할 수 있어요',
      );
    }

    return RatingEligibility.allowed();
  }

  /// 이상 탐지 체크 (짧은 시간 내 과다 평가 방지)
  Future<RatingEligibility> _checkAnomalyDetection(String raterId) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    // 1시간 내 평가 횟수 체크
    final hourlySnapshot = await _ratingsCollection
        .where('raterId', isEqualTo: raterId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
        .get();
    
    if (hourlySnapshot.docs.length >= maxRatingsPerHour) {
      return RatingEligibility.notAllowed(
        '잠시 후에 다시 시도해주세요 (1시간 내 최대 $maxRatingsPerHour개)',
      );
    }
    
    // 24시간 내 평가 횟수 체크
    final dailySnapshot = await _ratingsCollection
        .where('raterId', isEqualTo: raterId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
        .get();
    
    if (dailySnapshot.docs.length >= maxRatingsPerDay) {
      return RatingEligibility.notAllowed(
        '오늘 평가 횟수를 초과했어요 (하루 최대 $maxRatingsPerDay개)',
      );
    }
    
    return RatingEligibility.allowed();
  }

  // ===== 상호 평가 만료 자동 공개 =====

  /// 만료된 비공개 평가를 자동 공개 처리
  /// 
  /// 상호 평가 대기 기간(14일)이 지난 비공개 평가를 공개로 전환하고
  /// 해당 대상자의 통계를 업데이트합니다.
  /// 
  /// 호출 시점: 앱 초기화, 평가 목록 조회 시 lazy하게 실행
  Future<void> revealExpiredRatings() async {
    final cutoffDate = DateTime.now().subtract(
      Duration(days: RatingConstants.mutualRatingWaitDays),
    );

    // 만료된 비공개 평가 조회
    final snapshot = await _ratingsCollection
        .where('isVisible', isEqualTo: false)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    if (snapshot.docs.isEmpty) return;

    // 배치로 공개 처리
    final batch = _firebase.firestore.batch();
    final targetIds = <String>{};

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isVisible': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      targetIds.add(doc.data()['targetId'] as String? ?? '');
    }

    await batch.commit();

    // 영향받은 대상자들의 통계 업데이트
    for (final targetId in targetIds) {
      if (targetId.isNotEmpty) {
        await KkosunnaeService.updateScore(targetId);
      }
    }
  }

  // ===== 평가 CRUD =====

  /// 평가 생성
  /// 
  /// 평가 저장 후:
  /// 1. 대상자 통계 업데이트 (ratingCount, averageRating, noShowCount)
  /// 2. 꼬순내 지수 재계산
  /// 3. 상대방에게 알림 발송 (평가 내용은 비공개)
  /// 
  /// [relatedId]는 필수입니다. 활동 기반 평가만 허용합니다.
  Future<String> createRating({
    required String raterId,
    required String targetId,
    required RatingType type,
    required String relatedId,
    required ActivityResult result,
    required int score,
    List<String> tags = const [],
    String? comment,
  }) async {
    // 평가 가능 여부 확인
    final eligibility = await checkRatingEligibility(
      raterId: raterId,
      targetId: targetId,
      type: type,
      relatedId: relatedId,
    );

    if (!eligibility.canRate) {
      throw RatingException(eligibility.reason ?? '평가할 수 없습니다');
    }

    // 상대방이 이미 평가했는지 확인 (상호 평가 체크)
    final counterpartRating = await _getCounterpartRating(targetId, raterId, relatedId);
    final isVisible = counterpartRating != null;

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
      isVisible: isVisible,
    );

    await docRef.set(rating.toFirestore());

    // 상대방 평가가 있으면 해당 평가도 공개 처리
    if (counterpartRating != null && !counterpartRating.isVisible) {
      await _ratingsCollection.doc(counterpartRating.id).update({
        'isVisible': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    // 양쪽 평가가 모두 공개되면 양쪽 모두 통계 업데이트
    if (counterpartRating != null && isVisible) {
      // 현재 평가의 대상자 통계 업데이트
      await _updateTargetUserStats(targetId, result, score);
      // 상대방 평가의 대상자(= 현재 평가자) 통계도 업데이트
      await _updateTargetUserStats(
        raterId, 
        counterpartRating.result, 
        counterpartRating.score,
      );
    }

    // 상대방에게 평가 알림 발송
    await _sendRatingNotification(raterId, targetId, type, relatedId);

    return docRef.id;
  }

  /// 상대방 평가 조회 (상호 평가 체크용)
  Future<RatingModel?> _getCounterpartRating(
    String raterId,
    String targetId,
    String relatedId,
  ) async {
    final snapshot = await _ratingsCollection
        .where('raterId', isEqualTo: raterId)
        .where('targetId', isEqualTo: targetId)
        .where('relatedId', isEqualTo: relatedId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return RatingModel.fromFirestore(snapshot.docs.first.data(), id: snapshot.docs.first.id);
  }

  /// 평가 완료 알림 발송
  Future<void> _sendRatingNotification(
    String raterId,
    String targetId,
    RatingType type,
    String? relatedId,
  ) async {
    try {
      // 평가자 정보 조회
      final raterDoc = await _firebase.usersCollection.doc(raterId).get();
      if (!raterDoc.exists) return;
      
      final raterName = raterDoc.data()?['nickname'] ?? '사용자';
      
      // 알림 발송 (평가 내용은 비공개)
      await _notificationService.sendRatingNotification(
        recipientId: targetId,
        raterName: raterName,
        ratingType: type.name,
        relatedId: relatedId,
      );
    } catch (e) {
      // 알림 실패는 무시 (평가 자체는 성공)
      AppLogger.warning('RatingService', '평가 알림 발송 실패: $e');
    }
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

    // 평가 통계 계산 (공개된 평가만)
    final ratingsSnapshot = await _ratingsCollection
        .where('targetId', isEqualTo: targetId)
        .where('isVisible', isEqualTo: true)
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

    // 노쇼 횟수 계산 (공개된 평가만)
    final noShowCount = (await _ratingsCollection
        .where('targetId', isEqualTo: targetId)
        .where('isVisible', isEqualTo: true)
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

  /// 특정 사용자가 받은 평가 목록 (공개된 평가만)
  Stream<List<RatingModel>> getReceivedRatings(String userId) {
    return _ratingsCollection
        .where('targetId', isEqualTo: userId)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }

  /// 특정 사용자가 작성한 평가 목록 (본인이 작성한 것은 모두 표시)
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

  /// 평가 대기 목록 조회 (내가 평가해야 할 거래들)
  /// 
  /// 만료되지 않은 평가만 반환 (활동 완료 후 14일 이내)
  Future<List<TransactionStatusModel>> getPendingRatings(String userId) async {
    final expirationDate = DateTime.now().subtract(Duration(days: expirationDays));
    
    // 내가 판매자이고 아직 평가 안 한 거래
    final sellerSnapshot = await _transactionsCollection
        .where('sellerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .where('sellerRated', isEqualTo: false)
        .get();
    
    // 내가 구매자이고 아직 평가 안 한 거래
    final buyerSnapshot = await _transactionsCollection
        .where('buyerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .where('buyerRated', isEqualTo: false)
        .get();
    
    final transactions = <TransactionStatusModel>[];
    
    for (final doc in sellerSnapshot.docs) {
      final transaction = TransactionStatusModel.fromFirestore(doc.data(), id: doc.id);
      // 만료되지 않은 평가만 추가 (completedAt 또는 createdAt 기준)
      final completedAt = transaction.completedAt ?? transaction.createdAt;
      if (completedAt.isAfter(expirationDate)) {
        transactions.add(transaction);
      }
    }
    for (final doc in buyerSnapshot.docs) {
      final transaction = TransactionStatusModel.fromFirestore(doc.data(), id: doc.id);
      final completedAt = transaction.completedAt ?? transaction.createdAt;
      if (completedAt.isAfter(expirationDate)) {
        transactions.add(transaction);
      }
    }
    
    // 최신순 정렬
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  /// 평가 대기 목록 스트림
  /// 
  /// 만료되지 않은 평가만 반환 (활동 완료 후 14일 이내)
  Stream<List<TransactionStatusModel>> watchPendingRatings(String userId) {
    // 판매자로서 평가 대기 스트림을 기준으로 구매자 데이터도 함께 조회
    final sellerStream = _transactionsCollection
        .where('sellerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .where('sellerRated', isEqualTo: false)
        .snapshots();
    
    // 두 스트림 합치기 (sellerStream 변경 시 buyerSnapshot도 함께 조회)
    return sellerStream.asyncMap((sellerSnapshot) async {
      final expirationDate = DateTime.now().subtract(Duration(days: expirationDays));
      
      final buyerSnapshot = await _transactionsCollection
          .where('buyerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('buyerRated', isEqualTo: false)
          .get();
      
      final transactions = <TransactionStatusModel>[];
      
      for (final doc in sellerSnapshot.docs) {
        final transaction = TransactionStatusModel.fromFirestore(doc.data(), id: doc.id);
        final completedAt = transaction.completedAt ?? transaction.createdAt;
        if (completedAt.isAfter(expirationDate)) {
          transactions.add(transaction);
        }
      }
      for (final doc in buyerSnapshot.docs) {
        final transaction = TransactionStatusModel.fromFirestore(doc.data(), id: doc.id);
        final completedAt = transaction.completedAt ?? transaction.createdAt;
        if (completedAt.isAfter(expirationDate)) {
          transactions.add(transaction);
        }
      }
      
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }
}
