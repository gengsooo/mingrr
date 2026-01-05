import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 알림 모델
/// 앱 내 알림 데이터 구조
/// ============================================================

/// 알림 타입
enum NotificationType {
  /// 데이팅 관련
  likeReceived('좋아요 받음', 'dating'),
  likeAccepted('좋아요 수락됨', 'dating'),
  matchSuccess('매칭 성공', 'dating'),
  
  /// 교배 관련
  breedingRequest('교배 신청', 'breeding'),
  breedingAccepted('교배 수락', 'breeding'),
  
  /// 채팅 관련
  newMessage('새 메시지', 'chat'),
  
  /// 마켓 관련
  productInquiry('상품 문의', 'market'),
  productSold('판매 완료', 'market'),
  
  /// 소모임 관련
  groupJoinRequest('가입 신청', 'community'),
  groupJoinAccepted('가입 승인', 'community'),
  groupNewSchedule('새 일정', 'community'),
  
  /// 시스템 관련
  system('시스템 알림', 'system');

  final String label;
  final String category;

  const NotificationType(this.label, this.category);
}

/// 알림 모델
class NotificationModel extends Equatable {
  /// 알림 ID
  final String id;
  
  /// 받는 사용자 ID
  final String userId;
  
  /// 알림 타입
  final NotificationType type;
  
  /// 제목
  final String title;
  
  /// 내용
  final String body;
  
  /// 관련 데이터 (targetId, targetType 등)
  final Map<String, dynamic>? data;
  
  /// 읽음 여부
  final bool isRead;
  
  /// 생성일
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return NotificationModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, title, body, data, isRead, createdAt];
}
