import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import '../../models/chat_model.dart';
import '../../models/dating_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/community_model.dart';
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
      return UserModel.fromFirestore(doc.data()!);
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
          return UserModel.fromFirestore(doc.data()!);
        });
  }
  
  Future<void> createDog(DogModel dog) async {
    try {
      await _firebase.dogsCollection.doc(dog.id).set(dog.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<DogModel?> getDog(String dogId) async {
    try {
      final doc = await _firebase.dogsCollection.doc(dogId).get();
      if (!doc.exists) return null;
      return DogModel.fromFirestore(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateDog(DogModel dog) async {
    try {
      await _firebase.dogsCollection.doc(dog.id).update(dog.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteDog(String dogId) async {
    try {
      await _firebase.dogsCollection.doc(dogId).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<DogModel>> getUserDogs(String userId) async {
    try {
      final snapshot = await _firebase.dogsCollection
          .where('ownerId', isEqualTo: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => DogModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Stream<List<DogModel>> watchUserDogs(String userId) {
    return _firebase.dogsCollection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DogModel.fromFirestore(doc.data()))
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
      return ChatRoomModel.fromFirestore(doc.data()!);
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
            .map((doc) => ChatRoomModel.fromFirestore(doc.data()))
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
            .map((doc) => MessageModel.fromFirestore(doc.data()))
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
          .map((doc) => LikeModel.fromFirestore(doc.data()))
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
            .map((doc) => LikeModel.fromFirestore(doc.data()))
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
          .map((doc) => MatchModel.fromFirestore(doc.data()))
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
      return ProductModel.fromFirestore(doc.data()!);
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
          .map((doc) => ProductModel.fromFirestore(doc.data()))
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
      return GroupModel.fromFirestore(doc.data()!);
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
          .map((doc) => GroupModel.fromFirestore(doc.data()))
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
          .map((doc) => ScheduleModel.fromFirestore(doc.data()))
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
}
