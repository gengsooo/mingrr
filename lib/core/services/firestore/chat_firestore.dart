import '../../../models/chat_model.dart';
import '../../utils/app_logger.dart';
import 'firestore_base.dart';

/// 채팅(Chat) 도메인 Firestore CRUD mixin
mixin ChatFirestore on FirestoreBase {

  Future<void> createChatRoom(ChatRoomModel chatRoom) async {
    try {
      await firebase.chatRoomsCollection.doc(chatRoom.id).set(chatRoom.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createChatRoom (chatRoomId: ${chatRoom.id})', e);
      rethrow;
    }
  }
  
  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await firebase.chatRoomsCollection.doc(chatRoomId).get();
      if (!doc.exists) return null;
      return ChatRoomModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getChatRoom (chatRoomId: $chatRoomId)', e);
      rethrow;
    }
  }
  
  Future<void> updateChatRoom(ChatRoomModel chatRoom) async {
    try {
      await firebase.chatRoomsCollection.doc(chatRoom.id).update(chatRoom.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateChatRoom (chatRoomId: ${chatRoom.id})', e);
      rethrow;
    }
  }
  
  Stream<List<ChatRoomModel>> watchUserChatRooms(String userId) {
    return firebase.chatRoomsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  Future<void> sendMessage(String chatRoomId, MessageModel message) async {
    try {
      final batch = firestore.batch();
      
      batch.set(
        firebase.messagesCollection(chatRoomId).doc(message.id),
        message.toFirestore(),
      );
      
      batch.update(
        firebase.chatRoomsCollection.doc(chatRoomId),
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
    return firebase.messagesCollection(chatRoomId)
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
}
