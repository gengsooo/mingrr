import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../../models/dating_model.dart';
import '../../../models/group_model.dart';
import '../../../models/job_application_model.dart';

/// ============================================================
/// 신청 상태 배지 공통 컴포넌트
/// 
/// 데이팅, 교배, 소모임 가입, 알바 지원 등 모든 신청 상태를 
/// 통일된 디자인으로 표시
/// 
/// 사용 예시:
/// ```dart
/// RequestStatusBadge.fromDating(request.status)
/// RequestStatusBadge.fromGroup(joinRequest.status)
/// RequestStatusBadge.fromJob(application.status)
/// ```
/// ============================================================

/// 신청 상태 배지 크기
enum RequestStatusBadgeSize {
  small,
  medium,
  large;
  
  double get fontSize {
    switch (this) {
      case RequestStatusBadgeSize.small:
        return 10;
      case RequestStatusBadgeSize.medium:
        return 12;
      case RequestStatusBadgeSize.large:
        return 14;
    }
  }
  
  double get iconSize {
    switch (this) {
      case RequestStatusBadgeSize.small:
        return 12;
      case RequestStatusBadgeSize.medium:
        return 14;
      case RequestStatusBadgeSize.large:
        return 16;
    }
  }
  
  EdgeInsets get padding {
    switch (this) {
      case RequestStatusBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case RequestStatusBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case RequestStatusBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
  }
}

/// 통합 신청 상태 (UI 표시용)
enum UnifiedRequestStatus {
  pending,   // 대기 중
  accepted,  // 수락됨
  rejected,  // 거절됨
  cancelled, // 취소됨
  expired;   // 만료됨
  
  String get label {
    switch (this) {
      case UnifiedRequestStatus.pending:
        return '대기 중';
      case UnifiedRequestStatus.accepted:
        return '수락됨';
      case UnifiedRequestStatus.rejected:
        return '거절됨';
      case UnifiedRequestStatus.cancelled:
        return '취소됨';
      case UnifiedRequestStatus.expired:
        return '만료됨';
    }
  }
  
  IconData get icon {
    switch (this) {
      case UnifiedRequestStatus.pending:
        return AppIcons.accessTime;
      case UnifiedRequestStatus.accepted:
        return AppIcons.success;
      case UnifiedRequestStatus.rejected:
        return AppIcons.close;
      case UnifiedRequestStatus.cancelled:
        return AppIcons.cancel;
      case UnifiedRequestStatus.expired:
        return AppIcons.accessTime;
    }
  }
  
  Color getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case UnifiedRequestStatus.pending:
        return colorScheme.tertiary;
      case UnifiedRequestStatus.accepted:
        return colorScheme.primary;
      case UnifiedRequestStatus.rejected:
        return colorScheme.error;
      case UnifiedRequestStatus.cancelled:
        return colorScheme.onSurfaceVariant;
      case UnifiedRequestStatus.expired:
        return colorScheme.outline;
    }
  }
  
  /// DatingRequestStatus에서 변환
  static UnifiedRequestStatus fromDating(DatingRequestStatus status) {
    switch (status) {
      case DatingRequestStatus.pending:
        return UnifiedRequestStatus.pending;
      case DatingRequestStatus.accepted:
        return UnifiedRequestStatus.accepted;
      case DatingRequestStatus.rejected:
        return UnifiedRequestStatus.rejected;
      case DatingRequestStatus.cancelled:
        return UnifiedRequestStatus.cancelled;
      case DatingRequestStatus.expired:
        return UnifiedRequestStatus.expired;
    }
  }
  
  /// JoinRequestStatus에서 변환
  static UnifiedRequestStatus fromGroup(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.pending:
        return UnifiedRequestStatus.pending;
      case JoinRequestStatus.approved:
        return UnifiedRequestStatus.accepted;
      case JoinRequestStatus.rejected:
        return UnifiedRequestStatus.rejected;
    }
  }
  
  /// JobApplicationStatus에서 변환
  static UnifiedRequestStatus fromJob(JobApplicationStatus status) {
    switch (status) {
      case JobApplicationStatus.pending:
        return UnifiedRequestStatus.pending;
      case JobApplicationStatus.accepted:
        return UnifiedRequestStatus.accepted;
      case JobApplicationStatus.rejected:
        return UnifiedRequestStatus.rejected;
      case JobApplicationStatus.cancelled:
        return UnifiedRequestStatus.cancelled;
    }
  }
}

/// 신청 상태 배지 위젯
class RequestStatusBadge extends StatelessWidget {
  final UnifiedRequestStatus status;
  final RequestStatusBadgeSize size;
  final bool showIcon;
  final Color? customColor;
  final String? customLabel;

  const RequestStatusBadge({
    super.key,
    required this.status,
    this.size = RequestStatusBadgeSize.medium,
    this.showIcon = true,
    this.customColor,
    this.customLabel,
  });
  
  /// 데이팅/교배 신청 상태에서 생성
  factory RequestStatusBadge.fromDating(
    DatingRequestStatus status, {
    RequestStatusBadgeSize size = RequestStatusBadgeSize.medium,
    bool showIcon = true,
  }) {
    return RequestStatusBadge(
      status: UnifiedRequestStatus.fromDating(status),
      size: size,
      showIcon: showIcon,
    );
  }
  
  /// 소모임 가입 신청 상태에서 생성
  factory RequestStatusBadge.fromGroup(
    JoinRequestStatus status, {
    RequestStatusBadgeSize size = RequestStatusBadgeSize.medium,
    bool showIcon = true,
  }) {
    return RequestStatusBadge(
      status: UnifiedRequestStatus.fromGroup(status),
      size: size,
      showIcon: showIcon,
    );
  }
  
  /// 알바 지원 상태에서 생성
  factory RequestStatusBadge.fromJob(
    JobApplicationStatus status, {
    RequestStatusBadgeSize size = RequestStatusBadgeSize.medium,
    bool showIcon = true,
  }) {
    return RequestStatusBadge(
      status: UnifiedRequestStatus.fromJob(status),
      size: size,
      showIcon: showIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? status.getColor(context);
    final label = customLabel ?? status.label;
    
    return Container(
      padding: size.padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: color.withValues(alpha: AppOpacity.o30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              status.icon,
              size: size.iconSize,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelMedium(context).copyWith(
              fontSize: size.fontSize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 신청 상태 텍스트 (배지 없이 텍스트만)
class RequestStatusText extends StatelessWidget {
  final UnifiedRequestStatus status;
  final TextStyle? style;
  final Color? customColor;
  final String? customLabel;

  const RequestStatusText({
    super.key,
    required this.status,
    this.style,
    this.customColor,
    this.customLabel,
  });
  
  factory RequestStatusText.fromDating(DatingRequestStatus status, {TextStyle? style}) {
    return RequestStatusText(
      status: UnifiedRequestStatus.fromDating(status),
      style: style,
    );
  }
  
  factory RequestStatusText.fromGroup(JoinRequestStatus status, {TextStyle? style}) {
    return RequestStatusText(
      status: UnifiedRequestStatus.fromGroup(status),
      style: style,
    );
  }
  
  factory RequestStatusText.fromJob(JobApplicationStatus status, {TextStyle? style}) {
    return RequestStatusText(
      status: UnifiedRequestStatus.fromJob(status),
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? status.getColor(context);
    final label = customLabel ?? status.label;
    
    return Text(
      label,
      style: (style ?? AppTextStyles.labelMedium(context)).copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
