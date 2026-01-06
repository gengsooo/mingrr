import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import '../../models/chat_model.dart';
import '../../models/dating_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/community_model.dart';
import '../../models/breeding_model.dart';
import 'firebase_service.dart';

class FirestoreService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  Future<void> createUser(UserModel user) async {
    try {
      await _firebase.usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firebase.usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateUser(UserModel user) async {
    try {
      await _firebase.usersCollection.doc(user.id).update(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteUser(String userId) async {
    try {
      await _firebase.usersCollection.doc(userId).delete();
    } catch (e) {
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
      rethrow;
    }
  }
  
  Future<PetModel?> getPet(String petId) async {
    try {
      final doc = await _firebase.petsCollection.doc(petId).get();
      if (!doc.exists) return null;
      return PetModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updatePet(PetModel pet) async {
    try {
      await _firebase.petsCollection.doc(pet.id).update(pet.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deletePet(String petId) async {
    try {
      await _firebase.petsCollection.doc(petId).delete();
    } catch (e) {
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
      rethrow;
    }
  }
  
  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firebase.chatRoomsCollection.doc(chatRoomId).get();
      if (!doc.exists) return null;
      return ChatRoomModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateChatRoom(ChatRoomModel chatRoom) async {
    try {
      await _firebase.chatRoomsCollection.doc(chatRoom.id).update(chatRoom.toFirestore());
    } catch (e) {
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
  
  Future<void> createLike(LikeModel like) async {
    try {
      await _firebase.likesCollection.doc(like.id).set(like.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateLike(LikeModel like) async {
    try {
      await _firebase.likesCollection.doc(like.id).update(like.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<LikeModel>> getReceivedLikes(String userId) async {
    try {
      final snapshot = await _firebase.likesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => LikeModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Stream<List<LikeModel>> watchReceivedLikes(String userId) {
    return _firebase.likesCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LikeModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  Future<void> createMatch(MatchModel match) async {
    try {
      await _firebase.matchesCollection.doc(match.id).set(match.toFirestore());
    } catch (e) {
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
      rethrow;
    }
  }
  
  Future<void> createProduct(ProductModel product) async {
    try {
      await _firebase.productsCollection.doc(product.id).set(product.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firebase.productsCollection.doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firebase.productsCollection.doc(product.id).update(product.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    try {
      await _firebase.productsCollection.doc(productId).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<ProductModel>> getProducts({
    ProductStatus? status,
    ProductCategory? category,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.productsCollection;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
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
      rethrow;
    }
  }
  
  Future<void> createGroup(GroupModel group) async {
    try {
      await _firebase.groupsCollection.doc(group.id).set(group.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firebase.groupsCollection.doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _firebase.groupsCollection.doc(group.id).update(group.toFirestore());
    } catch (e) {
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
      rethrow;
    }
  }
  
  Future<void> createSchedule(ScheduleModel schedule) async {
    try {
      await _firebase.schedulesCollection.doc(schedule.id).set(schedule.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<ScheduleModel>> getGroupSchedules(String groupId) async {
    try {
      final snapshot = await _firebase.schedulesCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('startTime', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> incrementProductViewCount(String productId) async {
    try {
      await _firebase.productsCollection.doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> incrementProductLikeCount(String productId) async {
    try {
      await _firebase.productsCollection.doc(productId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> decrementProductLikeCount(String productId) async {
    try {
      await _firebase.productsCollection.doc(productId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== 알바(Job) 관련 =====
  
  Future<void> createJob(JobModel job) async {
    try {
      await _firebase.jobsCollection.doc(job.id).set(job.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<JobModel?> getJob(String jobId) async {
    try {
      final doc = await _firebase.jobsCollection.doc(jobId).get();
      if (!doc.exists) return null;
      return JobModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
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
      rethrow;
    }
  }
  
  // ===== 활동 기록 관련 =====
  
  /// 사용자의 매칭 수 조회
  Future<int> getUserMatchCount(String userId) async {
    final snapshot = await _firebase.matchesCollection
        .where('user1Id', isEqualTo: userId)
        .get();
    final snapshot2 = await _firebase.matchesCollection
        .where('user2Id', isEqualTo: userId)
        .get();
    return snapshot.docs.length + snapshot2.docs.length;
  }
  
  /// 사용자의 산책 횟수 조회
  Future<int> getUserWalkCount(String userId) async {
    final snapshot = await _firebase.walksCollection
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }
  
  /// 사용자의 거래 수 조회 (판매 완료 + 구매)
  Future<int> getUserTransactionCount(String userId) async {
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
  }
  
  /// 사용자가 참여한 모임 수 조회
  Future<int> getUserGroupCount(String userId) async {
    final snapshot = await _firebase.groupsCollection
        .where('memberIds', arrayContains: userId)
        .get();
    return snapshot.docs.length;
  }
  
  /// 사용자의 전체 활동 기록 조회
  Future<Map<String, int>> getUserActivityStats(String userId) async {
    final results = await Future.wait([
      getUserMatchCount(userId),
      getUserWalkCount(userId),
      getUserTransactionCount(userId),
      getUserGroupCount(userId),
    ]);
    
    return {
      'matches': results[0],
      'walks': results[1],
      'transactions': results[2],
      'groups': results[3],
    };
  }
  
  // ===== 소모임 좋아요 관련 =====
  
  /// 소모임 좋아요 토글
  Future<bool> toggleGroupLike(String groupId, String userId) async {
    try {
      final likeId = '${userId}_$groupId';
      final likeDoc = await _firebase.groupLikesCollection.doc(likeId).get();
      
      if (likeDoc.exists) {
        // 좋아요 취소
        await _firebase.groupLikesCollection.doc(likeId).delete();
        await _firebase.groupsCollection.doc(groupId).update({
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // 좋아요 추가
        await _firebase.groupLikesCollection.doc(likeId).set({
          'userId': userId,
          'groupId': groupId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firebase.groupsCollection.doc(groupId).update({
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    } catch (e) {
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
      rethrow;
    }
  }
  
  // ===== 교배 글 관련 =====
  
  /// 교배 글 생성
  Future<void> createBreedingPost(BreedingPostModel post) async {
    try {
      await _firebase.breedingPostsCollection.doc(post.id).set(post.toFirestore());
    } catch (e) {
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
      rethrow;
    }
  }
  
  /// 교배 글 수정
  Future<void> updateBreedingPost(BreedingPostModel post) async {
    try {
      await _firebase.breedingPostsCollection.doc(post.id).update(post.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// 교배 글 삭제
  Future<void> deleteBreedingPost(String postId) async {
    try {
      await _firebase.breedingPostsCollection.doc(postId).delete();
    } catch (e) {
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

  /// 위치 인증 처리 (GPS 기반)
  Future<void> verifyLocation(String userId, String location, {GeoPoint? geoPoint}) async {
    try {
      final updateData = <String, dynamic>{
        'verifications.location': true,
        'verifications.locationAt': FieldValue.serverTimestamp(),
        'verifications.locationAddress': location,
      };
      
      if (geoPoint != null) {
        updateData['verifications.locationGeoPoint'] = geoPoint;
        updateData['homeLocation'] = geoPoint;
        updateData['homeAddress'] = location;
      }
      
      await _firebase.usersCollection.doc(userId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  /// 동물등록 인증 처리
  Future<void> verifyPetRegistration(String userId, String registrationNumber) async {
    try {
      await _firebase.usersCollection.doc(userId).update({
        'verifications.petRegistration': true,
        'verifications.petRegistrationAt': FieldValue.serverTimestamp(),
        'verifications.petRegistrationNumber': registrationNumber,
      });
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
}
