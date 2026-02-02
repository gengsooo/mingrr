import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../models/location_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// ============================================================
/// 위치 정보 표시 카드
/// 
/// 기능:
/// - 주소 정보 표시
/// - 미니맵 미리보기 (선택)
/// - 탭하여 지도 열기
/// ============================================================
class LocationDisplayCard extends StatelessWidget {
  /// 위치 데이터
  final LocationData? location;
  
  /// 테마 색상
  final Color? accentColor;
  
  /// 탭 콜백
  final VoidCallback? onTap;
  
  /// 미니맵 표시 여부
  final bool showMiniMap;
  
  /// 미니맵 높이
  final double miniMapHeight;
  
  /// 플레이스홀더 텍스트
  final String placeholder;
  
  /// 편집 가능 여부 (변경 버튼 표시)
  final bool editable;

  const LocationDisplayCard({
    super.key,
    this.location,
    this.accentColor,
    this.onTap,
    this.showMiniMap = false,
    this.miniMapHeight = 120,
    this.placeholder = '위치를 선택해주세요',
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null && location!.isValid;
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasLocation ? color.withValues(alpha: AppOpacity.o10) : context.inputBackground,
          border: Border.all(
            color: hasLocation ? color.withValues(alpha: AppOpacity.o30) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 아이콘
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasLocation 
                        ? color.withValues(alpha: AppOpacity.o15)
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Icon(
                    hasLocation ? AppIcons.location : AppIcons.locationOutlined,
                    size: 22,
                    color: hasLocation ? color : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                
                // 주소 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasLocation) ...[
                        Text(
                          location!.shortAddress ?? location!.displayAddress,
                          style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                        ),
                        if (location!.fullAddress != null) ...[
                          const SizedBox(height: AppSizes.gapXXS),
                          Text(
                            location!.fullAddress!,
                            style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ] else ...[
                        Text(
                          '위치 선택',
                          style: AppTextStyles.titleMedium(context),
                        ),
                        const SizedBox(height: AppSizes.gapXXS),
                        Text(
                          '탭하여 지도에서 선택',
                          style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 액션 버튼 (위치가 있을 때만 변경 버튼 표시)
                if (editable && hasLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Text(
                      '변경',
                      style: AppTextStyles.labelLarge(context).withColor(Colors.white),
                    ),
                  )
                else if (editable)
                  Icon(
                    AppIcons.chevronRight,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    size: 20,
                  ),
              ],
            ),
            
            // 미니맵 (선택적)
            if (showMiniMap && hasLocation) ...[
              const SizedBox(height: AppSizes.gapM),
              Container(
                height: miniMapHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: AppOpacity.o10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                ),
                child: Stack(
                  children: [
                    // 격자 패턴
                    CustomPaint(
                      size: Size.infinite,
                      painter: _MiniMapGridPainter(color),
                    ),
                    // 중앙 마커
                    Center(
                      child: Icon(
                        AppIcons.location,
                        size: 32,
                        color: color,
                      ),
                    ),
                    // 크게 보기 힌트
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: AppOpacity.o80),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.fullscreen, size: 14, color: accentColor),
                            const SizedBox(width: AppSizes.gapXS),
                            Text(
                              '지도 보기',
                              style: AppTextStyles.caption(context).withWeight(FontWeight.w500).withColor(color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMapGridPainter extends CustomPainter {
  final Color color;
  _MiniMapGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: AppOpacity.o15)
      ..strokeWidth = 1;

    const spacing = 25.0;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
