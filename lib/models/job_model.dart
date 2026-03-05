import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_icons.dart';

/// ============================================================
/// 알바(펫시터/산책 등) 모델
/// ============================================================

/// 알바 타입
enum JobType {
  care('돌봄', AppIcons.care),
  walk('산책', AppIcons.walk),
  bath('목욕', AppIcons.bath),
  training('훈련', AppIcons.training),
  other('기타', AppIcons.more);

  final String label;
  final IconData icon;

  const JobType(this.label, this.icon);
}

/// 알바 상태
enum JobStatus {
  recruiting, // 모집중
  reserved,   // 예약됨
  completed,  // 완료
  cancelled,  // 취소됨
}

/// 알바 모델
class JobModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final JobType type;
  final JobStatus status;
  final int price;
  final String priceUnit; // '일', '회', '시간'
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime; // 시작 시간 (HH:mm 형식)
  final String? endTime; // 종료 시간 (HH:mm 형식)
  final bool isTimeFlexible; // 시간 미정 여부
  final int? duration; // 시간 단위
  final GeoPoint? location;
  final String? address;
  final List<String> imageUrls;
  final int chatCount;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    this.status = JobStatus.recruiting,
    required this.price,
    required this.priceUnit,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isTimeFlexible = false,
    this.duration,
    this.location,
    this.address,
    this.imageUrls = const [],
    this.chatCount = 0,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeString {
    switch (type) {
      case JobType.care:
        return '돌봄';
      case JobType.walk:
        return '산책';
      case JobType.bath:
        return '목욕';
      case JobType.training:
        return '훈련';
      case JobType.other:
        return '기타';
    }
  }

  String get priceString => '${_formatPrice(price)}원/$priceUnit';
  
  /// 가격 포맷팅 (천 단위 콤마)
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String get periodString {
    if (startDate != null && endDate != null) {
      return '${startDate!.month}/${startDate!.day} ~ ${endDate!.month}/${endDate!.day}';
    }
    if (duration != null) {
      return '$duration시간';
    }
    return '';
  }
  
  /// 시간 문자열 (시간 미정 포함)
  String get timeString {
    if (isTimeFlexible) {
      return '시간 미정';
    }
    final startStr = startTime ?? '미정';
    final endStr = endTime ?? '미정';
    if (startTime != null || endTime != null) {
      return '$startStr ~ $endStr';
    }
    return '';
  }
  
  /// 기간 + 시간 전체 문자열
  String get fullPeriodString {
    final period = periodString;
    final time = timeString;
    if (period.isNotEmpty && time.isNotEmpty) {
      return '$period ($time)';
    }
    return period.isNotEmpty ? period : time;
  }

  factory JobModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return JobModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: JobType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => JobType.other,
      ),
      status: JobStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JobStatus.recruiting,
      ),
      price: data['price'] ?? 0,
      priceUnit: data['priceUnit'] ?? '회',
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      startTime: data['startTime'],
      endTime: data['endTime'],
      isTimeFlexible: data['isTimeFlexible'] ?? false,
      duration: data['duration'],
      location: data['location'],
      address: data['address'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      chatCount: data['chatCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'price': price,
      'priceUnit': priceUnit,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'startTime': startTime,
      'endTime': endTime,
      'isTimeFlexible': isTimeFlexible,
      'duration': duration,
      'location': location,
      'address': address,
      'imageUrls': imageUrls,
      'chatCount': chatCount,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        type,
        status,
        price,
        priceUnit,
        startDate,
        endDate,
        startTime,
        endTime,
        isTimeFlexible,
        duration,
        location,
        address,
        imageUrls,
        chatCount,
        likeCount,
        createdAt,
        updatedAt,
      ];
}
