import 'package:flutter/material.dart';
import '../theme/feature_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 위치 확인 말풍선 위젯
/// 
/// 사용처:
/// - 프로필 > 인증 배지 > 위치인증 카드 상단
/// - 홈 > 산책하러가기 카드 상단
/// 
/// 기능:
/// - 위치 불일치 시 말풍선 형태로 알림 표시
/// - "현재 위치로 변경" / "맞아요" 버튼 제공
/// ============================================================

/// 말풍선 위치 (꼬리 방향)
enum BubblePosition {
  /// 위젯 위에 표시 (꼬리가 아래로)
  above,
  /// 위젯 아래에 표시 (꼬리가 위로)
  below,
}

/// 위치 확인 말풍선 위젯
class LocationBubbleWidget extends StatelessWidget {
  /// 저장된 주소 (표시용)
  final String? savedAddress;
  
  /// 현재 위치로 변경 콜백
  final VoidCallback? onUpdateLocation;
  
  /// 맞아요 (무시) 콜백
  final VoidCallback? onDismiss;
  
  /// 말풍선 위치
  final BubblePosition position;
  
  /// 테마 색상 (기본: primary)
  final Color? accentColor;

  const LocationBubbleWidget({
    super.key,
    this.savedAddress,
    this.onUpdateLocation,
    this.onDismiss,
    this.position = BubblePosition.above,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = accentColor ?? colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 꼬리가 위로 (below 위치일 때)
        if (position == BubblePosition.below)
          _buildTail(context, color, isUp: true),
        
        // 말풍선 본체
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(color: color.withValues(alpha: AppOpacity.o30)),
            boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: color),
                  const SizedBox(width: AppSizes.gapXS),
                  Text(
                    '현재 위치가 맞나요?',
                    style: AppTextStyles.titleSmall(context).withWeight(FontWeight.w600),
                  ),
                ],
              ),
              
              // 저장된 주소 표시
              if (savedAddress != null && savedAddress!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.gapSM),
                Text(
                  '저장된 위치: $savedAddress',
                  style: AppTextStyles.caption(context),
                ),
              ],
              
              const SizedBox(height: 10),
              
              // 버튼들
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 현재 위치로 변경 버튼
                  _buildActionButton(
                    context,
                    label: '위치 변경',
                    icon: Icons.my_location,
                    color: color,
                    isPrimary: true,
                    onTap: onUpdateLocation,
                  ),
                  const SizedBox(width: AppSizes.gapS),
                  // 맞아요 버튼
                  _buildActionButton(
                    context,
                    label: '맞아요',
                    icon: Icons.check,
                    color: colorScheme.outline,
                    isPrimary: false,
                    onTap: onDismiss,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 꼬리가 아래로 (above 위치일 때)
        if (position == BubblePosition.above)
          _buildTail(context, color, isUp: false),
      ],
    );
  }

  /// 말풍선 꼬리
  Widget _buildTail(BuildContext context, Color color, {required bool isUp}) {
    return CustomPaint(
      size: const Size(16, 8),
      painter: _BubbleTailPainter(
        color: Theme.of(context).colorScheme.surface,
        borderColor: color.withValues(alpha: AppOpacity.o30),
        isUp: isUp,
      ),
    );
  }

  /// 액션 버튼
  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: isPrimary ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isPrimary ? Colors.white : color,
            ),
            const SizedBox(width: AppSizes.gapXS),
            Text(
              label,
              style: AppTextStyles.labelMedium(context).withWeight(FontWeight.w600).withColor(
                isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 말풍선 꼬리 페인터
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isUp;

  _BubbleTailPainter({
    required this.color,
    required this.borderColor,
    required this.isUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    
    if (isUp) {
      // 꼬리가 위로 (아래 위젯을 가리킴)
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      // 꼬리가 아래로 (위 위젯을 가리킴)
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 위치 불일치 알림 배너 (홈 화면용)
/// 
/// 산책하러가기 카드 위에 표시되는 간단한 배너 형태
class LocationMismatchBanner extends StatelessWidget {
  final String? savedAddress;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onDismiss;
  final Color? accentColor;

  const LocationMismatchBanner({
    super.key,
    this.savedAddress,
    this.onUpdateLocation,
    this.onDismiss,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = accentColor ?? context.features.walk;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: color.withValues(alpha: AppOpacity.o30)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 18, color: color),
          const SizedBox(width: AppSizes.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '저장된 위치와 현재 위치가 달라요',
                  style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600),
                ),
                if (savedAddress != null && savedAddress!.isNotEmpty)
                  Text(
                    savedAddress!,
                    style: AppTextStyles.captionSmall(context),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          // 위치 업데이트 버튼
          GestureDetector(
            onTap: onUpdateLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                '변경',
                style: AppTextStyles.labelMedium(context).withWeight(FontWeight.w600).withColor(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapSM),
          // 닫기 버튼
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 위치 인증 상태 표시 위젯 (인증 배지 카드용)
/// 
/// 인증 배지 카드에 오버레이로 표시되는 작은 말풍선
class LocationVerificationOverlay extends StatelessWidget {
  final Widget child;
  final bool showBubble;
  final String? savedAddress;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onDismiss;
  final Color? accentColor;

  const LocationVerificationOverlay({
    super.key,
    required this.child,
    this.showBubble = false,
    this.savedAddress,
    this.onUpdateLocation,
    this.onDismiss,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBubble) return child;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -70,
          left: 0,
          right: 0,
          child: Center(
            child: LocationBubbleWidget(
              savedAddress: savedAddress,
              onUpdateLocation: onUpdateLocation,
              onDismiss: onDismiss,
              position: BubblePosition.above,
              accentColor: accentColor,
            ),
          ),
        ),
      ],
    );
  }
}
