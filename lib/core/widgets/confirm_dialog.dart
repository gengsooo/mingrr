import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 공통 확인 다이얼로그
/// 각 메뉴 테마 색상에 맞게 재사용 가능한 확인 다이얼로그
/// ============================================================

class ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color themeColor;
  final String title;
  final String description;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.themeColor,
    required this.title,
    required this.description,
    this.cancelText = '취소',
    this.confirmText = '확인',
    this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: themeColor),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 설명
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onCancel?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 14,
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
    );
  }
}

/// 확인 다이얼로그 표시 헬퍼 함수
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required Color themeColor,
  required String title,
  required String description,
  String cancelText = '취소',
  String confirmText = '확인',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _ConfirmDialogWithResult(
      icon: icon,
      themeColor: themeColor,
      title: title,
      description: description,
      cancelText: cancelText,
      confirmText: confirmText,
    ),
  );
}

/// 결과를 반환하는 확인 다이얼로그 (내부용)
class _ConfirmDialogWithResult extends StatelessWidget {
  final IconData icon;
  final Color themeColor;
  final String title;
  final String description;
  final String cancelText;
  final String confirmText;

  const _ConfirmDialogWithResult({
    required this.icon,
    required this.themeColor,
    required this.title,
    required this.description,
    this.cancelText = '취소',
    this.confirmText = '확인',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: themeColor),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 설명
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 14,
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
    );
  }
}

/// 마켓 종류 변경 확인 다이얼로그
Future<bool?> showMarketTypeChangeDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmDialog(
      icon: Icons.swap_horiz,
      themeColor: AppColors.market,
      title: '종류 변경',
      description: '종류를 변경하면 이전에 입력된\n정보가 사라집니다.\n종류를 수정하시겠습니까?',
      cancelText: '취소',
      confirmText: '변경',
      onConfirm: () {},
    ),
  );
}
