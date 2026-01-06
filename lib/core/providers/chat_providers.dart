import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_model.dart';
import 'firebase_providers.dart';

final userChatRoomsProvider = StreamProvider<List<ChatRoomModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUserChatRooms(userId);
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatRoomId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchMessages(chatRoomId);
});
