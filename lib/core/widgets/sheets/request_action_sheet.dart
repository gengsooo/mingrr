import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../common_widgets.dart';
import '../mingrr_image.dart';

/// ============================================================
/// 신청 수락/거절 액션 시트 공통 컴포넌트
/// 
/// 데이팅, 교배, 소모임 가입, 알바 지원 등 모든 신청에 대한
/// 수락/거절 액션을 통일된 UI로 제공
/// 
/// 사용 예시:
/// ```dart
/// showRequestActionSheet(
///   context,
///   type: RequestActionType.dating,
///   senderName: '뽀삐',
///   senderImageUrl: pet.imageUrl,
///   message: request.message,
///   onAccept: () => acceptRequest(),
///   onReject: () => rejectRequest(),
/// );
/// ```
/// ============================================================

/// 신청 액션 타입
enum RequestActionType {
  dating,    // 데이트 신청
  breeding,  // 교배 신청
  groupJoin, // 소모임 가입 신청
  jobApply;  // 알바 지원
  
  String get title {
    switch (this) {
      case RequestActionType.dating:
        return '데이트 신청';
      case RequestActionType.breeding:
        return '교배 신청';
      case RequestActionType.groupJoin:
        return '가입 신청';
      case RequestActionType.jobApply:
        return '알바 지원';
    }
  }
  
  String get acceptText {
    switch (this) {
      case RequestActionType.dating:
        return '수락하기';
      case RequestActionType.breeding:
        return '수락하기';
      case RequestActionType.groupJoin:
        return '승인하기';
      case RequestActionType.jobApply:
        return '수락하기';
    }
  }
  
  String get rejectText {
    switch (this) {
      case RequestActionType.dating:
        return '거절하기';
      case RequestActionType.breeding:
        return '거절하기';
      case RequestActionType.groupJoin:
        return '거절하기';
      case RequestActionType.jobApply:
        return '거절하기';
    }
  }
  
  IconData get icon {
    switch (this) {
      case RequestActionType.dating:
        return AppIcons.dating;
      case RequestActionType.breeding:
        return AppIcons.breeding;
      case RequestActionType.groupJoin:
        return AppIcons.group;
      case RequestActionType.jobApply:
        return AppIcons.work;
    }
  }
  
  Color getAccentColor(BuildContext context) {
    switch (this) {
      case RequestActionType.dating:
      case RequestActionType.breeding:
        return context.features.dating;
      case RequestActionType.groupJoin:
        return context.features.social;
      case RequestActionType.jobApply:
        return context.features.market;
    }
  }
}

/// 신청 액션 시트 표시
Future<void> showRequestActionSheet(
  BuildContext context, {
  required RequestActionType type,
  required String senderName,
  String? senderImageUrl,
  String? senderSubtitle,
  String? message,
  DateTime? requestedAt,
  required VoidCallback onAccept,
  required VoidCallback onReject,
  VoidCallback? onViewProfile,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => RequestActionSheet(
      type: type,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      senderSubtitle: senderSubtitle,
      message: message,
      requestedAt: requestedAt,
      onAccept: onAccept,
      onReject: onReject,
      onViewProfile: onViewProfile,
    ),
  );
}

class RequestActionSheet extends StatelessWidget {
  final RequestActionType type;
  final String senderName;
  final String? senderImageUrl;
  final String? senderSubtitle;
  final String? message;
  final DateTime? requestedAt;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onViewProfile;

  const RequestActionSheet({
    super.key,
    required this.type,
    required this.senderName,
    this.senderImageUrl,
    this.senderSubtitle,
    this.message,
    this.requestedAt,
    required this.onAccept,
    required this.onReject,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = type.getAccentColor(context);
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들 바
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.gapL),
              
              // 헤더: 타입 아이콘 + 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon, color: accentColor, size: 24),
                  const SizedBox(width: AppSizes.gapS),
                  Text(
                    type.title,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.gapXL),
              
              // 발신자 정보
              _buildSenderInfo(context, colorScheme, accentColor),
              
              // 메시지 (있는 경우)
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.gapL),
                _buildMessage(context, colorScheme),
              ],
              
              // 신청 시간 (있는 경우)
              if (requestedAt != null) ...[
                const SizedBox(height: AppSizes.gapM),
                Text(
                  _formatDateTime(requestedAt!),
                  style: AppTextStyles.captionSmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              
              const SizedBox(height: AppSizes.gapXL),
              
              // 액션 버튼
              _buildActionButtons(context, colorScheme, accentColor),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSenderInfo(BuildContext context, ColorScheme colorScheme, Color accentColor) {
    return GestureDetector(
      onTap: onViewProfile,
      child: Row(
        children: [
          // 프로필 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            child: SizedBox(
              width: 60,
              height: 60,
              child: MingrrImage(
                imageUrl: senderImageUrl,
                fit: BoxFit.cover,
                accentColor: accentColor,
                placeholderIcon: AppIcons.profile,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          
          // 이름 + 부제목
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: AppTextStyles.titleLarge(context),
                ),
                if (senderSubtitle != null) ...[
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    senderSubtitle!,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 프로필 보기 버튼
          if (onViewProfile != null)
            Icon(
              AppIcons.chevronRight,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessage(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '메시지',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.gapXS),
          Text(
            message!,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme, Color accentColor) {
    return Row(
      children: [
        // 거절 버튼
        Expanded(
          child: MingrrButton(
            text: type.rejectText,
            onPressed: () {
              Navigator.pop(context);
              onReject();
            },
            isOutlined: true,
            textColor: colorScheme.error,
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        // 수락 버튼
        Expanded(
          child: MingrrButton(
            text: type.acceptText,
            onPressed: () {
              Navigator.pop(context);
              onAccept();
            },
            backgroundColor: accentColor,
          ),
        ),
      ],
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }
}
