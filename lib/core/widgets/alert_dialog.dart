import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 공통 Alert 다이얼로그
/// 정보 표시, 경고, 성공/실패 알림 등에 사용
/// 화면 중앙에 표시되는 다이얼로그 형태
/// 
/// 사용법:
/// ```dart
/// // 기본 사용
/// showAppAlert(
///   context,
///   type: AlertType.info,
///   title: '안내',
///   message: '처리가 완료되었습니다.',
/// );
/// 
/// // 결과 반환
/// final result = await showAppAlertWithResult(
///   context,
///   type: AlertType.warning,
///   title: '경고',
///   message: '계속하시겠습니까?',
/// );
/// ```
/// ============================================================

/// Alert 타입 - enum에 설정값을 직접 정의
enum AlertType {
  // 정보
  info(Icons.info_outline, AppColors.primary, '안내'),
  success(Icons.check_circle_outline, AppColors.success, '완료'),
  warning(Icons.warning_amber_outlined, AppColors.warning, '경고'),
  error(Icons.error_outline, AppColors.error, '오류'),
  
  // 기능별
  walk(Icons.directions_walk, AppColors.walk, '산책'),
  health(Icons.favorite_outline, AppColors.health, '건강'),
  community(Icons.group_outlined, AppColors.community, '소모임'),
  market(Icons.store_outlined, AppColors.market, '마켓'),
  dating(Icons.pets, AppColors.dating, '데이팅'),
  chat(Icons.chat_bubble_outline, AppColors.chat, '채팅');

  final IconData icon;
  final Color color;
  final String defaultTitle;

  const AlertType(this.icon, this.color, this.defaultTitle);
}

/// 공통 Alert 다이얼로그 위젯
class AppAlertDialog extends StatelessWidget {
  final AlertType type;
  final String? title;
  final String message;
  final String? confirmText;
  final VoidCallback? onConfirm;

  const AppAlertDialog({
    super.key,
    required this.type,
    this.title,
    required this.message,
    this.confirmText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                color: type.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, size: 28, color: type.color),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title ?? type.defaultTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.gapXS),
            
            // 메시지
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: type.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  confirmText ?? '확인',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alert 다이얼로그 표시 헬퍼 함수
Future<void> showAppAlert(
  BuildContext context, {
  required AlertType type,
  String? title,
  required String message,
  String? confirmText,
  VoidCallback? onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AppAlertDialog(
      type: type,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    ),
  );
}

/// 결과를 반환하는 Alert 다이얼로그 (await 가능)
Future<bool?> showAppAlertWithResult(
  BuildContext context, {
  required AlertType type,
  String? title,
  required String message,
  String? confirmText,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
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
                color: type.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, size: 28, color: type.color),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title ?? type.defaultTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.gapXS),
            
            // 메시지
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: type.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  confirmText ?? '확인',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 입력 다이얼로그 (텍스트 입력 받기)
Future<String?> showInputDialog(
  BuildContext context, {
  required AlertType type,
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText ?? '취소',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText ?? '확인',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

/// 커스텀 콘텐츠 다이얼로그 (위젯 직접 전달)
Future<T?> showCustomDialog<T>(
  BuildContext context, {
  required AlertType type,
  required String title,
  required Widget content,
  List<Widget>? actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 커스텀 콘텐츠
            content,
            
            // 액션 버튼
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
