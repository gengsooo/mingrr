import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/location_model.dart';

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
  final Color accentColor;
  
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
    this.accentColor = AppColors.primary,
    this.onTap,
    this.showMiniMap = false,
    this.miniMapHeight = 120,
    this.placeholder = '위치를 선택해주세요',
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null && location!.isValid;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasLocation ? accentColor.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: hasLocation ? accentColor.withOpacity(0.3) : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(12),
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
                        ? accentColor.withOpacity(0.15)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasLocation ? Icons.location_on : Icons.location_on_outlined,
                    size: 22,
                    color: hasLocation ? accentColor : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 12),
                
                // 주소 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocation 
                            ? (location!.shortAddress ?? location!.displayAddress)
                            : placeholder,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasLocation ? FontWeight.w600 : FontWeight.w400,
                          color: hasLocation ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      if (hasLocation && location!.fullAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          location!.fullAddress!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 액션 버튼
                if (editable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasLocation ? accentColor : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      hasLocation ? '변경' : '선택',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: hasLocation ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            
            // 미니맵 (선택적)
            if (showMiniMap && hasLocation) ...[
              const SizedBox(height: 12),
              Container(
                height: miniMapHeight,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // 격자 패턴
                    CustomPaint(
                      size: Size.infinite,
                      painter: _MiniMapGridPainter(accentColor),
                    ),
                    // 중앙 마커
                    Center(
                      child: Icon(
                        Icons.location_on,
                        size: 32,
                        color: accentColor,
                      ),
                    ),
                    // 크게 보기 힌트
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              '지도 보기',
                              style: TextStyle(
                                fontSize: 11,
                                color: accentColor,
                                fontWeight: FontWeight.w500,
                              ),
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
      ..color = color.withOpacity(0.15)
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
