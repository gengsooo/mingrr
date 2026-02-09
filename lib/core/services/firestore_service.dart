import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import '../../models/chat_model.dart';
import '../../models/dating_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../../models/breeding_model.dart';
import '../../models/community_post_model.dart';
import 'firebase_service.dart';
import 'geohash_service.dart';
import 'transaction_service.dart';
import '../utils/app_logger.dart';

class FirestoreService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  Future<void> createUser(UserModel user) async {
    try {
      await _firebase.usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createUser (userId: ${user.id})', e);
      rethrow;
    }
  }
  
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firebase.usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUser (userId: $userId)', e);
      rethrow;
    }
  }
  
  Future<void> updateUser(UserModel user) async {
    try {
      await _firebase.usersCollection.doc(user.id).update(user.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateUser (userId: ${user.id})', e);
      rethrow;
    }
  }
  
  Future<void> deleteUser(String userId) async {
    try {
      await _firebase.usersCollection.doc(userId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteUser (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 닉네임 중복 체크
  /// [nickname] 체크할 닉네임
  /// [excludeUserId] 본인 ID (수정 시 본인 제외)
  /// Returns: true = 사용 가능, false = 이미 사용 중
  Future<bool> isNicknameAvailable(String nickname, {String? excludeUserId}) async {
    try {
      final query = await _firebase.usersCollection
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return true;
      
      // 본인인 경우 사용 가능
      if (excludeUserId != null && query.docs.first.id == excludeUserId) {
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'isNicknameAvailable (nickname: $nickname)', e);
      rethrow;
    }
  }
  
  Stream<UserModel?> watchUser(String userId) {
    return _firebase.usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc.data()!, id: doc.id);
        });
  }
  
  Future<void> createPet(PetModel pet) async {
    try {
      await _firebase.petsCollection.doc(pet.id).set(pet.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createPet (petId: ${pet.id})', e);
      rethrow;
    }
  }
  
  Future<PetModel?> getPet(String petId) async {
    try {
      final doc = await _firebase.petsCollection.doc(petId).get();
      if (!doc.exists) return null;
      return PetModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getPet (petId: $petId)', e);
      rethrow;
    }
  }
  
  Future<void> updatePet(PetModel pet) async {
    try {
      await _firebase.petsCollection.doc(pet.id).update(pet.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updatePet (petId: ${pet.id})', e);
      rethrow;
    }
  }
  
  Future<void> deletePet(String petId) async {
    try {
      await _firebase.petsCollection.doc(petId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deletePet (petId: $petId)', e);
      rethrow;
    }
  }
  
  Future<List<PetModel>> getUserPets(String userId) async {
    try {
      final snapshot = await _firebase.petsCollection
          .where('ownerId', isEqualTo: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserPets (userId: $userId)', e);
      rethrow;
    }
  }
  
  Stream<List<PetModel>> watchUserPets(String userId) {
    return _firebase.petsCollection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromFirestore(doc))
            .toList());
  }
  
  Future<void> createChatRoom(ChatRoomModel chatRoom) async {
    try {
      await _firebase.chatRoomsCollection.doc(chatRoom.id).set(chatRoom.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createChatRoom (chatRoomId: ${chatRoom.id})', e);
      rethrow;
    }
  }
  
  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firebase.chatRoomsCollection.doc(chatRoomId).get();
      if (!doc.exists) return null;
      return ChatRoomModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getChatRoom (chatRoomId: $chatRoomId)', e);
      rethrow;
    }
  }
  
  Future<void> updateChatRoom(ChatRoomModel chatRoom) async {
    try {
      await _firebase.chatRoomsCollection.doc(chatRoom.id).update(chatRoom.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateChatRoom (chatRoomId: ${chatRoom.id})', e);
      rethrow;
    }
  }
  
  Stream<List<ChatRoomModel>> watchUserChatRooms(String userId) {
    return _firebase.chatRoomsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  Future<void> sendMessage(String chatRoomId, MessageModel message) async {
    try {
      final batch = _firestore.batch();
      
      batch.set(
        _firebase.messagesCollection(chatRoomId).doc(message.id),
        message.toFirestore(),
      );
      
      batch.update(
        _firebase.chatRoomsCollection.doc(chatRoomId),
        {
          'lastMessage': message.content,
          'lastMessageSenderId': message.senderId,
          'lastMessageAt': message.sentAt,
        },
      );
      
      await batch.commit();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'sendMessage (chatRoomId: $chatRoomId)', e);
      rethrow;
    }
  }
  
  Stream<List<MessageModel>> watchMessages(String chatRoomId) {
    return _firebase.messagesCollection(chatRoomId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  // ===== 데이팅 신청 관련 =====
  
  Future<void> createDatingRequest(DatingRequestModel request) async {
    try {
      await _firebase.datingRequestsCollection.doc(request.id).set(request.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createDatingRequest (requestId: ${request.id})', e);
      rethrow;
    }
  }
  
  Future<void> updateDatingRequest(DatingRequestModel request) async {
    try {
      await _firebase.datingRequestsCollection.doc(request.id).update(request.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateDatingRequest (requestId: ${request.id})', e);
      rethrow;
    }
  }
  
  Future<List<DatingRequestModel>> getReceivedDatingRequests(String userId) async {
    try {
      final snapshot = await _firebase.datingRequestsCollection
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
    return _firebase.datingRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  Future<void> createMatch(MatchModel match) async {
    try {
      await _firebase.matchesCollection.doc(match.id).set(match.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createMatch (matchId: ${match.id})', e);
      rethrow;
    }
  }
  
  Future<List<MatchModel>> getUserMatches(String userId) async {
    try {
      final snapshot = await _firebase.matchesCollection
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
  
  Future<void> createProduct(ProductModel product) async {
    try {
      await _firebase.productsCollection.doc(product.id).set(product.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createProduct (productId: ${product.id})', e);
      rethrow;
    }
  }
  
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firebase.productsCollection.doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getProduct (productId: $productId)', e);
      rethrow;
    }
  }
  
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firebase.productsCollection.doc(product.id).update(product.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateProduct (productId: ${product.id})', e);
      rethrow;
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    try {
      await _firebase.productsCollection.doc(productId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteProduct (productId: $productId)', e);
      rethrow;
    }
  }
  
  Future<List<ProductModel>> getProducts({
    ProductStatus? status,
    ProductCategory? category,
    ProductType? type,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.productsCollection;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getProducts', e);
      rethrow;
    }
  }
  
  Future<void> createGroup(GroupModel group) async {
    try {
      await _firebase.groupsCollection.doc(group.id).set(group.toFirestore());
      
      // 생성자의 소모임 카운터 증가 (생성자도 멤버에 포함됨)
      if (group.creatorId.isNotEmpty) {
        await _firebase.usersCollection.doc(group.creatorId).update({
          'groupCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createGroup (groupId: ${group.id})', e);
      rethrow;
    }
  }
  
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firebase.groupsCollection.doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getGroup (groupId: $groupId)', e);
      rethrow;
    }
  }
  
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _firebase.groupsCollection.doc(group.id).update(group.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateGroup (groupId: ${group.id})', e);
      rethrow;
    }
  }
  
  Future<List<GroupModel>> getPublicGroups({int limit = 20}) async {
    try {
      final snapshot = await _firebase.groupsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getPublicGroups', e);
      rethrow;
    }
  }
  
  Future<void> createSchedule(GroupScheduleModel schedule) async {
    try {
      await _firebase.schedulesCollection.doc(schedule.id).set(schedule.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createSchedule (scheduleId: ${schedule.id})', e);
      rethrow;
    }
  }
  
  Future<List<GroupScheduleModel>> getGroupSchedules(String groupId) async {
    try {
      final snapshot = await _firebase.schedulesCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('startTime', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => GroupScheduleModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getGroupSchedules (groupId: $groupId)', e);
      rethrow;
    }
  }
  
  Future<void> incrementProductViewCount(String productId) async {
    try {
      await _firebase.productsCollection.doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'incrementProductViewCount (productId: $productId)', e);
      rethrow;
    }
  }
  
  // ===== 알바(Job) 관련 =====
  
  Future<void> createJob(JobModel job) async {
    try {
      await _firebase.jobsCollection.doc(job.id).set(job.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createJob (jobId: ${job.id})', e);
      rethrow;
    }
  }
  
  Future<JobModel?> getJob(String jobId) async {
    try {
      final doc = await _firebase.jobsCollection.doc(jobId).get();
      if (!doc.exists) return null;
      return JobModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getJob (jobId: $jobId)', e);
      rethrow;
    }
  }
  
  Future<List<JobModel>> getJobs({int limit = 20, JobType? type}) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.jobsCollection
          .where('status', isEqualTo: 'recruiting');
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getJobs', e);
      rethrow;
    }
  }
  
  Stream<List<JobModel>> watchJobs({JobType? type}) {
    Query<Map<String, dynamic>> query = _firebase.jobsCollection
        .where('status', isEqualTo: 'recruiting');
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  Future<void> deleteJob(String jobId) async {
    try {
      await _firebase.jobsCollection.doc(jobId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteJob (jobId: $jobId)', e);
      rethrow;
    }
  }
  
  // ===== 활동 기록 관련 =====
  
  /// 사용자의 전체 활동 기록 조회 (카운터 필드 활용 - 최적화)
  /// 
  /// UserModel에 저장된 카운터 필드를 직접 읽어 추가 쿼리 없이 통계 반환
  /// - 이벤트 발생 시 카운터가 자동 증가/감소되므로 항상 최신 상태 유지
  Future<Map<String, int>> getUserActivityStats(String userId) async {
    try {
      final userDoc = await _firebase.usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return {
          'walks': 0,
          'matches': 0,
          'transactions': 0,
          'posts': 0,
          'groups': 0,
        };
      }
      
      final data = userDoc.data()!;
      return {
        'walks': data['walkCount'] ?? 0,
        'matches': data['matchCount'] ?? 0,
        'transactions': data['transactionCount'] ?? 0,
        'posts': data['postCount'] ?? 0,
        'groups': data['groupCount'] ?? 0,
      };
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserActivityStats (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 사용자의 매칭 수 조회 (userIds 배열 활용 - 최적화)
  /// 
  /// MatchModel의 userIds 배열 필드를 활용하여 단일 쿼리로 조회
  Future<int> getUserMatchCount(String userId) async {
    try {
      final snapshot = await _firebase.matchesCollection
          .where('userIds', arrayContains: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserMatchCount (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 사용자의 산책 횟수 조회 (실제 기록 기반)
  Future<int> getUserWalkCount(String userId) async {
    try {
      final snapshot = await _firebase.walksCollection
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserWalkCount (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 사용자의 거래 수 조회 (판매 완료 + 구매)
  Future<int> getUserTransactionCount(String userId) async {
    try {
      // 판매 완료
      final soldSnapshot = await _firebase.productsCollection
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'sold')
          .get();
      // 구매
      final boughtSnapshot = await _firebase.productsCollection
          .where('buyerId', isEqualTo: userId)
          .get();
      return soldSnapshot.docs.length + boughtSnapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserTransactionCount (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 사용자가 참여한 모임 수 조회
  Future<int> getUserGroupCount(String userId) async {
    try {
      final snapshot = await _firebase.groupsCollection
          .where('memberIds', arrayContains: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserGroupCount (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 사용자의 커뮤니티 게시글 수 조회
  Future<int> getUserPostCount(String userId) async {
    try {
      final snapshot = await _firebase.feedPostsCollection
          .where('authorId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserPostCount (userId: $userId)', e);
      rethrow;
    }
  }
  
  // ===== 소모임 좋아요 관련 =====
  
  /// 소모임 좋아요 토글 (TransactionService 위임)
  Future<bool> toggleGroupLike(String groupId, String userId) async {
    try {
      return await TransactionService.toggleGroupLike(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'toggleGroupLike (groupId: $groupId)', e);
      rethrow;
    }
  }
  
  /// 소모임 좋아요 여부 확인
  Future<bool> isGroupLiked(String groupId, String userId) async {
    try {
      final likeId = '${userId}_$groupId';
      final doc = await _firebase.groupLikesCollection.doc(likeId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
  
  /// 사용자가 좋아요한 소모임 목록
  Future<List<String>> getUserLikedGroupIds(String userId) async {
    try {
      final snapshot = await _firebase.groupLikesCollection
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data()['groupId'] as String).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 소모임 삭제
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firebase.groupsCollection.doc(groupId).delete();
      // 관련 좋아요도 삭제
      final likes = await _firebase.groupLikesCollection
          .where('groupId', isEqualTo: groupId)
          .get();
      for (final doc in likes.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteGroup (groupId: $groupId)', e);
      rethrow;
    }
  }
  
  // ===== 검색 관련 =====
  
  /// 상품 검색
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      // 데이터베이스는 전문 검색을 지원하지 않으므로 제목 기반 검색
      final snapshot = await _firebase.productsCollection
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
          .where((p) => 
              p.title.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchProducts (query: $query)', e);
      rethrow;
    }
  }
  
  /// 소모임 검색
  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      final snapshot = await _firebase.groupsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
          .where((g) => 
              g.name.toLowerCase().contains(lowerQuery) ||
              g.description.toLowerCase().contains(lowerQuery) ||
              g.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchGroups (query: $query)', e);
      rethrow;
    }
  }
  
  /// 알바 검색
  Future<List<JobModel>> searchJobs(String query) async {
    try {
      final snapshot = await _firebase.jobsCollection
          .where('status', isEqualTo: 'recruiting')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id))
          .where((j) => 
              j.title.toLowerCase().contains(lowerQuery) ||
              j.description.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchJobs (query: $query)', e);
      rethrow;
    }
  }
  
  // ===== 교배 글 관련 =====
  
  /// 교배 글 생성
  Future<void> createBreedingPost(BreedingPostModel post) async {
    try {
      await _firebase.breedingPostsCollection.doc(post.id).set(post.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createBreedingPost (postId: ${post.id})', e);
      rethrow;
    }
  }
  
  /// 교배 글 조회
  Future<BreedingPostModel?> getBreedingPost(String postId) async {
    try {
      final doc = await _firebase.breedingPostsCollection.doc(postId).get();
      if (!doc.exists) return null;
      return BreedingPostModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getBreedingPost (postId: $postId)', e);
      rethrow;
    }
  }
  
  /// 교배 글 수정
  Future<void> updateBreedingPost(BreedingPostModel post) async {
    try {
      await _firebase.breedingPostsCollection.doc(post.id).update(post.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateBreedingPost (postId: ${post.id})', e);
      rethrow;
    }
  }
  
  /// 교배 글 삭제
  Future<void> deleteBreedingPost(String postId) async {
    try {
      await _firebase.breedingPostsCollection.doc(postId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteBreedingPost (postId: $postId)', e);
      rethrow;
    }
  }
  
  /// 활성 교배 글 목록 조회
  Future<List<BreedingPostModel>> getActiveBreedingPosts({int limit = 20}) async {
    try {
      final snapshot = await _firebase.breedingPostsCollection
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => BreedingPostModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getActiveBreedingPosts', e);
      rethrow;
    }
  }
  
  /// 교배 글 검색
  Future<List<BreedingPostModel>> searchBreedingPosts(String query) async {
    try {
      final snapshot = await _firebase.breedingPostsCollection
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => BreedingPostModel.fromFirestore(doc.data(), id: doc.id))
          .where((p) => 
              p.title.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchBreedingPosts (query: $query)', e);
      rethrow;
    }
  }

  /// 커뮤니티 게시글 검색
  Future<List<CommunityPostModel>> searchCommunityPosts(String query) async {
    try {
      final snapshot = await _firebase.feedPostsCollection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => CommunityPostModel.fromFirestore(doc.data()!, id: doc.id))
          .where((p) => 
              p.content.toLowerCase().contains(lowerQuery) ||
              p.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchCommunityPosts (query: $query)', e);
      rethrow;
    }
  }

  // ============================================================
  // 인증 관련 메서드
  // ============================================================

  /// 사용자 인증 상태 조회
  Future<Map<String, bool>> getUserVerifications(String userId) async {
    try {
      final doc = await _firebase.usersCollection.doc(userId).get();
      if (!doc.exists) {
        return {
          'identity': false,
          'location': false,
          'petRegistration': false,
        };
      }
      
      final data = doc.data()!;
      final verifications = data['verifications'] as Map<String, dynamic>?;
      
      return {
        'identity': verifications?['identity'] ?? false,
        'location': verifications?['location'] ?? false,
        'petRegistration': verifications?['petRegistration'] ?? false,
      };
    } catch (e) {
      return {
        'identity': false,
        'location': false,
        'petRegistration': false,
      };
    }
  }

  /// 인증 상태 업데이트
  Future<void> updateUserVerification(String userId, String verificationType, bool isVerified) async {
    try {
      await _firebase.usersCollection.doc(userId).update({
        'verifications.$verificationType': isVerified,
        'verifications.${verificationType}At': isVerified ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 본인 인증 처리
  Future<void> verifyIdentity(String userId) async {
    await updateUserVerification(userId, 'identity', true);
  }

  /// 동물등록 인증 처리 (API 검증 결과 저장)
  /// 
  /// [userId]: 사용자 ID
  /// [registrationNumber]: 동물등록번호
  /// [animalData]: API에서 받은 동물 정보 (선택)
  /// [matchedPetId]: 매칭된 반려동물 ID (선택)
  Future<void> verifyPetRegistration(
    String userId, 
    String registrationNumber, {
    Map<String, dynamic>? animalData,
    String? matchedPetId,
  }) async {
    try {
      final updateData = {
        'verifications.petRegistration': true,
        'verifications.petRegistrationAt': FieldValue.serverTimestamp(),
        'verifications.petRegistrationNumber': registrationNumber,
      };
      
      // API 응답 데이터 저장
      if (animalData != null) {
        updateData['verifications.petRegistrationData'] = animalData;
      }
      
      // 매칭된 반려동물 ID 저장
      if (matchedPetId != null) {
        updateData['verifications.petRegistrationMatchedPetId'] = matchedPetId;
      }
      
      await _firebase.usersCollection.doc(userId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }
  
  /// 반려동물에 동물등록 인증 정보 연결
  /// 
  /// [petId]: 반려동물 ID
  /// [registrationNumber]: 동물등록번호
  /// [animalData]: API에서 받은 동물 정보
  Future<void> linkPetRegistration(
    String petId,
    String registrationNumber,
    Map<String, dynamic> animalData,
  ) async {
    try {
      await _firebase.petsCollection.doc(petId).update({
        'registrationNumber': registrationNumber,
        'isRegistrationVerified': true,
        'registrationVerifiedAt': FieldValue.serverTimestamp(),
        'registrationData': animalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// 동물등록번호로 반려동물 찾기
  Future<PetModel?> findPetByRegistrationNumber(String userId, String registrationNumber) async {
    try {
      final snapshot = await _firebase.petsCollection
          .where('ownerId', isEqualTo: userId)
          .where('registrationNumber', isEqualTo: registrationNumber)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return PetModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      rethrow;
    }
  }

  /// 인증 상태 스트림
  Stream<Map<String, bool>> watchUserVerifications(String userId) {
    return _firebase.usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'identity': false,
          'location': false,
          'petRegistration': false,
        };
      }
      
      final data = doc.data()!;
      final verifications = data['verifications'] as Map<String, dynamic>?;
      
      return {
        'identity': verifications?['identity'] ?? false,
        'location': verifications?['location'] ?? false,
        'petRegistration': verifications?['petRegistration'] ?? false,
      };
    });
  }

  // ============================================================
  // 차단 관련 메서드
  // ============================================================

  /// 사용자 차단
  /// [blockerId] 차단하는 사용자 ID
  /// [blockedId] 차단당하는 사용자 ID
  /// [reason] 차단 사유 (선택)
  Future<void> blockUser(String blockerId, String blockedId, {String? reason}) async {
    try {
      final blockId = '${blockerId}_$blockedId';
      await _firebase.blocksCollection.doc(blockId).set({
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
      await _firebase.blocksCollection.doc(blockId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// 차단 여부 확인
  Future<bool> isUserBlocked(String blockerId, String blockedId) async {
    try {
      final blockId = '${blockerId}_$blockedId';
      final doc = await _firebase.blocksCollection.doc(blockId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 내가 차단한 사용자 목록 조회
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final snapshot = await _firebase.blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data()['blockedId'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// 차단한 사용자 목록 스트림
  Stream<List<String>> watchBlockedUserIds(String userId) {
    return _firebase.blocksCollection
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['blockedId'] as String)
            .toList());
  }

  // ============================================================
  // 상품 찜(북마크) 관련 메서드
  // ============================================================

  /// 상품 찜하기 토글 (TransactionService 위임)
  /// Returns: true = 찜 추가됨, false = 찜 해제됨
  Future<bool> toggleProductLike(String productId, String userId) async {
    return TransactionService.toggleProductLike(
      productId: productId,
      userId: userId,
    );
  }

  /// 상품 찜 여부 확인
  Future<bool> isProductLiked(String productId, String userId) async {
    try {
      final likeId = '${userId}_$productId';
      final doc = await _firebase.productLikesCollection.doc(likeId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 사용자가 찜한 상품 ID 목록
  Future<List<String>> getUserLikedProductIds(String userId) async {
    try {
      final snapshot = await _firebase.productLikesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()['productId'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// 사용자가 찜한 상품 목록 조회
  Future<List<ProductModel>> getUserLikedProducts(String userId) async {
    try {
      final productIds = await getUserLikedProductIds(userId);
      if (productIds.isEmpty) return [];
      
      final products = <ProductModel>[];
      for (final id in productIds) {
        final product = await getProduct(id);
        if (product != null) {
          products.add(product);
        }
      }
      return products;
    } catch (e) {
      return [];
    }
  }

  /// 찜한 상품 ID 목록 스트림
  Stream<List<String>> watchUserLikedProductIds(String userId) {
    return _firebase.productLikesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['productId'] as String)
            .toList());
  }

  // ============================================================
  // 소모임 가입 신청 관련 메서드
  // ============================================================

  /// 가입 신청 생성
  Future<void> createJoinRequest({
    required String groupId,
    required String userId,
    String? message,
  }) async {
    try {
      await _firebase.groupJoinRequestsCollection.add({
        'groupId': groupId,
        'userId': userId,
        'message': message,
        'status': JoinRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 특정 모임의 가입 신청 목록 조회 (대기중만)
  Future<List<GroupJoinRequestModel>> getPendingJoinRequests(String groupId) async {
    try {
      final snapshot = await _firebase.groupJoinRequestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => GroupJoinRequestModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 모임의 가입 신청 목록 스트림 (대기중만)
  Stream<List<GroupJoinRequestModel>> watchPendingJoinRequests(String groupId) {
    return _firebase.groupJoinRequestsCollection
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupJoinRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 가입 신청 승인
  Future<void> approveJoinRequest({
    required String requestId,
    required String groupId,
    required String userId,
    required String respondedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. 신청 상태 업데이트
      batch.update(_firebase.groupJoinRequestsCollection.doc(requestId), {
        'status': JoinRequestStatus.approved.name,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': respondedBy,
      });
      
      // 2. 모임 멤버 목록에 추가
      batch.update(_firebase.groupsCollection.doc(groupId), {
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// 가입 신청 거절
  Future<void> rejectJoinRequest({
    required String requestId,
    required String respondedBy,
  }) async {
    try {
      await _firebase.groupJoinRequestsCollection.doc(requestId).update({
        'status': JoinRequestStatus.rejected.name,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': respondedBy,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자가 해당 모임에 가입 신청했는지 확인
  Future<bool> hasUserRequestedJoin(String groupId, String userId) async {
    try {
      final snapshot = await _firebase.groupJoinRequestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 대기중인 가입 신청 수 조회
  Future<int> getPendingJoinRequestCount(String groupId) async {
    try {
      final snapshot = await _firebase.groupJoinRequestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ===== 서버 사이드 필터링 + GeoHash 쿼리 =====

  /// 상품 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  /// 
  /// [type] 상품 타입 (sell/share/job)
  /// [status] 상품 상태
  /// [lastDocument] 페이지네이션 커서
  /// [limit] 페이지 크기
  Future<({List<ProductModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getProductsPaginated({
    ProductType? type,
    ProductStatus? status,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.productsCollection;
      
      // 서버 사이드 필터링
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // 페이지네이션
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GeoHash 기반 상품 검색 (반경 내)
  /// 
  /// [centerGeohash] 중심점 GeoHash
  /// [radiusKm] 반경 (km)
  /// [type] 상품 타입
  /// [status] 상품 상태
  Future<List<ProductModel>> getProductsByGeohash({
    required String centerGeohash,
    required double radiusKm,
    ProductType? type,
    ProductStatus? status,
  }) async {
    try {
      final bounds = GeoHashService.getBoundsForRadius(
        GeoPoint(0, 0), // 실제로는 centerGeohash에서 역산 필요
        radiusKm,
      );
      
      // GeoHash prefix 기반 범위 쿼리
      final precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4);
      final prefix = centerGeohash.substring(0, precision);
      
      Query<Map<String, dynamic>> query = _firebase.productsCollection
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~');
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      final snapshot = await query.get();
      
      var products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
      
      // 타입 필터 (클라이언트 사이드 - 복합 인덱스 제한)
      if (type != null) {
        products = products.where((p) => p.type == type).toList();
      }
      
      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// 소모임 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<GroupModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getGroupsPaginated({
    bool? isPublic,
    String? category,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.groupsCollection;
      
      // 서버 사이드 필터링
      if (isPublic != null) {
        query = query.where('isPublic', isEqualTo: isPublic);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // 페이지네이션
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GeoHash 기반 소모임 검색 (반경 내)
  Future<List<GroupModel>> getGroupsByGeohash({
    required String centerGeohash,
    required double radiusKm,
    bool? isPublic,
  }) async {
    try {
      final precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4);
      final prefix = centerGeohash.substring(0, precision.clamp(1, centerGeohash.length));
      
      Query<Map<String, dynamic>> query = _firebase.groupsCollection
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~');
      
      if (isPublic != null) {
        query = query.where('isPublic', isEqualTo: isPublic);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 반려동물 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<PetModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getPetsPaginated({
    bool? isBreedingAvailable,
    String? species,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.petsCollection;
      
      // 서버 사이드 필터링
      if (isBreedingAvailable != null) {
        query = query.where('isBreedingAvailable', isEqualTo: isBreedingAvailable);
      }
      if (species != null) {
        query = query.where('species', isEqualTo: species);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // 페이지네이션
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => PetModel.fromFirestore(doc)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GeoHash 기반 반려동물 검색 (반경 내 - 주인 위치 기준)
  Future<List<PetModel>> getPetsByOwnerGeohash({
    required String centerGeohash,
    required double radiusKm,
    bool? isBreedingAvailable,
  }) async {
    try {
      final precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4);
      final prefix = centerGeohash.substring(0, precision.clamp(1, centerGeohash.length));
      
      // 먼저 해당 범위 내 사용자 조회
      final usersSnapshot = await _firebase.usersCollection
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~')
          .get();
      
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
      if (userIds.isEmpty) return [];
      
      // 해당 사용자들의 반려동물 조회
      Query<Map<String, dynamic>> query = _firebase.petsCollection
          .where('ownerId', whereIn: userIds.take(10).toList()); // Firestore whereIn 제한
      
      if (isBreedingAvailable != null) {
        query = query.where('isBreedingAvailable', isEqualTo: isBreedingAvailable);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 커뮤니티 게시글 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<CommunityPostModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getCommunityPostsPaginated({
    CommunityCategory? category,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.feedPostsCollection;
      
      // 서버 사이드 필터링
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // 페이지네이션
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => CommunityPostModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 알바 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<JobModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getJobsPaginated({
    JobType? type,
    String? status,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.jobsCollection;
      
      // 서버 사이드 필터링
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // 페이지네이션
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자 GeoHash 업데이트
  Future<void> updateUserGeohash(String userId, GeoPoint location) async {
    try {
      final geohash = GeoHashService.encodeGeoPoint(location);
      await _firebase.usersCollection.doc(userId).update({
        'geohash': geohash,
        'homeLocation': location,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 상품 GeoHash 업데이트
  Future<void> updateProductGeohash(String productId, GeoPoint location) async {
    try {
      final geohash = GeoHashService.encodeGeoPoint(location);
      await _firebase.productsCollection.doc(productId).update({
        'geohash': geohash,
        'location': location,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 소모임 GeoHash 업데이트
  Future<void> updateGroupGeohash(String groupId, GeoPoint location) async {
    try {
      final geohash = GeoHashService.encodeGeoPoint(location);
      await _firebase.groupsCollection.doc(groupId).update({
        'geohash': geohash,
        'location': location,
      });
    } catch (e) {
      rethrow;
    }
  }
}
