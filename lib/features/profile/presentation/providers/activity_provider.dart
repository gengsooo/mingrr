import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/community_post_model.dart';
import '../../../../models/dating_model.dart';
import '../../../../models/group_model.dart';
import '../../../../models/health_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 내 활동 관련 Provider
/// 
/// 프로필 > 내 활동 화면에서 사용
/// 탭 구성: 산책 / 매칭 / 거래 / 커뮤니티 / 모임
/// 
/// 개선 사항:
/// - 성능 최적화: 내 펫 목록 캐싱 (currentUserPetIdsProvider)
/// - 페이지네이션: ClientPaginatedNotifier 적용
/// - 에러 처리: 디버그 로깅 추가
/// ============================================================

final _firebase = FirebaseService();
final _firestoreService = FirestoreService();

// ============================================================
// 공통: 내 펫 ID 목록 캐싱 Provider
// ============================================================

/// 현재 사용자의 펫 ID 목록 (캐싱)
/// 매칭 Provider에서 상대방 펫을 구분할 때 사용
final currentUserPetIdsProvider = FutureProvider<Set<String>>((ref) async {
  // keepAlive로 캐싱 활성화
  ref.keepAlive();
  
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return {};
  
  try {
    final snapshot = await _firebase.petsCollection
        .where('ownerId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((d) => d.id).toSet();
  } catch (e, st) {
    _logError('currentUserPetIdsProvider', e, st);
    return {};
  }
});

// ============================================================
// 공통: 로깅 유틸리티
// ============================================================

void _logError(String source, Object error, [StackTrace? stackTrace]) {
  AppLogger.error('ActivityProvider', source, error);
}

// ============================================================
// 1. 산책 기록 Provider (페이지네이션 적용)
// ============================================================

/// 산책 기록 페이지네이션 Provider
final userWalkRecordsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<WalkRecordModel>,
    PaginatedState<WalkRecordModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<WalkRecordModel>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final snapshot = await _firebase.firestore
            .collection('walkRecords')
            .where('userId', isEqualTo: userId)
            .orderBy('startTime', descending: true)
            .get();
        
        return snapshot.docs
            .map((doc) => WalkRecordModel.fromFirestore(doc))
            .toList();
      } catch (e, st) {
        _logError('userWalkRecordsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 산책 기록 (단순 조회용 - 하위 호환)
final userWalkRecordsProvider = FutureProvider.autoDispose<List<WalkRecordModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final snapshot = await _firebase.firestore
        .collection('walkRecords')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs
        .map((doc) => WalkRecordModel.fromFirestore(doc))
        .toList();
  } catch (e, st) {
    _logError('userWalkRecordsProvider', e, st);
    return [];
  }
});

// ============================================================
// 2. 매칭 기록 Provider (상세 정보 포함)
// ============================================================

/// 매칭 + 상대방 정보 통합 모델
class MatchWithDetails {
  final MatchModel match;
  final String? partnerPetName;
  final String? partnerPetImageUrl;
  final String? partnerPetBreed;
  final String? chatRoomId;
  final DateTime matchedAt;
  
  MatchWithDetails({
    required this.match,
    this.partnerPetName,
    this.partnerPetImageUrl,
    this.partnerPetBreed,
    this.chatRoomId,
    required this.matchedAt,
  });
}

/// 매칭 기록 페이지네이션 Provider
final userMatchesPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<MatchWithDetails>,
    PaginatedState<MatchWithDetails>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  // 캐싱된 내 펫 ID 목록 사용 (성능 최적화)
  final myPetIdsAsync = ref.watch(currentUserPetIdsProvider);
  
  return ClientPaginatedNotifier<MatchWithDetails>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final matches = await _firestoreService.getUserMatches(userId);
        final myPetIds = myPetIdsAsync.valueOrNull ?? {};
        final result = <MatchWithDetails>[];
        
        for (final match in matches) {
          // 상대방 펫 ID 찾기 (캐싱된 내 펫 ID 사용)
          String? partnerPetId;
          if (match.petIds.length >= 2) {
            partnerPetId = match.petIds.firstWhere(
              (id) => !myPetIds.contains(id),
              orElse: () => match.petIds.first,
            );
          }
          
          // 상대방 펫 정보 조회
          String? petName;
          String? petImageUrl;
          String? petBreed;
          
          if (partnerPetId != null) {
            try {
              final petDoc = await _firebase.petsCollection.doc(partnerPetId).get();
              if (petDoc.exists) {
                final data = petDoc.data()!;
                petName = data['name'] as String?;
                petImageUrl = data['primaryPhotoUrl'] as String? ?? 
                              (data['photoUrls'] as List?)?.firstOrNull as String?;
                petBreed = data['breed'] as String?;
              }
            } catch (e, st) {
              _logError('userMatchesPaginatedProvider.fetchPetInfo', e, st);
            }
          }
          
          result.add(MatchWithDetails(
            match: match,
            partnerPetName: petName,
            partnerPetImageUrl: petImageUrl,
            partnerPetBreed: petBreed,
            chatRoomId: match.chatRoomId,
            matchedAt: match.matchedAt,
          ));
        }
        
        // 최신순 정렬
        result.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        return result;
      } catch (e, st) {
        _logError('userMatchesPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 사용자의 매칭 목록 (단순 조회용 - 하위 호환)
final userMatchesWithDetailsProvider = FutureProvider.autoDispose<List<MatchWithDetails>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final matches = await _firestoreService.getUserMatches(userId);
    // 캐싱된 내 펫 ID 목록 사용 (성능 최적화)
    final myPetIds = ref.read(currentUserPetIdsProvider).valueOrNull ?? {};
    final result = <MatchWithDetails>[];
    
    for (final match in matches) {
      // 상대방 펫 ID 찾기 (캐싱된 내 펫 ID 사용)
      String? partnerPetId;
      if (match.petIds.length >= 2) {
        partnerPetId = match.petIds.firstWhere(
          (id) => !myPetIds.contains(id),
          orElse: () => match.petIds.first,
        );
      }
      
      // 상대방 펫 정보 조회
      String? petName;
      String? petImageUrl;
      String? petBreed;
      
      if (partnerPetId != null) {
        try {
          final petDoc = await _firebase.petsCollection.doc(partnerPetId).get();
          if (petDoc.exists) {
            final data = petDoc.data()!;
            petName = data['name'] as String?;
            petImageUrl = data['primaryPhotoUrl'] as String? ?? 
                          (data['photoUrls'] as List?)?.firstOrNull as String?;
            petBreed = data['breed'] as String?;
          }
        } catch (e, st) {
          _logError('userMatchesWithDetailsProvider.fetchPetInfo', e, st);
        }
      }
      
      result.add(MatchWithDetails(
        match: match,
        partnerPetName: petName,
        partnerPetImageUrl: petImageUrl,
        partnerPetBreed: petBreed,
        chatRoomId: match.chatRoomId,
        matchedAt: match.matchedAt,
      ));
    }
    
    // 최신순 정렬
    result.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
    return result;
  } catch (e, st) {
    _logError('userMatchesWithDetailsProvider', e, st);
    return [];
  }
});

/// 매칭 활동 타입 (보낸 신청, 받은 신청, 성사된 매칭)
enum MatchActivityType { sent, received, matched }

/// 매칭 활동 통합 모델
class MatchActivity {
  final String id;
  final MatchActivityType type;
  final String partnerPetName;
  final String? partnerPetImageUrl;
  final String? partnerPetBreed;
  final String? message;
  final String? chatRoomId;
  final DateTime createdAt;
  final String? status; // pending, accepted, rejected
  final bool isBreeding; // 교배 신청 여부

  MatchActivity({
    required this.id,
    required this.type,
    required this.partnerPetName,
    this.partnerPetImageUrl,
    this.partnerPetBreed,
    this.message,
    this.chatRoomId,
    required this.createdAt,
    this.status,
    this.isBreeding = false,
  });
}

/// 통합 매칭 활동 Provider (보낸 신청 + 받은 신청 + 성사된 매칭)
final userMatchActivitiesProvider = FutureProvider.autoDispose<List<MatchActivity>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  final result = <MatchActivity>[];
  
  try {
    // 1. 성사된 매칭 조회
    final matches = await _firestoreService.getUserMatches(userId);
    final myPetIds = ref.read(currentUserPetIdsProvider).valueOrNull ?? {};
    
    for (final match in matches) {
      String? partnerPetId;
      if (match.petIds.length >= 2) {
        partnerPetId = match.petIds.firstWhere(
          (id) => !myPetIds.contains(id),
          orElse: () => match.petIds.first,
        );
      }
      
      String petName = '매칭된 친구';
      String? petImageUrl;
      String? petBreed;
      
      if (partnerPetId != null) {
        try {
          final petDoc = await _firebase.petsCollection.doc(partnerPetId).get();
          if (petDoc.exists) {
            final data = petDoc.data()!;
            petName = data['name'] as String? ?? '매칭된 친구';
            petImageUrl = data['primaryPhotoUrl'] as String? ?? 
                          (data['photoUrls'] as List?)?.firstOrNull as String?;
            petBreed = data['breed'] as String?;
          }
        } catch (_) {}
      }
      
      result.add(MatchActivity(
        id: match.id,
        type: MatchActivityType.matched,
        partnerPetName: petName,
        partnerPetImageUrl: petImageUrl,
        partnerPetBreed: petBreed,
        chatRoomId: match.chatRoomId,
        createdAt: match.matchedAt,
        status: 'accepted',
      ));
    }
    
    // 2. 보낸 신청 조회
    final sentSnapshot = await _firebase.firestore
        .collection('dating_requests')
        .where('fromUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    for (final doc in sentSnapshot.docs) {
      final data = doc.data();
      // dating_requests 컨렉션 필드명: toPetId (dating_model.dart 기준)
      final toPetId = data['toPetId'] as String?;
      
      String petName = '상대방';
      String? petImageUrl;
      String? petBreed;
      
      if (toPetId != null) {
        try {
          final petDoc = await _firebase.petsCollection.doc(toPetId).get();
          if (petDoc.exists) {
            final petData = petDoc.data()!;
            petName = petData['name'] as String? ?? '상대방';
            petImageUrl = petData['primaryPhotoUrl'] as String? ?? 
                          (petData['photoUrls'] as List?)?.firstOrNull as String?;
            petBreed = petData['breed'] as String?;
          }
        } catch (_) {}
      }
      
      result.add(MatchActivity(
        id: doc.id,
        type: MatchActivityType.sent,
        partnerPetName: petName,
        partnerPetImageUrl: petImageUrl,
        partnerPetBreed: petBreed,
        message: data['message'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String?,
        isBreeding: false,
      ));
    }
    
    // 3. 받은 데이팅 신청 조회
    final receivedSnapshot = await _firebase.firestore
        .collection('dating_requests')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    for (final doc in receivedSnapshot.docs) {
      final data = doc.data();
      // dating_requests 컨렉션 필드명: fromPetId (dating_model.dart 기준)
      final fromPetId = data['fromPetId'] as String?;
      
      String petName = '상대방';
      String? petImageUrl;
      String? petBreed;
      
      if (fromPetId != null) {
        try {
          final petDoc = await _firebase.petsCollection.doc(fromPetId).get();
          if (petDoc.exists) {
            final petData = petDoc.data()!;
            petName = petData['name'] as String? ?? '상대방';
            petImageUrl = petData['primaryPhotoUrl'] as String? ?? 
                          (petData['photoUrls'] as List?)?.firstOrNull as String?;
            petBreed = petData['breed'] as String?;
          }
        } catch (_) {}
      }
      
      result.add(MatchActivity(
        id: doc.id,
        type: MatchActivityType.received,
        partnerPetName: petName,
        partnerPetImageUrl: petImageUrl,
        partnerPetBreed: petBreed,
        message: data['message'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String?,
        isBreeding: false,
      ));
    }
    
    // 4. 보낸 교배 신청 조회 (Firestore 규칙/인덱스: senderId 사용)
    final sentBreedingSnapshot = await _firebase.firestore
        .collection('breeding_requests')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    for (final doc in sentBreedingSnapshot.docs) {
      final data = doc.data();
      // Firestore 필드명: receiverPetId (이전: toPetId)
      final toPetId = data['receiverPetId'] as String? ?? data['toPetId'] as String?;
      
      String petName = '상대방';
      String? petImageUrl;
      String? petBreed;
      
      if (toPetId != null) {
        try {
          final petDoc = await _firebase.petsCollection.doc(toPetId).get();
          if (petDoc.exists) {
            final petData = petDoc.data()!;
            petName = petData['name'] as String? ?? '상대방';
            petImageUrl = petData['primaryPhotoUrl'] as String? ?? 
                          (petData['photoUrls'] as List?)?.firstOrNull as String?;
            petBreed = petData['breed'] as String?;
          }
        } catch (_) {}
      }
      
      result.add(MatchActivity(
        id: doc.id,
        type: MatchActivityType.sent,
        partnerPetName: petName,
        partnerPetImageUrl: petImageUrl,
        partnerPetBreed: petBreed,
        message: data['message'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String?,
        isBreeding: true,
      ));
    }
    
    // 5. 받은 교배 신청 조회 (Firestore 규칙/인덱스: receiverId 사용)
    final receivedBreedingSnapshot = await _firebase.firestore
        .collection('breeding_requests')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    for (final doc in receivedBreedingSnapshot.docs) {
      final data = doc.data();
      // Firestore 필드명: senderPetId (이전: fromPetId)
      final fromPetId = data['senderPetId'] as String? ?? data['fromPetId'] as String?;
      
      String petName = '상대방';
      String? petImageUrl;
      String? petBreed;
      
      if (fromPetId != null) {
        try {
          final petDoc = await _firebase.petsCollection.doc(fromPetId).get();
          if (petDoc.exists) {
            final petData = petDoc.data()!;
            petName = petData['name'] as String? ?? '상대방';
            petImageUrl = petData['primaryPhotoUrl'] as String? ?? 
                          (petData['photoUrls'] as List?)?.firstOrNull as String?;
            petBreed = petData['breed'] as String?;
          }
        } catch (_) {}
      }
      
      result.add(MatchActivity(
        id: doc.id,
        type: MatchActivityType.received,
        partnerPetName: petName,
        partnerPetImageUrl: petImageUrl,
        partnerPetBreed: petBreed,
        message: data['message'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String?,
        isBreeding: true,
      ));
    }
    
    // 최신순 정렬
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  } catch (e, st) {
    _logError('userMatchActivitiesProvider', e, st);
    return [];
  }
});

// ============================================================
// 3. 거래 기록 Provider (상세 정보 포함)
// ============================================================

/// 거래 타입
enum TransactionType { sell, buy }

/// 거래 + 상세 정보 통합 모델
class TransactionWithDetails {
  final ProductModel product;
  final TransactionType type;
  
  TransactionWithDetails({
    required this.product,
    required this.type,
  });
}

/// 거래 기록 페이지네이션 Provider
final userTransactionsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<TransactionWithDetails>,
    PaginatedState<TransactionWithDetails>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<TransactionWithDetails>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final result = <TransactionWithDetails>[];
        
        final soldSnapshot = await _firebase.productsCollection
            .where('sellerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        
        for (final doc in soldSnapshot.docs) {
          final product = ProductModel.fromFirestore(doc.data(), id: doc.id);
          result.add(TransactionWithDetails(
            product: product,
            type: TransactionType.sell,
          ));
        }
        
        return result;
      } catch (e, st) {
        _logError('userTransactionsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 사용자의 거래 내역 (단순 조회용 - 하위 호환)
final userTransactionsWithDetailsProvider = FutureProvider.autoDispose<List<TransactionWithDetails>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final result = <TransactionWithDetails>[];
    
    final soldSnapshot = await _firebase.productsCollection
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    for (final doc in soldSnapshot.docs) {
      final product = ProductModel.fromFirestore(doc.data(), id: doc.id);
      result.add(TransactionWithDetails(
        product: product,
        type: TransactionType.sell,
      ));
    }
    
    return result;
  } catch (e, st) {
    _logError('userTransactionsWithDetailsProvider', e, st);
    return [];
  }
});

// ============================================================
// 4. 커뮤니티 활동 Provider (내가 쓴 글 + 댓글)
// ============================================================

/// 커뮤니티 활동 타입
enum CommunityActivityType { post, comment }

/// 커뮤니티 활동 통합 모델
class CommunityActivity {
  final CommunityActivityType type;
  final String id;
  final String title;
  final String? content;
  final String? postTitle; // 댓글인 경우 원글 제목
  final String? postId; // 댓글인 경우 원글 ID
  final CommunityCategory? category;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  
  CommunityActivity({
    required this.type,
    required this.id,
    required this.title,
    this.content,
    this.postTitle,
    this.postId,
    this.category,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
  });
}

/// 커뮤니티 활동 페이지네이션 Provider
final userCommunityActivitiesPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<CommunityActivity>,
    PaginatedState<CommunityActivity>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<CommunityActivity>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final result = <CommunityActivity>[];
        
        // 내가 쓴 글
        final postsSnapshot = await _firebase.feedPostsCollection
            .where('authorId', isEqualTo: userId)
            .get();
        
        for (final doc in postsSnapshot.docs) {
          final post = CommunityPostModel.fromFirestore(doc.data(), id: doc.id);
          result.add(CommunityActivity(
            type: CommunityActivityType.post,
            id: post.id,
            title: post.title,
            content: post.content,
            category: post.category,
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
          ));
        }
        
        // 내가 쓴 댓글
        final commentsSnapshot = await _firebase.feedCommentsCollection
            .where('authorId', isEqualTo: userId)
            .get();
        
        for (final doc in commentsSnapshot.docs) {
          final comment = CommunityCommentModel.fromFirestore(doc.data(), id: doc.id);
          
          // 원글 정보 조회
          String? postTitle;
          try {
            final postDoc = await _firebase.feedPostsCollection.doc(comment.postId).get();
            if (postDoc.exists) {
              postTitle = postDoc.data()?['title'] as String?;
            }
          } catch (e, st) {
            _logError('userCommunityActivitiesPaginatedProvider.fetchPostTitle', e, st);
          }
          
          result.add(CommunityActivity(
            type: CommunityActivityType.comment,
            id: comment.id,
            title: comment.content,
            postTitle: postTitle,
            postId: comment.postId,
            createdAt: comment.createdAt,
          ));
        }
        
        // 최신순 정렬
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return result;
      } catch (e, st) {
        _logError('userCommunityActivitiesPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 사용자의 커뮤니티 활동 (단순 조회용 - 하위 호환)
final userCommunityActivitiesProvider = FutureProvider.autoDispose<List<CommunityActivity>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final result = <CommunityActivity>[];
    
    // 내가 쓴 글
    final postsSnapshot = await _firebase.feedPostsCollection
        .where('authorId', isEqualTo: userId)
        .limit(30)
        .get();
    
    for (final doc in postsSnapshot.docs) {
      final post = CommunityPostModel.fromFirestore(doc.data(), id: doc.id);
      result.add(CommunityActivity(
        type: CommunityActivityType.post,
        id: post.id,
        title: post.title,
        content: post.content,
        category: post.category,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        createdAt: post.createdAt,
      ));
    }
    
    // 내가 쓴 댓글
    final commentsSnapshot = await _firebase.feedCommentsCollection
        .where('authorId', isEqualTo: userId)
        .limit(30)
        .get();
    
    for (final doc in commentsSnapshot.docs) {
      final comment = CommunityCommentModel.fromFirestore(doc.data(), id: doc.id);
      
      // 원글 정보 조회
      String? postTitle;
      try {
        final postDoc = await _firebase.feedPostsCollection.doc(comment.postId).get();
        if (postDoc.exists) {
          postTitle = postDoc.data()?['title'] as String?;
        }
      } catch (e, st) {
        _logError('userCommunityActivitiesProvider.fetchPostTitle', e, st);
      }
      
      result.add(CommunityActivity(
        type: CommunityActivityType.comment,
        id: comment.id,
        title: comment.content,
        postTitle: postTitle,
        postId: comment.postId,
        createdAt: comment.createdAt,
      ));
    }
    
    // 최신순 정렬
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  } catch (e, st) {
    _logError('userCommunityActivitiesProvider', e, st);
    return [];
  }
});

// ============================================================
// 5. 모임 활동 Provider (모임 + 일정 통합)
// ============================================================

/// 모임 + 일정 통합 모델
class GroupWithSchedules {
  final GroupModel group;
  final List<GroupScheduleModel> upcomingSchedules;
  
  GroupWithSchedules({
    required this.group,
    required this.upcomingSchedules,
  });
  
  /// 다음 일정
  GroupScheduleModel? get nextSchedule => 
      upcomingSchedules.isNotEmpty ? upcomingSchedules.first : null;
}

/// 모임 활동 페이지네이션 Provider
final userGroupsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<GroupWithSchedules>,
    PaginatedState<GroupWithSchedules>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<GroupWithSchedules>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final groupsSnapshot = await _firebase.groupsCollection
            .where('memberIds', arrayContains: userId)
            .get();
        
        final result = <GroupWithSchedules>[];
        final now = DateTime.now();
        
        for (final doc in groupsSnapshot.docs) {
          final group = GroupModel.fromFirestore(doc.data(), id: doc.id);
          
          // 해당 모임의 다가오는 일정 조회
          List<GroupScheduleModel> schedules = [];
          try {
            final schedulesSnapshot = await _firebase.schedulesCollection
                .where('groupId', isEqualTo: group.id)
                .get();
            
            schedules = schedulesSnapshot.docs
                .map((doc) => GroupScheduleModel.fromFirestore(doc.data(), id: doc.id))
                .where((s) => s.startTime.isAfter(now))
                .toList();
            
            schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
          } catch (e, st) {
            _logError('userGroupsPaginatedProvider.fetchSchedules', e, st);
          }
          
          result.add(GroupWithSchedules(
            group: group,
            upcomingSchedules: schedules.take(3).toList(),
          ));
        }
        
        result.sort((a, b) => b.group.updatedAt.compareTo(a.group.updatedAt));
        return result;
      } catch (e, st) {
        _logError('userGroupsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 사용자의 모임 목록 (단순 조회용 - 하위 호환)
final userGroupsWithSchedulesProvider = FutureProvider.autoDispose<List<GroupWithSchedules>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final groupsSnapshot = await _firebase.groupsCollection
        .where('memberIds', arrayContains: userId)
        .limit(30)
        .get();
    
    final result = <GroupWithSchedules>[];
    final now = DateTime.now();
    
    for (final doc in groupsSnapshot.docs) {
      final group = GroupModel.fromFirestore(doc.data(), id: doc.id);
      
      // 해당 모임의 다가오는 일정 조회
      List<GroupScheduleModel> schedules = [];
      try {
        final schedulesSnapshot = await _firebase.schedulesCollection
            .where('groupId', isEqualTo: group.id)
            .get();
        
        schedules = schedulesSnapshot.docs
            .map((doc) => GroupScheduleModel.fromFirestore(doc.data(), id: doc.id))
            .where((s) => s.startTime.isAfter(now))
            .toList();
        
        schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      } catch (e, st) {
        _logError('userGroupsWithSchedulesProvider.fetchSchedules', e, st);
      }
      
      result.add(GroupWithSchedules(
        group: group,
        upcomingSchedules: schedules.take(3).toList(),
      ));
    }
    
    result.sort((a, b) => b.group.updatedAt.compareTo(a.group.updatedAt));
    return result;
  } catch (e, st) {
    _logError('userGroupsWithSchedulesProvider', e, st);
    return [];
  }
});
