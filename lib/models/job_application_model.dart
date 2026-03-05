import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'marketplace_model.dart';

/// ============================================================
/// 알바 지원 모델
/// 
/// 데이팅 신청(DatingRequestModel)과 동일한 패턴으로 설계
/// Firestore 컬렉션: job_applications
/// ============================================================

/// 알바 지원 상태
enum JobApplicationStatus {
  pending,   // 대기 중
  accepted,  // 수락됨 (채팅 시작)
  rejected,  // 거절됨
  cancelled, // 지원 취소
}

/// 알바 지원 모델
class JobApplicationModel extends Equatable {
  /// 지원 ID
  final String id;
  
  /// 알바 ID
  final String jobId;
  
  /// 알바 제목 (비정규화)
  final String jobTitle;
  
  /// 알바 타입 (비정규화)
  final JobType jobType;
  
  /// 지원자 ID
  final String applicantId;
  
  /// 지원자 닉네임 (비정규화)
  final String applicantName;
  
  /// 지원자 프로필 이미지 (비정규화)
  final String? applicantImageUrl;
  
  /// 지원자 꼬순내 지수 (비정규화)
  final double applicantKkosunnaeScore;
  
  /// 알바 등록자 ID
  final String employerId;
  
  /// 한줄 메시지 (선택)
  final String? message;
  
  /// 지원 상태
  final JobApplicationStatus status;
  
  /// 지원 시간
  final DateTime createdAt;
  
  /// 응답 시간
  final DateTime? respondedAt;
  
  /// 수락 시 생성된 채팅방 ID
  final String? chatRoomId;

  const JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.jobType,
    required this.applicantId,
    required this.applicantName,
    this.applicantImageUrl,
    this.applicantKkosunnaeScore = 0.0,
    required this.employerId,
    this.message,
    this.status = JobApplicationStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.chatRoomId,
  });

  /// Firestore에서 변환
  factory JobApplicationModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return JobApplicationModel(
      id: id ?? data['id'] ?? '',
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      jobType: JobType.values.firstWhere(
        (e) => e.name == data['jobType'],
        orElse: () => JobType.care,
      ),
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantImageUrl: data['applicantImageUrl'],
      applicantKkosunnaeScore: (data['applicantKkosunnaeScore'] ?? 0.0).toDouble(),
      employerId: data['employerId'] ?? '',
      message: data['message'],
      status: JobApplicationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JobApplicationStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      chatRoomId: data['chatRoomId'],
    );
  }

  /// Firestore로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'jobType': jobType.name,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantImageUrl': applicantImageUrl,
      'applicantKkosunnaeScore': applicantKkosunnaeScore,
      'employerId': employerId,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'chatRoomId': chatRoomId,
    };
  }

  /// 상태 변경된 복사본 생성
  JobApplicationModel copyWith({
    JobApplicationStatus? status,
    DateTime? respondedAt,
    String? chatRoomId,
  }) {
    return JobApplicationModel(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      jobType: jobType,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantImageUrl: applicantImageUrl,
      applicantKkosunnaeScore: applicantKkosunnaeScore,
      employerId: employerId,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  /// 상태 라벨
  String get statusLabel {
    switch (status) {
      case JobApplicationStatus.pending:
        return '대기 중';
      case JobApplicationStatus.accepted:
        return '수락됨';
      case JobApplicationStatus.rejected:
        return '거절됨';
      case JobApplicationStatus.cancelled:
        return '취소됨';
    }
  }

  /// 알바 타입 라벨
  String get jobTypeLabel => jobType.label;

  @override
  List<Object?> get props => [
        id,
        jobId,
        jobTitle,
        jobType,
        applicantId,
        applicantName,
        applicantImageUrl,
        applicantKkosunnaeScore,
        employerId,
        message,
        status,
        createdAt,
        respondedAt,
        chatRoomId,
      ];
}
