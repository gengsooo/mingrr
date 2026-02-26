import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'firebase_service.dart';
import '../widgets/common_widgets.dart';
import '../../models/rating_model.dart';
import '../../../app.dart' show rootNavigatorKey;

/// ============================================================
/// 푸시 알림 서비스
/// Firebase Cloud Messaging (FCM) 연동
/// ============================================================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseService _firebase = FirebaseService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// 초기화
  Future<void> initialize() async {
    // 권한 요청
    await _requestPermission();

    // FCM 토큰 가져오기
    await _getToken();

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 백그라운드에서 알림 클릭 시
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 앱이 종료된 상태에서 알림 클릭으로 열린 경우
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// 권한 요청
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('FCM 권한 상태: ${settings.authorizationStatus}');
    }
  }

  /// FCM 토큰 가져오기
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }
      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 가져오기 실패: $e');
      }
      return null;
    }
  }

  /// 토큰 갱신 시
  void _onTokenRefresh(String token) {
    _fcmToken = token;
    _saveTokenToFirestore(token);
    if (kDebugMode) {
      print('FCM Token 갱신: $token');
    }
  }

  /// 데이터베이스에 토큰 저장
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    await _firebase.usersCollection.doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 사용자 로그인 시 토큰 저장
  Future<void> saveTokenForUser(String userId) async {
    if (_fcmToken == null) {
      await _getToken();
    }
    if (_fcmToken != null) {
      await _firebase.usersCollection.doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 사용자 로그아웃 시 토큰 제거
  Future<void> removeTokenForUser(String userId) async {
    await _firebase.usersCollection.doc(userId).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  /// 포그라운드 메시지 수신
  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('포그라운드 메시지 수신: ${message.notification?.title}');
    }

    // 인앱 알림 표시 (SnackBar, 배너 등)
    _showInAppNotification(message);
  }

  /// 백그라운드에서 알림 클릭
  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('알림 클릭으로 앱 열림: ${message.data}');
    }
    _handleNotificationTap(message);
  }

  /// 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    if (kDebugMode) {
      print('알림 탭 처리: type=$type, data=$data');
    }

    // 네비게이션 처리
    _navigateToScreen(type, data);
  }

  /// 알림 타입에 따른 화면 이동
  void _navigateToScreen(String? type, Map<String, dynamic> data) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      // 채팅 관련
      case 'chat':
      case 'marketInquiry':
        final chatRoomId = data['chatRoomId'] as String?;
        if (chatRoomId != null) {
          context.push('/chat/$chatRoomId');
        } else {
          context.go('/chat');
        }
        break;

      // 데이팅 관련
      case 'datingRequest':
      case 'breedingRequest':
      case 'datingAccepted':
      case 'breedingAccepted':
      case 'datingRejected':
      case 'breedingRejected':
        context.go('/chat'); // 채팅 목록으로 이동 (신청 탭)
        break;

      // 마켓 관련
      case 'marketSold':
      case 'productLike':
        final productId = data['productId'] as String?;
        if (productId != null) {
          context.push('/market/product/$productId');
        } else {
          context.go('/market');
        }
        break;

      // 소모임 관련
      case 'groupJoinRequest':
      case 'groupJoinApproved':
      case 'groupJoinRejected':
      case 'groupSchedule':
        final groupId = data['groupId'] as String?;
        if (groupId != null) {
          context.push('/social/group/$groupId');
        } else {
          context.go('/social');
        }
        break;

      // 산책 관련
      case 'walkInvite':
      case 'walkReminder':
        context.go('/walk');
        break;

      // 반려동물 좋아요
      case 'petLike':
        final petId = data['petId'] as String?;
        if (petId != null) {
          context.push('/dating/detail/$petId');
        } else {
          context.go('/dating');
        }
        break;

      // 평가/꼬순내지수 관련
      case 'rating':
      case 'ratingReminder':
      case 'gradeChange':
      case 'scoreChange':
        context.go('/profile');
        break;

      // 기본: 알림 화면으로 이동
      default:
        context.go('/notifications');
        break;
    }
  }

  /// 인앱 알림 표시
  void _showInAppNotification(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    // SnackBar로 인앱 알림 표시
    MingrrSnackBar.withAction(
      context,
      message: '${notification.title}: ${notification.body}',
      actionLabel: '보기',
      onAction: () => _navigateToScreen(
        message.data['type'] as String?,
        message.data,
      ),
    );
  }

  /// 알림 모델에서 화면 이동 (알림 화면에서 클릭 시)
  void navigateFromNotification(BuildContext context, NotificationModel notification) {
    _navigateToScreen(notification.data['type'] as String?, notification.data);
  }

  /// 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('토픽 구독: $topic');
    }
  }

  /// 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('토픽 구독 해제: $topic');
    }
  }

  // ===== 알림 전송 (Firestore 트리거용 데이터 저장) =====

  /// 채팅 메시지 알림 저장
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.chat,
      title: senderName,
      body: message,
      data: {
        'type': 'chat',
        'chatRoomId': chatRoomId,
        'senderId': senderId,
      },
    );
  }

  /// 데이팅 신청 알림
  Future<void> sendDatingRequestNotification({
    required String recipientId,
    required String senderName,
    required String senderPetName,
    required String requestId,
    required bool isBreeding,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.datingRequest,
      title: isBreeding ? '교배 신청' : '데이팅 신청',
      body: '$senderName님의 $senderPetName가 ${isBreeding ? '교배' : '데이팅'}를 신청했어요!',
      data: {
        'type': isBreeding ? 'breedingRequest' : 'datingRequest',
        'requestId': requestId,
      },
    );
  }

  /// 데이팅 수락 알림
  Future<void> sendDatingAcceptedNotification({
    required String recipientId,
    required String accepterName,
    required String accepterPetName,
    required String chatRoomId,
    required bool isBreeding,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.datingAccepted,
      title: isBreeding ? '교배 수락됨' : '데이팅 수락됨',
      body: '$accepterName님의 $accepterPetName가 ${isBreeding ? '교배' : '데이팅'}를 수락했어요! 💕',
      data: {
        'type': isBreeding ? 'breedingAccepted' : 'datingAccepted',
        'chatRoomId': chatRoomId,
      },
    );
  }

  /// 마켓 문의 알림
  Future<void> sendMarketInquiryNotification({
    required String recipientId,
    required String senderName,
    required String productTitle,
    required String chatRoomId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.marketInquiry,
      title: '상품 문의',
      body: '$senderName님이 "$productTitle" 상품에 문의했어요',
      data: {
        'type': 'marketInquiry',
        'chatRoomId': chatRoomId,
      },
    );
  }

  /// 소모임 가입 승인 알림
  Future<void> sendGroupJoinApprovedNotification({
    required String recipientId,
    required String groupName,
    required String groupId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.groupJoinApproved,
      title: '소모임 가입 승인',
      body: '"$groupName" 소모임 가입이 승인되었어요!',
      data: {
        'type': 'groupJoinApproved',
        'groupId': groupId,
      },
    );
  }

  /// 알바 지원 알림 (알바 등록자에게)
  Future<void> sendJobApplicationNotification({
    required String recipientId,
    required String applicantName,
    required String jobTitle,
    required String applicationId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.jobApplication,
      title: '새 알바 지원',
      body: '$applicantName님이 "$jobTitle" 알바에 지원했어요 💼',
      data: {
        'type': 'jobApplication',
        'applicationId': applicationId,
      },
    );
  }

  /// 알바 지원 수락 알림 (지원자에게)
  Future<void> sendJobAcceptedNotification({
    required String recipientId,
    required String employerName,
    required String jobTitle,
    required String chatRoomId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.jobAccepted,
      title: '알바 지원 수락됨',
      body: '$employerName님이 "$jobTitle" 지원을 수락했어요! 💼',
      data: {
        'type': 'jobAccepted',
        'chatRoomId': chatRoomId,
      },
    );
  }

  /// 소모임 새 일정 알림
  Future<void> sendGroupScheduleNotification({
    required String groupId,
    required String groupName,
    required String scheduleTitle,
    required String scheduleId,
  }) async {
    // 그룹 멤버들에게 알림 전송
    final groupDoc = await _firebase.groupsCollection.doc(groupId).get();
    if (!groupDoc.exists) return;

    final memberIds = List<String>.from(groupDoc.data()?['memberIds'] ?? []);
    
    for (final memberId in memberIds) {
      await _saveNotification(
        recipientId: memberId,
        type: NotificationType.groupSchedule,
        title: groupName,
        body: '새 일정: $scheduleTitle',
        data: {
          'type': 'groupSchedule',
          'groupId': groupId,
          'scheduleId': scheduleId,
        },
      );
    }
  }

  /// 소모임 가입 신청 알림 (모임장에게)
  Future<void> sendGroupJoinRequestNotification({
    required String leaderId,
    required String groupName,
    required String groupId,
    required String applicantName,
  }) async {
    await _saveNotification(
      recipientId: leaderId,
      type: NotificationType.groupJoinRequest,
      title: '소모임 가입 신청',
      body: '$applicantName님이 "$groupName" 가입을 신청했어요',
      data: {
        'type': 'groupJoinRequest',
        'groupId': groupId,
      },
    );
  }

  /// 소모임 가입 거절 알림
  Future<void> sendGroupJoinRejectedNotification({
    required String recipientId,
    required String groupName,
    required String groupId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.groupJoinRejected,
      title: '소모임 가입 거절',
      body: '"$groupName" 소모임 가입이 거절되었어요',
      data: {
        'type': 'groupJoinRejected',
        'groupId': groupId,
      },
    );
  }

  /// 산책 초대 알림
  Future<void> sendWalkInviteNotification({
    required String recipientId,
    required String senderName,
    required String walkId,
    required String location,
    required DateTime scheduledTime,
  }) async {
    final timeStr = '${scheduledTime.month}/${scheduledTime.day} ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.walkInvite,
      title: '산책 초대',
      body: '$senderName님이 $location에서 산책을 제안했어요 ($timeStr)',
      data: {
        'type': 'walkInvite',
        'walkId': walkId,
      },
    );
  }

  /// 산책 리마인더 알림
  Future<void> sendWalkReminderNotification({
    required String recipientId,
    required String walkId,
    required String location,
    required int minutesBefore,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.walkReminder,
      title: '산책 알림',
      body: '$minutesBefore분 후 $location에서 산책이 시작됩니다!',
      data: {
        'type': 'walkReminder',
        'walkId': walkId,
      },
    );
  }

  /// 상품 판매 완료 알림 (구매자에게)
  Future<void> sendMarketSoldNotification({
    required String buyerId,
    required String productTitle,
    required String productId,
    required String sellerName,
  }) async {
    await _saveNotification(
      recipientId: buyerId,
      type: NotificationType.marketSold,
      title: '거래 완료',
      body: '"$productTitle" 거래가 완료되었어요',
      data: {
        'type': 'marketSold',
        'productId': productId,
      },
    );
  }

  /// 상품 찜 알림 (판매자에게)
  Future<void> sendProductLikeNotification({
    required String sellerId,
    required String productTitle,
    required String productId,
    required String likerName,
  }) async {
    await _saveNotification(
      recipientId: sellerId,
      type: NotificationType.productLike,
      title: '상품 찜',
      body: '$likerName님이 "$productTitle" 상품을 찜했어요 ❤️',
      data: {
        'type': 'productLike',
        'productId': productId,
      },
    );
  }

  /// 반려동물 좋아요 알림
  Future<void> sendPetLikeNotification({
    required String ownerId,
    required String petName,
    required String petId,
    required String likerName,
  }) async {
    await _saveNotification(
      recipientId: ownerId,
      type: NotificationType.petLike,
      title: '좋아요',
      body: '$likerName님이 $petName를 좋아해요 💕',
      data: {
        'type': 'petLike',
        'petId': petId,
      },
    );
  }

  /// 데이팅 거절 알림
  Future<void> sendDatingRejectedNotification({
    required String recipientId,
    required String rejecterPetName,
    required bool isBreeding,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.datingRejected,
      title: isBreeding ? '교배 거절' : '데이팅 거절',
      body: '$rejecterPetName의 ${isBreeding ? '교배' : '데이팅'} 신청이 거절되었어요',
      data: {
        'type': isBreeding ? 'breedingRejected' : 'datingRejected',
      },
    );
  }

  /// 평가 완료 알림 (상대방에게)
  /// 
  /// 평가 내용(별점, 태그)은 비공개로 처리
  /// 꼬순내지수 변동만 알림
  Future<void> sendRatingNotification({
    required String recipientId,
    required String raterName,
    required String ratingType,
    String? relatedId,
  }) async {
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.rating,
      title: '🐾 평가가 도착했어요!',
      body: '$raterName님이 평가를 남겼어요. 내 꼬순내지수에 반영됐어요.',
      data: {
        'type': 'rating',
        'ratingType': ratingType,
        'relatedId': relatedId ?? '',
      },
    );
  }

  /// 평가 요청 리마인더 알림
  Future<void> sendRatingReminderNotification({
    required String recipientId,
    required String partnerName,
    required String activityType,
    required String relatedId,
  }) async {
    final typeLabel = RatingType.fromActivityType(activityType).activityLabel;
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.ratingReminder,
      title: '📝 평가를 남겨주세요',
      body: '$partnerName님과의 $typeLabel은 어떠셨나요? 평가를 남겨주세요 🐾',
      data: {
        'type': 'ratingReminder',
        'activityType': activityType,
        'relatedId': relatedId,
      },
    );
  }

  /// 꼬순내지수 등급 변동 알림
  Future<void> sendGradeChangeNotification({
    required String recipientId,
    required String oldGrade,
    required String newGrade,
    required int oldScore,
    required int newScore,
  }) async {
    final isUpgrade = newScore > oldScore;
    final diff = newScore - oldScore;
    final diffText = isUpgrade ? '+$diff' : '$diff';
    
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.gradeChange,
      title: isUpgrade ? '🎉 등급이 올랐어요!' : '📉 등급이 변경되었어요',
      body: '$oldGrade → $newGrade ($diffText점)',
      data: {
        'type': 'gradeChange',
        'oldGrade': oldGrade,
        'newGrade': newGrade,
        'oldScore': oldScore.toString(),
        'newScore': newScore.toString(),
      },
    );
  }

  /// 꼬순내지수 점수 변동 알림 (등급 변동 없이 점수만 변동)
  Future<void> sendScoreChangeNotification({
    required String recipientId,
    required int oldScore,
    required int newScore,
  }) async {
    final isUp = newScore > oldScore;
    final diff = newScore - oldScore;
    final diffText = isUp ? '+$diff' : '$diff';
    
    await _saveNotification(
      recipientId: recipientId,
      type: NotificationType.scoreChange,
      title: isUp ? '🐾 꼬순내지수가 올랐어요!' : '꼬순내지수가 변동되었어요',
      body: '$oldScore점 → $newScore점 ($diffText점)',
      data: {
        'type': 'scoreChange',
        'oldScore': oldScore.toString(),
        'newScore': newScore.toString(),
      },
    );
  }

  /// 알림 저장 (Cloud Functions에서 FCM 전송)
  Future<void> _saveNotification({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await _firebase.firestore.collection('notifications').add({
      'recipientId': recipientId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 사용자 알림 목록 스트림
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _firebase.firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }

  /// 알림 읽음 처리
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firebase.firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// 모든 알림 읽음 처리
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firebase.firestore.batch();
    final unreadNotifications = await _firebase.firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}

/// 알림 타입
enum NotificationType {
  chat,
  datingRequest,
  datingAccepted,
  datingRejected,
  marketInquiry,
  marketSold,
  groupJoinRequest,
  groupJoinApproved,
  groupJoinRejected,
  groupSchedule,
  walkInvite,
  walkReminder,
  breedingRequest,
  breedingAccepted,
  productLike,
  petLike,
  rating,           // 평가 완료 알림
  ratingReminder,   // 평가 리마인더 알림
  gradeChange,      // 꼬순내지수 등급 변동 알림
  scoreChange,      // 꼬순내지수 점수 변동 알림
  jobApplication,   // 알바 지원 알림
  jobAccepted,      // 알바 지원 수락 알림
  system,
}

/// 알림 모델
class NotificationModel {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, {required String id}) {
    return NotificationModel(
      id: id,
      recipientId: data['recipientId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
    );
  }
}

/// 백그라운드 메시지 핸들러 (main.dart에서 등록)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('백그라운드 메시지 수신: ${message.notification?.title}');
  }
}
