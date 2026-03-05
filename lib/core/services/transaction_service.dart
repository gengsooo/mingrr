import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// 트랜잭션 서비스
/// 
/// Race Condition 방지를 위한 원자적 데이터 처리
/// - 좋아요 토글
/// - 카운터 증감
/// - 멤버십 관리
/// ============================================================
class TransactionService {
  TransactionService._();
  
  static final FirebaseService _firebase = FirebaseService();
  static FirebaseFirestore get _firestore => _firebase.firestore;

  // ===== 좋아요 토글 (트랜잭션) =====

  /// 게시글 좋아요 토글
  /// Returns: true = 좋아요 추가됨, false = 좋아요 취소됨
  static Future<bool> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    final likeId = '${userId}_$postId';
    final likeRef = _firebase.feedLikesCollection.doc(likeId);
    final postRef = _firebase.feedPostsCollection.doc(postId);

    return _firestore.runTransaction<bool>((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        // 좋아요 취소
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // 좋아요 추가
        transaction.set(likeRef, {
          'userId': userId,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    });
  }

  /// 소모임 좋아요 토글
  static Future<bool> toggleGroupLike({
    required String groupId,
    required String userId,
  }) async {
    final likeId = '${userId}_$groupId';
    final likeRef = _firebase.groupLikesCollection.doc(likeId);
    final groupRef = _firebase.groupsCollection.doc(groupId);

    return _firestore.runTransaction<bool>((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(groupRef, {
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        transaction.set(likeRef, {
          'userId': userId,
          'groupId': groupId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(groupRef, {
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    });
  }

  /// 반려동물 좋아요 토글
  /// [ownerId]는 반려동물 소유자 ID (Firestore 규칙 검증용)
  static Future<bool> togglePetLike({
    required String petId,
    required String userId,
    String? ownerId,
  }) async {
    final likeId = '${userId}_$petId';
    final likeRef = _firestore.collection('likes').doc(likeId);
    final petRef = _firebase.petsCollection.doc(petId);

    return _firestore.runTransaction<bool>((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(petRef, {
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // ownerId가 없으면 pet 문서에서 조회
        String? petOwnerId = ownerId;
        if (petOwnerId == null) {
          final petDoc = await transaction.get(petRef);
          petOwnerId = petDoc.data()?['ownerId'] as String?;
        }
        
        transaction.set(likeRef, {
          'fromUserId': userId,
          'toUserId': petOwnerId ?? '',
          'toPetId': petId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(petRef, {
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    });
  }

  /// 상품 좋아요 토글
  static Future<bool> toggleProductLike({
    required String productId,
    required String userId,
  }) async {
    final likeId = '${userId}_$productId';
    final likeRef = _firebase.productLikesCollection.doc(likeId);
    final productRef = _firebase.productsCollection.doc(productId);

    AppLogger.info('TransactionService', '상품 찜 토글 시작 - productId: $productId, userId: $userId');

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          transaction.delete(likeRef);
          transaction.update(productRef, {
            'likeCount': FieldValue.increment(-1),
          });
          AppLogger.info('TransactionService', '상품 찜 취소 완료');
          return false;
        } else {
          transaction.set(likeRef, {
            'userId': userId,
            'productId': productId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(productRef, {
            'likeCount': FieldValue.increment(1),
          });
          AppLogger.info('TransactionService', '상품 찜 추가 완료');
          return true;
        }
      });
      return result;
    } catch (e) {
      AppLogger.error('TransactionService', '상품 찜 토글 오류', e);
      rethrow;
    }
  }

  /// 알바 좋아요 토글
  static Future<bool> toggleJobLike({
    required String jobId,
    required String userId,
  }) async {
    final likeId = '${userId}_$jobId';
    final likeRef = _firebase.jobLikesCollection.doc(likeId);
    final jobRef = _firebase.jobsCollection.doc(jobId);

    AppLogger.info('TransactionService', '알바 찜 토글 시작 - jobId: $jobId, userId: $userId');

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          transaction.delete(likeRef);
          transaction.update(jobRef, {
            'likeCount': FieldValue.increment(-1),
          });
          AppLogger.info('TransactionService', '알바 찜 취소 완료');
          return false;
        } else {
          transaction.set(likeRef, {
            'userId': userId,
            'jobId': jobId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(jobRef, {
            'likeCount': FieldValue.increment(1),
          });
          AppLogger.info('TransactionService', '알바 찜 추가 완료');
          return true;
        }
      });
      return result;
    } catch (e) {
      AppLogger.error('TransactionService', '알바 찜 토글 오류', e);
      rethrow;
    }
  }

  // ===== 소모임 멤버십 (트랜잭션) =====

  /// 소모임 가입
  static Future<bool> joinGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _firebase.groupsCollection.doc(groupId);
    final userRef = _firebase.usersCollection.doc(userId);

    return _firestore.runTransaction<bool>((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      
      if (!groupDoc.exists) {
        throw Exception('소모임을 찾을 수 없습니다');
      }

      final data = groupDoc.data()!;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final maxMembers = data['maxMembers'] as int? ?? 50;

      // 이미 멤버인지 확인
      if (memberIds.contains(userId)) {
        return false;
      }

      // 정원 확인
      if (memberIds.length >= maxMembers) {
        throw Exception('소모임 정원이 가득 찼습니다');
      }

      // 멤버 추가
      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });

      // 사용자 카운터 증가
      transaction.update(userRef, {
        'groupCount': FieldValue.increment(1),
      });

      return true;
    });
  }

  /// 소모임 탈퇴
  static Future<bool> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _firebase.groupsCollection.doc(groupId);
    final userRef = _firebase.usersCollection.doc(userId);

    return _firestore.runTransaction<bool>((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      
      if (!groupDoc.exists) {
        throw Exception('소모임을 찾을 수 없습니다');
      }

      final data = groupDoc.data()!;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final creatorId = data['creatorId'] as String?;

      // 멤버가 아닌 경우
      if (!memberIds.contains(userId)) {
        return false;
      }

      // 방장은 탈퇴 불가
      if (creatorId == userId) {
        throw Exception('방장은 소모임을 탈퇴할 수 없습니다');
      }

      // 멤버 제거
      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
      });

      // 사용자 카운터 감소
      transaction.update(userRef, {
        'groupCount': FieldValue.increment(-1),
      });

      return true;
    });
  }

  // ===== 게시글 삭제 (배치) =====

  /// 게시글 및 관련 데이터 삭제
  static Future<void> deletePostWithRelated({
    required String postId,
    required String authorId,
  }) async {
    final batch = _firestore.batch();

    // 1. 게시글 삭제
    batch.delete(_firebase.feedPostsCollection.doc(postId));

    // 2. 작성자 카운터 감소
    batch.update(_firebase.usersCollection.doc(authorId), {
      'postCount': FieldValue.increment(-1),
    });

    // 배치 커밋
    await batch.commit();

    // 3. 관련 댓글 삭제 (별도 처리 - 대량일 수 있음)
    await _deleteCollectionByField(
      collection: _firebase.feedCommentsCollection,
      field: 'postId',
      value: postId,
    );

    // 4. 관련 좋아요 삭제
    await _deleteCollectionByField(
      collection: _firebase.feedLikesCollection,
      field: 'postId',
      value: postId,
    );
  }

  /// 소모임 삭제 및 관련 데이터 정리
  static Future<void> deleteGroupWithRelated({
    required String groupId,
    required String creatorId,
    required List<String> memberIds,
  }) async {
    final batch = _firestore.batch();

    // 1. 소모임 삭제
    batch.delete(_firebase.groupsCollection.doc(groupId));

    // 2. 모든 멤버의 카운터 감소
    for (final memberId in memberIds) {
      batch.update(_firebase.usersCollection.doc(memberId), {
        'groupCount': FieldValue.increment(-1),
      });
    }

    await batch.commit();

    // 3. 관련 좋아요 삭제
    await _deleteCollectionByField(
      collection: _firebase.groupLikesCollection,
      field: 'groupId',
      value: groupId,
    );

    // 4. 가입 신청 삭제
    await _deleteCollectionByField(
      collection: _firebase.groupJoinRequestsCollection,
      field: 'groupId',
      value: groupId,
    );
  }

  // ===== 댓글 관리 (트랜잭션) =====

  /// 댓글 추가 (트랜잭션으로 원자적 처리)
  static Future<String> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? authorName,
    String? authorProfileUrl,
    String? parentId,
    bool isAnonymous = false,
  }) async {
    final commentRef = _firebase.feedCommentsCollection.doc();
    final postRef = _firebase.feedPostsCollection.doc(postId);

    await _firestore.runTransaction((transaction) async {
      // 댓글 생성
      transaction.set(commentRef, {
        'id': commentRef.id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName ?? '사용자',
        'authorProfileUrl': authorProfileUrl,
        'content': content,
        'parentId': parentId,
        'isAnonymous': isAnonymous,
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 게시글 댓글 수 증가
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(1),
      });
    });

    return commentRef.id;
  }

  /// 댓글 삭제
  static Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    final commentRef = _firebase.feedCommentsCollection.doc(commentId);
    final postRef = _firebase.feedPostsCollection.doc(postId);

    await _firestore.runTransaction((transaction) async {
      transaction.delete(commentRef);
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(-1),
      });
    });
  }

  // ===== 내부 유틸리티 =====

  /// 필드 값으로 컬렉션 문서 일괄 삭제
  static Future<void> _deleteCollectionByField({
    required CollectionReference<Map<String, dynamic>> collection,
    required String field,
    required String value,
  }) async {
    const batchSize = 500;
    
    QuerySnapshot<Map<String, dynamic>> snapshot;
    do {
      snapshot = await collection
          .where(field, isEqualTo: value)
          .limit(batchSize)
          .get();

      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == batchSize);
  }
}
