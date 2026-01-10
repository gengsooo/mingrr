import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

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
  info(Icons.info_outline, AppColors.primary, '안내'),
  success(Icons.check_circle_outline, AppColors.success, '완료'),
  warning(Icons.warning_amber_outlined, AppColors.warning, '경고'),
  error(Icons.error_outline, AppColors.error, '오류'),
  
  // 기능별 타입
  walk(Icons.directions_walk, AppColors.walk, '산책'),
  health(Icons.favorite_outline, AppColors.health, '건강'),
  community(Icons.group_outlined, AppColors.community, '소모임'),
  market(Icons.store_outlined, AppColors.market, '마켓'),
  dating(Icons.pets, AppColors.dating, '데이팅'),
  chat(Icons.chat_bubble_outline, AppColors.chat, '채팅');

  final IconData icon;
  final Color color;
  final String defaultTitle;

  const DialogType(this.icon, this.color, this.defaultTitle);
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
    final color = themeColor ?? type.color;
    final displayIcon = icon ?? type.icon;
    
    return Dialog(
      backgroundColor: AppColors.cardBackground,
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
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(displayIcon, size: 28, color: color),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title ?? type.defaultTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 메시지
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          confirmText ?? '확인',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTwoButtons(BuildContext context, Color color) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              cancelText ?? '취소',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmText ?? '확인',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// 입력 다이얼로그 (텍스트 입력 받기)
Future<String?> showInputDialog(
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
  
  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.cardBackground,
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
                    color: type.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, size: 20, color: type.color),
                ),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            
            if (message != null) ...[
              const SizedBox(height: AppSizes.gapS),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
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
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: type.color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              autofocus: true,
            ),
            
            const SizedBox(height: AppSizes.gapL),
            
            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      cancelText ?? '취소',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty) {
                        Navigator.pop(ctx, value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      confirmText ?? '확인',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
