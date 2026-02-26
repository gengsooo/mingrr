import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../badges/request_status_badge.dart';
import '../common_widgets.dart';
import '../mingrr_image.dart';

/// ============================================================
/// 신청 카드 공통 컴포넌트
/// 
/// 데이팅, 교배, 소모임 가입, 알바 지원 등 모든 신청을
/// 통일된 카드 UI로 표시
/// 
/// 사용 예시:
/// ```dart
/// RequestCard(
///   type: RequestCardType.dating,
///   senderName: '뽀삐',
///   senderImageUrl: pet.imageUrl,
///   status: UnifiedRequestStatus.pending,
///   onTap: () => showActionSheet(),
/// )
/// ```
/// ============================================================

/// 신청 카드 타입
enum RequestCardType {
  dating,    // 데이트 신청
  breeding,  // 교배 신청
  groupJoin, // 소모임 가입 신청
  jobApply;  // 알바 지원
  
  String get label {
    switch (this) {
      case RequestCardType.dating:
        return '데이트 신청';
      case RequestCardType.breeding:
        return '교배 신청';
      case RequestCardType.groupJoin:
        return '가입 신청';
      case RequestCardType.jobApply:
        return '알바 지원';
    }
  }
  
  IconData get icon {
    switch (this) {
      case RequestCardType.dating:
        return AppIcons.dating;
      case RequestCardType.breeding:
        return AppIcons.breeding;
      case RequestCardType.groupJoin:
        return AppIcons.group;
      case RequestCardType.jobApply:
        return AppIcons.work;
    }
  }
  
  Color getAccentColor(BuildContext context) {
    switch (this) {
      case RequestCardType.dating:
      case RequestCardType.breeding:
        return context.features.dating;
      case RequestCardType.groupJoin:
        return context.features.social;
      case RequestCardType.jobApply:
        return context.features.market;
    }
  }
}

/// 신청 카드 위젯
class RequestCard extends StatelessWidget {
  final RequestCardType type;
  final String senderName;
  final String? senderImageUrl;
  final String? senderSubtitle;
  final UnifiedRequestStatus status;
  final String? message;
  final DateTime? requestedAt;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;

  const RequestCard({
    super.key,
    required this.type,
    required this.senderName,
    this.senderImageUrl,
    this.senderSubtitle,
    required this.status,
    this.message,
    this.requestedAt,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = type.getAccentColor(context);
    final isPending = status == UnifiedRequestStatus.pending;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
          border: isPending 
              ? Border.all(color: accentColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 발신자 정보 + 상태 배지
            Row(
              children: [
                // 프로필 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  child: SizedBox(
                    width: 48,
                    height: 48,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              senderName,
                              style: AppTextStyles.titleMedium(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 상태 배지
                          RequestStatusBadge(
                            status: status,
                            size: RequestStatusBadgeSize.small,
                          ),
                        ],
                      ),
                      if (senderSubtitle != null) ...[
                        const SizedBox(height: AppSizes.gapXXS),
                        Text(
                          senderSubtitle!,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // 메시지 (있는 경우)
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  message!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            
            // 하단: 시간 + 액션 버튼
            if (requestedAt != null || (showActions && isPending)) ...[
              const SizedBox(height: AppSizes.gapM),
              Row(
                children: [
                  // 신청 시간
                  if (requestedAt != null)
                    Text(
                      _formatDateTime(requestedAt!),
                      style: AppTextStyles.captionSmall(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // 액션 버튼 (대기 중일 때만)
                  if (showActions && isPending) ...[
                    // 거절 버튼
                    if (onReject != null)
                      _ActionButton(
                        text: '거절',
                        onPressed: onReject!,
                        isAccept: false,
                      ),
                    const SizedBox(width: AppSizes.gapS),
                    // 수락 버튼
                    if (onAccept != null)
                      _ActionButton(
                        text: '수락',
                        onPressed: onAccept!,
                        isAccept: true,
                        accentColor: accentColor,
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
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

/// 액션 버튼 (수락/거절)
class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isAccept;
  final Color? accentColor;

  const _ActionButton({
    required this.text,
    required this.onPressed,
    required this.isAccept,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isAccept 
        ? (accentColor ?? colorScheme.primary)
        : colorScheme.error;
    
    return Material(
      color: isAccept ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: isAccept ? null : Border.all(color: color),
          ),
          child: Text(
            text,
            style: AppTextStyles.labelMedium(context).copyWith(
              color: isAccept ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// 비동기 로딩을 지원하는 신청 카드 위젯
/// 
/// 사용자 정보를 비동기로 로드해야 하는 경우 사용
/// (예: 소모임 가입 신청 - userId만 있고 사용자 정보 별도 조회 필요)
class AsyncRequestCard extends StatefulWidget {
  final RequestCardType type;
  final String userId;
  final UnifiedRequestStatus status;
  final String? message;
  final DateTime? requestedAt;
  final Future<Map<String, dynamic>?> Function(String userId) loadUserInfo;
  final VoidCallback? onTap;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
  final bool showActions;

  const AsyncRequestCard({
    super.key,
    required this.type,
    required this.userId,
    required this.status,
    this.message,
    this.requestedAt,
    required this.loadUserInfo,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = true,
  });

  @override
  State<AsyncRequestCard> createState() => _AsyncRequestCardState();
}

class _AsyncRequestCardState extends State<AsyncRequestCard> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final info = await widget.loadUserInfo(widget.userId);
      if (mounted) {
        setState(() {
          _userInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccept() async {
    if (_isProcessing || widget.onAccept == null) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onAccept!();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject() async {
    if (_isProcessing || widget.onReject == null) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onReject!();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = widget.type.getAccentColor(context);
    final isPending = widget.status == UnifiedRequestStatus.pending;

    // 로딩 중
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapXS),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final senderName = _userInfo?['name'] as String? ?? '알 수 없음';
    final senderImageUrl = _userInfo?['imageUrl'] as String?;
    final senderSubtitle = _userInfo?['subtitle'] as String?;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
          border: isPending 
              ? Border.all(color: accentColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 발신자 정보 + 상태 배지
            Row(
              children: [
                // 프로필 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  child: SizedBox(
                    width: 48,
                    height: 48,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              senderName,
                              style: AppTextStyles.titleMedium(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 상태 배지
                          RequestStatusBadge(
                            status: widget.status,
                            size: RequestStatusBadgeSize.small,
                          ),
                        ],
                      ),
                      if (senderSubtitle != null) ...[
                        const SizedBox(height: AppSizes.gapXXS),
                        Text(
                          senderSubtitle,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // 메시지 (있는 경우)
            if (widget.message != null && widget.message!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  widget.message!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            
            // 하단: 시간 + 액션 버튼
            if (widget.requestedAt != null || (widget.showActions && isPending)) ...[
              const SizedBox(height: AppSizes.gapM),
              Row(
                children: [
                  // 신청 시간
                  if (widget.requestedAt != null)
                    Text(
                      _formatDateTime(widget.requestedAt!),
                      style: AppTextStyles.captionSmall(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // 액션 버튼 (대기 중일 때만)
                  if (widget.showActions && isPending) ...[
                    if (_isProcessing)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      // 거절 버튼
                      if (widget.onReject != null)
                        _ActionButton(
                          text: '거절',
                          onPressed: _handleReject,
                          isAccept: false,
                        ),
                      const SizedBox(width: AppSizes.gapS),
                      // 수락 버튼
                      if (widget.onAccept != null)
                        _ActionButton(
                          text: '수락',
                          onPressed: _handleAccept,
                          isAccept: true,
                          accentColor: accentColor,
                        ),
                    ],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
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

/// 신청 카드 리스트 (빈 상태 포함)
class RequestCardList extends StatelessWidget {
  final List<Widget> cards;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Color? accentColor;

  const RequestCardList({
    super.key,
    required this.cards,
    this.emptyTitle = '신청이 없습니다',
    this.emptySubtitle = '새로운 신청이 오면 여기에 표시됩니다',
    this.emptyIcon = AppIcons.inbox,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return MingrrEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        accentColor: accentColor,
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      children: cards,
    );
  }
}
