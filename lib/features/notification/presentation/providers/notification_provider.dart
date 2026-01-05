import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 알림 관련 Provider
/// Firebase Firestore와 연동하여 알림 데이터 관리
/// ============================================================

final _firebase = FirebaseService();

/// 알림 서비스 Provider
final notificationServiceProvider = Provider<NotificationDataService>((ref) {
  return NotificationDataService();
});

/// 사용자 알림 목록 (실시간 스트림)
final userNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<NotificationModel>[]);
      
      return _firebase.firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc.data(), id: doc.id))
              .toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(<NotificationModel>[]),
  );
});

/// 읽지 않은 알림 개수
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// 알림 데이터 서비스
class NotificationDataService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  
  /// 알림 생성
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    
    final notification = NotificationModel(
      id: docRef.id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await docRef.set(notification.toFirestore());
  }
  
  /// 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
  
  /// 모든 알림 읽음 처리
  Future<void> markAllAsRead() async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) return;
    
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  
  /// 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
  
  /// 오래된 알림 삭제 (30일 이상)
  Future<void> deleteOldNotifications() async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) return;
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
