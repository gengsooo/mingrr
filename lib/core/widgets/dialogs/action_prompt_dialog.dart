import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../common_widgets.dart';

/// ============================================================
/// MingrrActionPromptDialog - 액션 유도 다이얼로그
/// 
/// 아이콘 + 제목 + 메시지 + 주 버튼 + 보조 버튼 구조의 공통 다이얼로그
/// 평가 유도, 완료 알림 등 사용자에게 액션을 유도하는 경우에 사용
/// 
/// 사용법:
/// ```dart
/// showActionPromptDialog(
///   context,
///   icon: Container(
///     decoration: BoxDecoration(color: Colors.green.withValues(alpha: AppOpacity.o10), shape: BoxShape.circle),
///     child: Icon(Icons.check_circle, color: Colors.green),
///   ),
///   title: '🎉 활동이 완료되었어요!',
///   message: '홍길동님과의 만남은 어떠셨나요?',
///   primaryButtonText: '지금 평가하기',
///   onPrimaryPressed: () => showRatingModal(...),
///   secondaryButtonText: '나중에 하기',
/// );
/// ```
/// ============================================================

/// 액션 유도 다이얼로그 표시 함수
void showActionPromptDialog(
  BuildContext context, {
  required Widget icon,
  required String title,
  String? message,
  required String primaryButtonText,
  required VoidCallback onPrimaryPressed,
  String? secondaryButtonText,
  VoidCallback? onSecondaryPressed,
  Color? primaryButtonColor,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => MingrrActionPromptDialog(
      icon: icon,
      title: title,
      message: message,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      primaryButtonColor: primaryButtonColor,
    ),
  );
}

/// MingrrActionPromptDialog 위젯
class MingrrActionPromptDialog extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? message;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Color? primaryButtonColor;

  const MingrrActionPromptDialog({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.primaryButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = primaryButtonColor ?? colorScheme.primary;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            SizedBox(
              width: 64,
              height: 64,
              child: icon,
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 제목
            Text(
              title,
              style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            
            // 메시지
            if (message != null) ...[
              const SizedBox(height: AppSizes.gapS),
              Text(
                message!,
                style: AppTextStyles.bodyLarge(context).withColor(colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: AppSizes.gapXL),
            
            // 주 버튼
            MingrrButton(
              text: primaryButtonText,
              onPressed: () {
                Navigator.pop(context);
                onPrimaryPressed();
              },
              backgroundColor: buttonColor,
              textColor: Colors.white,
              height: 48,
            ),
            
            // 보조 버튼
            if (secondaryButtonText != null) ...[
              const SizedBox(height: AppSizes.gapS),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onSecondaryPressed?.call();
                },
                child: Text(
                  secondaryButtonText!,
                  style: AppTextStyles.bodyMedium(context).withColor(colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 원형 아이콘 컨테이너 빌더 (편의 함수)
  static Widget buildCircleIcon({
    required IconData icon,
    required Color color,
    double size = 64,
    double iconSize = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }

  /// 그라데이션 아이콘 컨테이너 빌더 (편의 함수)
  static Widget buildGradientIcon({
    required IconData icon,
    required List<Color> colors,
    double size = 64,
    double iconSize = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
