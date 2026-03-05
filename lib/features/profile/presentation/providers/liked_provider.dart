import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/favorite_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/community_post_model.dart';
import '../../../../models/group_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/pet_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 좋아요 목록 관련 Provider
/// 
/// 프로필 > 좋아요 목록 화면에서 사용
/// 탭 구성: 상품 / 반려동물 / 커뮤니티 / 소모임
/// 
/// 개선 사항:
/// - 페이지네이션: ClientPaginatedNotifier 적용
/// - 에러 처리: 디버그 로깅 추가
/// ============================================================

final _firebase = FirebaseService();
final _firestoreService = FirestoreService();
final _favoriteService = FavoriteService();

// ============================================================
// 공통: 로깅 유틸리티
// ============================================================

void _logError(String source, Object error, [StackTrace? stackTrace]) {
  AppLogger.error('LikedProvider', source, error);
}

// ============================================================
// 1. 찜한 상품 Provider
// ============================================================

/// 찜한 상품 페이지네이션 Provider
final likedProductsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<ProductModel>,
    PaginatedState<ProductModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<ProductModel>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        return await _firestoreService.getUserLikedProducts(userId);
      } catch (e, st) {
        _logError('likedProductsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 찜한 상품 목록 (단순 조회용 - 하위 호환)
final likedProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    return await _firestoreService.getUserLikedProducts(userId);
  } catch (e, st) {
    _logError('likedProductsProvider', e, st);
    return [];
  }
});

// ============================================================
// 2. 좋아요한 반려동물 Provider
// ============================================================

/// 좋아요한 반려동물 페이지네이션 Provider
final likedPetsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<PetModel>,
    PaginatedState<PetModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<PetModel>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        return await _favoriteService.getFavoritePets();
      } catch (e, st) {
        _logError('likedPetsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 좋아요한 반려동물 목록 (단순 조회용 - 하위 호환)
final likedPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    return await _favoriteService.getFavoritePets();
  } catch (e, st) {
    _logError('likedPetsProvider', e, st);
    return [];
  }
});

/// 좋아요한 반려동물 ID 목록 스트림
final likedPetIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return _favoriteService.watchFavoritePetIds().handleError((error, stackTrace) {
    AppLogger.error('LikedProvider', '좋아요한 반려동물 ID 스트림 오류', error, stackTrace);
    return <String>[];
  });
});

/// 반려동물 좋아요 토글
final petLikeToggleProvider = Provider<Future<void> Function(String petId, bool isLiked)>((ref) {
  return (String petId, bool isLiked) async {
    if (isLiked) {
      await _favoriteService.unlikePet(petId);
    } else {
      await _favoriteService.likePet(petId);
    }
    ref.invalidate(likedPetsProvider);
  };
});

// ============================================================
// 3. 좋아요한 커뮤니티 글 Provider
// ============================================================

/// 좋아요한 커뮤니티 글 페이지네이션 Provider
final likedCommunityPostsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<CommunityPostModel>,
    PaginatedState<CommunityPostModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<CommunityPostModel>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final likesSnapshot = await _firebase.feedLikesCollection
            .where('userId', isEqualTo: userId)
            .get();
        
        final postIds = likesSnapshot.docs
            .map((doc) => doc.data()['postId'] as String)
            .toList();
        
        if (postIds.isEmpty) return [];
        
        final result = <CommunityPostModel>[];
        for (final postId in postIds) {
          try {
            final postDoc = await _firebase.feedPostsCollection.doc(postId).get();
            if (postDoc.exists) {
              result.add(CommunityPostModel.fromFirestore(postDoc.data()!, id: postDoc.id));
            }
          } catch (e, st) {
            _logError('likedCommunityPostsPaginatedProvider.fetchPost', e, st);
          }
        }
        
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return result;
      } catch (e, st) {
        _logError('likedCommunityPostsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 좋아요한 커뮤니티 글 목록 (단순 조회용 - 하위 호환)
final likedCommunityPostsProvider = FutureProvider.autoDispose<List<CommunityPostModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final likesSnapshot = await _firebase.feedLikesCollection
        .where('userId', isEqualTo: userId)
        .limit(50)
        .get();
    
    final postIds = likesSnapshot.docs
        .map((doc) => doc.data()['postId'] as String)
        .toList();
    
    if (postIds.isEmpty) return [];
    
    final result = <CommunityPostModel>[];
    for (final postId in postIds) {
      try {
        final postDoc = await _firebase.feedPostsCollection.doc(postId).get();
        if (postDoc.exists) {
          result.add(CommunityPostModel.fromFirestore(postDoc.data()!, id: postDoc.id));
        }
      } catch (e, st) {
        _logError('likedCommunityPostsProvider.fetchPost', e, st);
      }
    }
    
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  } catch (e, st) {
    _logError('likedCommunityPostsProvider', e, st);
    return [];
  }
});

// ============================================================
// 4. 좋아요한 소모임 Provider
// ============================================================

/// 좋아요한 소모임 페이지네이션 Provider
final likedGroupsPaginatedProvider = StateNotifierProvider.autoDispose<
    ClientPaginatedNotifier<GroupModel>,
    PaginatedState<GroupModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  return ClientPaginatedNotifier<GroupModel>(
    fetchAll: () async {
      if (userId == null) return [];
      
      try {
        final groupIds = await _firestoreService.getUserLikedGroupIds(userId);
        
        if (groupIds.isEmpty) return [];
        
        final result = <GroupModel>[];
        for (final groupId in groupIds) {
          try {
            final group = await _firestoreService.getGroup(groupId);
            if (group != null) {
              result.add(group);
            }
          } catch (e, st) {
            _logError('likedGroupsPaginatedProvider.fetchGroup', e, st);
          }
        }
        
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return result;
      } catch (e, st) {
        _logError('likedGroupsPaginatedProvider', e, st);
        rethrow;
      }
    },
    pageSize: 20,
  );
});

/// 좋아요한 소모임 목록 (단순 조회용 - 하위 호환)
final likedGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  try {
    final groupIds = await _firestoreService.getUserLikedGroupIds(userId);
    
    if (groupIds.isEmpty) return [];
    
    final result = <GroupModel>[];
    for (final groupId in groupIds) {
      try {
        final group = await _firestoreService.getGroup(groupId);
        if (group != null) {
          result.add(group);
        }
      } catch (e, st) {
        _logError('likedGroupsProvider.fetchGroup', e, st);
      }
    }
    
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  } catch (e, st) {
    _logError('likedGroupsProvider', e, st);
    return [];
  }
});

// ============================================================
// 좋아요 토글 Provider (공통)
// ============================================================

/// 커뮤니티 글 좋아요 토글
final communityPostLikeToggleProvider = Provider<Future<bool> Function(String postId)>((ref) {
  return (String postId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return false;
    
    final likeId = '${userId}_$postId';
    final likeDoc = await _firebase.feedLikesCollection.doc(likeId).get();
    
    if (likeDoc.exists) {
      await _firebase.feedLikesCollection.doc(likeId).delete();
      ref.invalidate(likedCommunityPostsProvider);
      return false;
    } else {
      await _firebase.feedLikesCollection.doc(likeId).set({
        'userId': userId,
        'postId': postId,
        'createdAt': DateTime.now(),
      });
      ref.invalidate(likedCommunityPostsProvider);
      return true;
    }
  };
});

/// 소모임 좋아요 토글
final groupLikeToggleProvider = Provider<Future<bool> Function(String groupId)>((ref) {
  return (String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return false;
    
    final likeId = '${userId}_$groupId';
    final likeDoc = await _firebase.groupLikesCollection.doc(likeId).get();
    
    if (likeDoc.exists) {
      await _firebase.groupLikesCollection.doc(likeId).delete();
      ref.invalidate(likedGroupsProvider);
      return false;
    } else {
      await _firebase.groupLikesCollection.doc(likeId).set({
        'userId': userId,
        'groupId': groupId,
        'createdAt': DateTime.now(),
      });
      ref.invalidate(likedGroupsProvider);
      return true;
    }
  };
});
