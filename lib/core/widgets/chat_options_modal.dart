import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'rating_modal.dart';

/// ============================================================
/// 채팅방 옵션 모달 (공통 위젯)
/// 
/// 사용처:
/// - 채팅방 상단 더보기 버튼
/// ============================================================

enum ChatOptionType {
  rating,
  muteNotification,
  block,
  report,
  leave,
}

/// 채팅방 옵션 모달 표시 함수
void showChatOptionsModal(
  BuildContext context, {
  required String chatName,
  required String targetId,
  required VoidCallback? onMuteNotification,
  required VoidCallback? onBlock,
  required VoidCallback? onReport,
  required VoidCallback? onLeave,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => ChatOptionsModal(
      chatName: chatName,
      targetId: targetId,
      onMuteNotification: onMuteNotification,
      onBlock: onBlock,
      onReport: onReport,
      onLeave: onLeave,
    ),
  );
}

/// 채팅방 옵션 모달 위젯
class ChatOptionsModal extends StatelessWidget {
  final String chatName;
  final String targetId;
  final VoidCallback? onMuteNotification;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;
  final VoidCallback? onLeave;

  const ChatOptionsModal({
    super.key,
    required this.chatName,
    required this.targetId,
    this.onMuteNotification,
    this.onBlock,
    this.onReport,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppSizes.gapL),
            
            // 옵션 리스트
            _buildOption(
              context,
              icon: Icons.pets,
              label: '꼬순내지수 평가하기',
              subtitle: '상대방을 평가해주세요',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                showRatingModal(
                  context,
                  targetName: chatName,
                  onRatingSelected: (rating) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$chatName님을 "${rating.label}"로 평가했어요!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
            
            _buildOption(
              context,
              icon: Icons.notifications_off_outlined,
              label: '알림 끄기',
              color: AppColors.textPrimary,
              onTap: () {
                Navigator.pop(context);
                onMuteNotification?.call();
              },
            ),
            
            _buildOption(
              context,
              icon: Icons.block_outlined,
              label: '차단하기',
              color: AppColors.textPrimary,
              onTap: () {
                Navigator.pop(context);
                onBlock?.call();
              },
            ),
            
            _buildOption(
              context,
              icon: Icons.report_outlined,
              label: '신고하기',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
            
            _buildOption(
              context,
              icon: Icons.exit_to_app_outlined,
              label: '채팅방 나가기',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                onLeave?.call();
              },
            ),
            
            const SizedBox(height: AppSizes.gapL),
          ],
        ),
      ),
    );
  }

  /// 옵션 아이템
  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingL,
            vertical: AppSizes.paddingM,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppSizes.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
