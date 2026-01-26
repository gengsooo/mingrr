import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/chat_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 채팅 관련 Provider
/// Firebase Firestore와 연동하여 채팅 데이터 관리
/// ============================================================

// ChatService Provider
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// 데이터베이스 서비스 상태 관리
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// 사용자의 채팅방 목록 (실시간 스트림)
final userChatRoomsProvider = StreamProvider.autoDispose<List<ChatRoomModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<ChatRoomModel>[]);
      final chatService = ref.watch(chatServiceProvider);
      return chatService.watchUserChatRooms(user.uid).handleError((error, stackTrace) {
        AppLogger.error('ChatProvider', '채팅방 목록 스트림 오류', error, stackTrace);
        return <ChatRoomModel>[];
      });
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) {
      AppLogger.error('ChatProvider', '인증 상태 오류로 채팅방 로드 실패', error, stackTrace);
      return Stream.value(<ChatRoomModel>[]);
    },
  );
});

// 채팅 타입별 필터링된 채팅방 목록
final filteredChatRoomsProvider = Provider.autoDispose.family<List<ChatRoomModel>, String>((ref, type) {
  final chatRooms = ref.watch(userChatRoomsProvider).valueOrNull ?? [];
  
  if (type == 'all') return chatRooms;
  
  return chatRooms.where((room) {
    if (type == 'dating') {
      return room.type == 'dating' || room.type == 'breeding';
    }
    return room.type == type;
  }).toList();
});

// 특정 채팅방의 메시지 목록 (실시간 스트림)
final chatMessagesProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, chatRoomId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.watchMessages(chatRoomId).handleError((error, stackTrace) {
    AppLogger.error('ChatProvider', '메시지 스트림 오류 (chatRoomId: $chatRoomId)', error, stackTrace);
    return <MessageModel>[];
  });
});

// 읽지 않은 메시지 총 개수
final totalUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final chatRooms = ref.watch(userChatRoomsProvider).valueOrNull ?? [];
  
  final userId = authState.valueOrNull?.uid;
  if (userId == null) return 0;
  
  return chatRooms.fold<int>(0, (sum, room) => sum + (room.unreadCounts[userId] ?? 0));
});

// 선택된 채팅방 ID
final selectedChatRoomIdProvider = StateProvider<String?>((ref) => null);

// 소모임 이름 캐시 Provider (relatedId -> groupName)
final groupNameCacheProvider = StateProvider<Map<String, String>>((ref) => {});

// 소모임 이름 조회 Provider
final groupNameProvider = FutureProvider.autoDispose.family<String?, String>((ref, groupId) async {
  if (groupId.isEmpty) return null;
  
  // 캐시 확인
  final cache = ref.read(groupNameCacheProvider);
  if (cache.containsKey(groupId)) {
    return cache[groupId];
  }
  
  // Firebase에서 조회
  try {
    final firebaseService = FirebaseService();
    final groupDoc = await firebaseService.firestore
        .collection('groups')
        .doc(groupId)
        .get();
    
    if (groupDoc.exists) {
      final name = groupDoc.data()?['name'] as String?;
      if (name != null) {
        // 캐시에 저장
        ref.read(groupNameCacheProvider.notifier).state = {...cache, groupId: name};
        return name;
      }
    }
  } catch (e) {
    AppLogger.error('ChatProvider', '소모임 이름 조회 실패 (groupId: $groupId)', e);
  }
  return null;
});
