import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../theme/feature_colors.dart';

/// ============================================================
/// 플랫폼별 지도 위젯
/// 
/// - 웹: 플레이스홀더 (카카오맵 JS SDK 또는 Google Maps 사용 가능)
/// - 모바일: 카카오맵 Flutter SDK
/// 
/// 사용 방법:
/// 1. 모바일에서 카카오맵 사용 시:
///    - pubspec.yaml에서 kakao_maps_flutter 주석 해제
///    - main.dart에서 KakaoMapsFlutter.init() 호출
///    - 이 파일의 _MobileMapWidget에서 카카오맵 코드 주석 해제
/// ============================================================

class PlatformMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double zoom;
  final bool showCurrentLocation;
  final Function(double lat, double lng)? onMapTap;
  final Function(dynamic controller)? onMapCreated;
  final List<MapMarker> markers;
  final List<MapPolyline> polylines;

  const PlatformMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.zoom = 15.0,
    this.showCurrentLocation = true,
    this.onMapTap,
    this.onMapCreated,
    this.markers = const [],
    this.polylines = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebMapWidget(
        latitude: latitude,
        longitude: longitude,
        zoom: zoom,
        markers: markers,
      );
    } else {
      return _MobileMapWidget(
        latitude: latitude,
        longitude: longitude,
        zoom: zoom,
        showCurrentLocation: showCurrentLocation,
        onMapTap: onMapTap,
        onMapCreated: onMapCreated,
        markers: markers,
        polylines: polylines,
      );
    }
  }
}

/// 웹용 지도 위젯 (단순 플레이스홀더)
class _WebMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double zoom;
  final List<MapMarker> markers;

  const _WebMapWidget({
    this.latitude,
    this.longitude,
    this.zoom = 15.0,
    this.markers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o50),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.mapOutlined,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              '지도 영역',
              style: AppTextStyles.titleMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.gapXS),
            Text(
              '모바일 앱에서 확인 가능',
              style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.outlineVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 모바일용 지도 위젯 (카카오맵)
class _MobileMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final double zoom;
  final bool showCurrentLocation;
  final Function(double lat, double lng)? onMapTap;
  final Function(dynamic controller)? onMapCreated;
  final List<MapMarker> markers;
  final List<MapPolyline> polylines;

  const _MobileMapWidget({
    this.latitude,
    this.longitude,
    this.zoom = 15.0,
    this.showCurrentLocation = true,
    this.onMapTap,
    this.onMapCreated,
    this.markers = const [],
    this.polylines = const [],
  });

  @override
  State<_MobileMapWidget> createState() => _MobileMapWidgetState();
}

class _MobileMapWidgetState extends State<_MobileMapWidget> {
  // 카카오맵 사용 시 아래 코드 주석 해제
  // KakaoMapController? _controller;
  
  @override
  Widget build(BuildContext context) {
    // ============================================================
    // 카카오맵 사용 시 아래 코드로 교체
    // ============================================================
    // return KakaoMap(
    //   onMapCreated: (controller) {
    //     _controller = controller;
    //     widget.onMapCreated?.call(controller);
    //   },
    //   center: LatLng(
    //     widget.latitude ?? 37.5665,
    //     widget.longitude ?? 126.9780,
    //   ),
    //   currentLevel: widget.zoom.toInt(),
    //   onMapTap: (latLng) {
    //     widget.onMapTap?.call(latLng.latitude, latLng.longitude);
    //   },
    //   markers: widget.markers.map((m) => Marker(
    //     markerId: m.id,
    //     latLng: LatLng(m.latitude, m.longitude),
    //   )).toList(),
    //   polylines: widget.polylines.map((p) => Polyline(
    //     polylineId: p.id,
    //     points: p.points.map((pt) => LatLng(pt.latitude, pt.longitude)).toList(),
    //     strokeColor: p.color,
    //     strokeWidth: p.width.toInt(),
    //   )).toList(),
    // );
    
    // 플레이스홀더 (카카오맵 SDK 설정 전)
    return _buildPlaceholder();
  }
  
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Stack(
        children: [
          // 배경 그리드
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),
          
          // 중앙 안내
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.mapOutlined,
                    size: 48,
                    color: context.features.walk.withValues(alpha: AppOpacity.o70),
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Text(
                    '카카오맵',
                    style: AppTextStyles.headlineSmall(context).withWeight(FontWeight.w600),
                  ),
                  const SizedBox(height: AppSizes.gapXS),
                  Text(
                    '카카오맵 SDK 설정 후\n지도가 표시됩니다',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  if (widget.latitude != null && widget.longitude != null) ...[
                    const SizedBox(height: AppSizes.gapS),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                      decoration: BoxDecoration(
                        color: context.features.walk.withValues(alpha: AppOpacity.o10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: Text(
                        '${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
                        style: AppTextStyles.caption(context).withColor(context.features.walk),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // 현재 위치 버튼
          if (widget.showCurrentLocation)
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'currentLocation',
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: () {
                  // 현재 위치로 이동
                },
                child: Icon(AppIcons.myLocation, color: context.features.walk),
              ),
            ),
        ],
      ),
    );
  }
}

/// 지도 그리드 페인터
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: AppOpacity.o20)
      ..strokeWidth = 1;
    
    const spacing = 30.0;
    
    // 수직선
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // 수평선
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 지도 마커 모델
class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String? title;
  final String? snippet;
  final Color? color;

  const MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.title,
    this.snippet,
    this.color,
  });
}

/// 지도 폴리라인 모델
class MapPolyline {
  final String id;
  final List<MapPoint> points;
  final Color color;
  final double width;

  const MapPolyline({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.width = 4.0,
  });
}

/// 지도 포인트 모델
class MapPoint {
  final double latitude;
  final double longitude;

  const MapPoint({
    required this.latitude,
    required this.longitude,
  });
}
