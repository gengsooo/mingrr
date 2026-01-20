import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/feature_colors.dart';
import '../theme/app_text_styles.dart';

/// ============================================================
/// 공통 로딩 위젯 모음
/// 
/// 앱 전체에서 통일된 로딩 UI를 제공합니다.
/// - MingrrLoadingDialog: 팝업 형태의 로딩 (작업 중 화면 차단)
/// - MingrrLoadingOverlay: 화면 내 오버레이 로딩 (부분 로딩)
/// - MingrrLoadingIndicator: 인라인 로딩 인디케이터
/// ============================================================

/// 로딩 타입 (색상 결정용)
enum MingrrLoadingType {
  primary,
  walk,
  dating,
  market,
  community,
  chat,
  health,
  success,
}

// ============================================================
// 1. 로딩 팝업 다이얼로그 (MingrrLoadingDialog)
// ============================================================

/// 팝업 형태의 로딩 다이얼로그
class MingrrLoadingDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final MingrrLoadingType type;
  final Color? customColor;

  const MingrrLoadingDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.type = MingrrLoadingType.primary,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
      contentPadding: const EdgeInsets.all(AppSizes.paddingXXL),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.gapLL),
          Text(
            title,
            style: AppTextStyles.titleLarge(context),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.gapS),
            Text(
              subtitle!,
              style: AppTextStyles.secondary(context),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getColor(BuildContext context) {
    if (customColor != null) return customColor!;
    switch (type) {
      case MingrrLoadingType.walk:
        return context.features.walk;
      case MingrrLoadingType.dating:
        return context.features.dating;
      case MingrrLoadingType.market:
        return context.features.market;
      case MingrrLoadingType.community:
        return context.features.social;
      case MingrrLoadingType.chat:
        return context.features.chat;
      case MingrrLoadingType.health:
        return context.features.health;
      case MingrrLoadingType.success:
        return context.features.success;
      case MingrrLoadingType.primary:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

/// 로딩 다이얼로그 표시
void showMingrrLoading(
  BuildContext context, {
  required String title,
  String? subtitle,
  MingrrLoadingType type = MingrrLoadingType.primary,
  Color? customColor,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => MingrrLoadingDialog(
      title: title,
      subtitle: subtitle,
      type: type,
      customColor: customColor,
    ),
  );
}

/// 로딩 다이얼로그 닫기
void hideMingrrLoading(BuildContext context) {
  if (context.mounted) Navigator.of(context).pop();
}

// ============================================================
// 2. 로딩 오버레이 (MingrrLoadingOverlay)
// ============================================================

/// 화면 내 오버레이 형태의 로딩
class MingrrLoadingOverlay extends StatelessWidget {
  final String? message;
  final String? subMessage;
  final MingrrLoadingType type;
  final Color? customColor;
  final bool showBackground;

  const MingrrLoadingOverlay({
    super.key,
    this.message,
    this.subMessage,
    this.type = MingrrLoadingType.primary,
    this.customColor,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: showBackground 
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.9)
          : Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: color,
                  ),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSizes.gapLL),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL, vertical: AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: AppSizes.gapM),
                    Text(
                      message!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (subMessage != null) ...[
              const SizedBox(height: AppSizes.gapM),
              Text(
                subMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getColor(BuildContext context) {
    if (customColor != null) return customColor!;
    switch (type) {
      case MingrrLoadingType.walk:
        return context.features.walk;
      case MingrrLoadingType.dating:
        return context.features.dating;
      case MingrrLoadingType.market:
        return context.features.market;
      case MingrrLoadingType.community:
        return context.features.social;
      case MingrrLoadingType.chat:
        return context.features.chat;
      case MingrrLoadingType.health:
        return context.features.health;
      case MingrrLoadingType.success:
        return context.features.success;
      case MingrrLoadingType.primary:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

// ============================================================
// 3. 인라인 로딩 인디케이터 (MingrrLoadingIndicator)
// ============================================================

/// 인라인 로딩 인디케이터 (버튼 내부, 리스트 아이템 등)
/// 
/// 무한 회전 로딩과 진행률 표시 모두 지원:
/// - value가 null이면 무한 회전 (indeterminate)
/// - value가 0.0~1.0이면 진행률 표시 (determinate)
class MingrrLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final MingrrLoadingType type;
  final Color? customColor;
  final double? value;           // null = 무한 회전, 0.0~1.0 = 진행률
  final Color? backgroundColor;  // 진행률 배경색

  const MingrrLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.type = MingrrLoadingType.primary,
    this.customColor,
    this.value,
    this.backgroundColor,
  });
  
  /// 작은 사이즈 (버튼 내부용)
  const MingrrLoadingIndicator.small({
    super.key,
    this.type = MingrrLoadingType.primary,
    this.customColor,
    this.value,
    this.backgroundColor,
  }) : size = 18, strokeWidth = 2;
  
  /// 중간 사이즈 (기본)
  const MingrrLoadingIndicator.medium({
    super.key,
    this.type = MingrrLoadingType.primary,
    this.customColor,
    this.value,
    this.backgroundColor,
  }) : size = 24, strokeWidth = 2.5;
  
  /// 큰 사이즈 (전체 화면용)
  const MingrrLoadingIndicator.large({
    super.key,
    this.type = MingrrLoadingType.primary,
    this.customColor,
    this.value,
    this.backgroundColor,
  }) : size = 32, strokeWidth = 3;
  
  /// 진행률 표시 전용 (0.0~1.0)
  const MingrrLoadingIndicator.progress({
    super.key,
    required this.value,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.type = MingrrLoadingType.primary,
    this.customColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
        value: value,
        backgroundColor: backgroundColor,
      ),
    );
  }
  
  Color _getColor(BuildContext context) {
    if (customColor != null) return customColor!;
    switch (type) {
      case MingrrLoadingType.walk:
        return context.features.walk;
      case MingrrLoadingType.dating:
        return context.features.dating;
      case MingrrLoadingType.market:
        return context.features.market;
      case MingrrLoadingType.community:
        return context.features.social;
      case MingrrLoadingType.chat:
        return context.features.chat;
      case MingrrLoadingType.health:
        return context.features.health;
      case MingrrLoadingType.success:
        return context.features.success;
      case MingrrLoadingType.primary:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

// ============================================================
// 4. 전체 화면 로딩 (MingrrFullScreenLoading)
// ============================================================

/// 전체 화면 로딩 (Scaffold body 대체용)
class MingrrFullScreenLoading extends StatelessWidget {
  final String? message;
  final String? subMessage;
  final MingrrLoadingType type;
  final Color? customColor;

  const MingrrFullScreenLoading({
    super.key,
    this.message,
    this.subMessage,
    this.type = MingrrLoadingType.primary,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: color,
                  ),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSizes.gapXL),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (subMessage != null) ...[
              const SizedBox(height: AppSizes.gapS),
              Text(
                subMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getColor(BuildContext context) {
    if (customColor != null) return customColor!;
    switch (type) {
      case MingrrLoadingType.walk:
        return context.features.walk;
      case MingrrLoadingType.dating:
        return context.features.dating;
      case MingrrLoadingType.market:
        return context.features.market;
      case MingrrLoadingType.community:
        return context.features.social;
      case MingrrLoadingType.chat:
        return context.features.chat;
      case MingrrLoadingType.health:
        return context.features.health;
      case MingrrLoadingType.success:
        return context.features.success;
      case MingrrLoadingType.primary:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
