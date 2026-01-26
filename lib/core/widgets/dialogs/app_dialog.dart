import 'package:flutter/material.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import 'dialog_buttons.dart';

/// ============================================================
/// AppDialog - 통합 알림/확인 다이얼로그
/// 
/// AlertDialog + ConfirmDialog를 통합한 공통 다이얼로그
/// 화면 중앙에 표시되며, 알림/확인 용도로 사용
/// 
/// 사용법:
/// ```dart
/// // 1. 단순 알림 (확인 버튼만)
/// await showAppDialog(
///   context,
///   type: DialogType.success,
///   title: '완료',
///   message: '저장되었습니다.',
/// );
/// 
/// // 2. 확인/취소 선택
/// final confirmed = await showAppDialog(
///   context,
///   type: DialogType.warning,
///   title: '삭제 확인',
///   message: '정말 삭제하시겠습니까?',
///   showCancel: true,
/// );
/// if (confirmed == true) { ... }
/// ```
/// ============================================================

/// 다이얼로그 타입
enum DialogType {
  // 기본 타입
  info(Icons.info_outline, '안내'),
  success(Icons.check_circle_outline, '완료'),
  warning(Icons.warning_amber_outlined, '경고'),
  error(Icons.error_outline, '오류'),
  location(Icons.location_on, '위치 인증'),
  
  // 기능별 타입
  walk(Icons.directions_walk, '산책'),
  health(Icons.favorite_outline, '건강'),
  community(Icons.group_outlined, '소모임'),
  market(Icons.store_outlined, '마켓'),
  dating(Icons.pets, '데이팅'),
  chat(Icons.chat_bubble_outline, '채팅');

  final IconData icon;
  final String defaultTitle;

  const DialogType(this.icon, this.defaultTitle);
  
  /// 빌드 시점에 context에서 색상 가져오기
  Color getColor(BuildContext context) {
    final features = context.features;
    switch (this) {
      case DialogType.info:
        return Theme.of(context).colorScheme.primary;
      case DialogType.success:
        return features.success;
      case DialogType.warning:
        return Colors.orange;
      case DialogType.error:
        return Colors.red;
      case DialogType.location:
        return Theme.of(context).colorScheme.primary;
      case DialogType.walk:
        return features.walk;
      case DialogType.health:
        return features.health;
      case DialogType.community:
        return features.social;
      case DialogType.market:
        return features.market;
      case DialogType.dating:
        return features.dating;
      case DialogType.chat:
        return features.chat;
    }
  }
}

/// 공통 다이얼로그 표시 함수
/// 
/// [showCancel]이 true이면 취소 버튼 표시, 결과로 bool 반환
/// [showCancel]이 false이면 확인 버튼만 표시
Future<bool?> showAppDialog(
  BuildContext context, {
  required DialogType type,
  String? title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool showCancel = false,
  Color? themeColor,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AppDialog(
      type: type,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      showCancel: showCancel,
      themeColor: themeColor,
      icon: icon,
    ),
  );
}

/// AppDialog 위젯
class AppDialog extends StatelessWidget {
  final DialogType type;
  final String? title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final bool showCancel;
  final Color? themeColor;
  final IconData? icon;

  const AppDialog({
    super.key,
    required this.type,
    this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.showCancel = false,
    this.themeColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = themeColor ?? type.getColor(context);
    final displayIcon = icon ?? type.icon;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: AppOpacity.o10),
                shape: BoxShape.circle,
              ),
              child: Icon(displayIcon, size: 28, color: color),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title ?? type.defaultTitle,
              style: AppTextStyles.headlineSmall(context),
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 메시지
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 버튼
            if (showCancel)
              _buildTwoButtons(context, color)
            else
              _buildSingleButton(context, color),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleButton(BuildContext context, Color color) {
    return MingrrDialogButton.confirm(
      text: confirmText ?? '확인',
      onPressed: () => Navigator.pop(context, true),
      color: color,
    );
  }

  Widget _buildTwoButtons(BuildContext context, Color color) {
    return MingrrDialogButtons(
      cancelText: cancelText ?? '취소',
      confirmText: confirmText ?? '확인',
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
      confirmColor: color,
    );
  }
}

/// 입력 다이얼로그 (텍스트 입력 받기) - DialogType 기반
/// Note: 단순 입력은 input_dialog.dart의 showInputDialog 사용
Future<String?> showAppInputDialog(
  BuildContext context, {
  required DialogType type,
  required String title,
  String? message,
  String? initialValue,
  String? hintText,
  String? confirmText,
  String? cancelText,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
}) {
  final controller = TextEditingController(text: initialValue);
  
  final colorScheme = Theme.of(context).colorScheme;
  
  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: type.getColor(context).withValues(alpha: AppOpacity.o10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, size: 20, color: type.getColor(context)),
                ),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w600),
                  ),
                ),
              ],
            ),
            
            if (message != null) ...[
              const SizedBox(height: AppSizes.gapS),
              Text(
                message,
                style: AppTextStyles.bodyMedium(context).withColor(colorScheme.onSurfaceVariant),
              ),
            ],
            
            const SizedBox(height: AppSizes.gapM),
            
            // 입력 필드
            TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  borderSide: BorderSide(color: type.getColor(context), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(AppSizes.paddingL),
              ),
              autofocus: true,
            ),
            
            const SizedBox(height: AppSizes.gapL),
            
            // 버튼
            MingrrDialogButtons(
              cancelText: cancelText ?? '취소',
              confirmText: confirmText ?? '확인',
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(ctx, value);
                }
              },
              confirmColor: type.getColor(context),
            ),
          ],
        ),
      ),
    ),
  );
}
