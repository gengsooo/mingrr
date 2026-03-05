import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../services/bottom_sheet_stack_manager.dart';
import '../sheets/mingrr_bottom_sheet.dart';

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
  final stackManager = BottomSheetStackManager();
  final sheetId = BottomSheetStackManager.createSheetId(BottomSheetType.chatOptions, targetId);
  
  // 순환 감지: 같은 채팅 옵션 바텀시트가 이미 열려있으면 해당 바텀시트까지 닫기
  if (stackManager.hasCycle(sheetId)) {
    final closeCount = stackManager.popUntilAndGetCount(sheetId);
    for (int i = 0; i < closeCount; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
  
  // 스택에 등록
  stackManager.push(sheetId);
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ChatOptionsModal(
      chatName: chatName,
      targetId: targetId,
      onMuteNotification: onMuteNotification,
      onBlock: onBlock,
      onReport: onReport,
      onLeave: onLeave,
    ),
  ).then((_) {
    // 바텀시트가 닫힐 때 스택에서 제거
    stackManager.pop(sheetId);
  });
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppSizes.gapS),
            
            // 옵션 리스트
            // 평가 옵션 제거 - 활동 기반 평가만 허용 (채팅 상세 화면에서 평가)
            _buildOption(
              context,
              icon: AppIcons.notificationsOff,
              label: '알림 끄기',
              color: Theme.of(context).colorScheme.onSurface,
              onTap: () {
                Navigator.pop(context);
                onMuteNotification?.call();
              },
            ),
            
            _buildOption(
              context,
              icon: AppIcons.block,
              label: '차단하기',
              color: Theme.of(context).colorScheme.onSurface,
              onTap: () {
                Navigator.pop(context);
                onBlock?.call();
              },
            ),
            
            _buildOption(
              context,
              icon: AppIcons.report,
              label: '신고하기',
              color: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
            
            _buildOption(
              context,
              icon: AppIcons.logout,
              label: '채팅방 나가기',
              color: Theme.of(context).colorScheme.error,
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
                      style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w500).withColor(color),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSizes.gapXXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.outlineVariant),
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
