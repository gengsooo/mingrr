import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/chat_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 채팅 관련 Provider
/// Firebase Firestore와 연동하여 채팅 데이터 관리
/// ============================================================

// FirestoreService Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// 사용자의 채팅방 목록 (실시간 스트림)
final userChatRoomsProvider = StreamProvider.autoDispose<List<ChatRoomModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<ChatRoomModel>[]);
      }
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.watchUserChatRooms(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(<ChatRoomModel>[]),
  );
});

// 채팅 타입별 필터링된 채팅방 목록
final filteredChatRoomsProvider = Provider.autoDispose.family<List<ChatRoomModel>, String>((ref, type) {
  final chatRooms = ref.watch(userChatRoomsProvider).valueOrNull ?? [];
  
  if (type == 'all') return chatRooms;
  
  return chatRooms.where((room) {
    if (type == 'dating') {
      // 데이팅 탭: dating과 breeding 모두 포함
      return room.type == 'dating' || room.type == 'breeding';
    }
    return room.type == type;
  }).toList();
});

// 특정 채팅방의 메시지 목록 (실시간 스트림)
final chatMessagesProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, chatRoomId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchMessages(chatRoomId);
});

// 읽지 않은 메시지 총 개수
final totalUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final chatRooms = ref.watch(userChatRoomsProvider).valueOrNull ?? [];
  
  final userId = authState.valueOrNull?.uid;
  if (userId == null) return 0;
  
  return chatRooms.fold<int>(0, (sum, room) {
    return sum + (room.unreadCounts[userId] ?? 0);
  });
});
