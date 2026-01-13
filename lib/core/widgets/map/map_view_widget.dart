import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/location_model.dart';
import 'map_loading_widget.dart';

/// ============================================================
/// 지도 뷰 위젯 (읽기 전용)
/// 
/// 기능:
/// - 특정 위치 표시
/// - 경로 폴리라인 표시
/// - 마커 표시
/// - 산책 기록 상세, 마켓 상세 등에서 사용
/// ============================================================
class MapViewWidget extends StatefulWidget {
  /// 중심 위치
  final LocationData? centerLocation;
  
  /// 경로 포인트 (폴리라인 표시용)
  final List<GeoPoint>? routePoints;
  
  /// 마커 포인트 (발바닥 등)
  final List<GeoPoint>? markerPoints;
  
  /// 지도 높이
  final double height;
  
  /// 테마 색상
  final Color? accentColor;
  
  /// 줌 레벨
  final int zoomLevel;
  
  /// 경로 색상
  final Color? routeColor;
  
  /// 경로 두께
  final double routeWidth;
  
  /// 마커 아이콘 (기본: 발바닥)
  final IconData markerIcon;
  
  /// 마커 색상
  final Color? markerColor;
  
  /// 탭 콜백
  final VoidCallback? onTap;

  const MapViewWidget({
    super.key,
    this.centerLocation,
    this.routePoints,
    this.markerPoints,
    this.height = 200,
    this.accentColor,
    this.zoomLevel = 15,
    this.routeColor,
    this.routeWidth = 4,
    this.markerIcon = Icons.pets,
    this.markerColor,
    this.onTap,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  KakaoMapController? _mapController;
  bool _isMapReady = false;
  
  Color get accentColor => widget.accentColor ?? Theme.of(context).colorScheme.primary;
  
  /// LatLng 생성 헬퍼
  LatLng _createLatLng(double lat, double lng) => LatLng(lat, lng);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.centerLocation == null && 
        (widget.routePoints == null || widget.routePoints!.isEmpty)) {
      return _buildPlaceholder('위치 정보가 없습니다');
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (kIsWeb)
              _buildWebPlaceholder()
            else
              _buildKakaoMap(),
            
            if (widget.onTap != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, size: 16, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '크게 보기',
                        style: TextStyle(
                          fontSize: 12,
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
    );
  }

  Widget _buildKakaoMap() {
    final center = _getMapCenter();
    
    return Stack(
      children: [
        KakaoMap(
          key: ValueKey('map_view_${center.latitude}_${center.longitude}'),
          option: KakaoMapOption(
            position: _createLatLng(center.latitude, center.longitude),
            zoomLevel: widget.zoomLevel,
            mapType: MapType.normal,
          ),
          onMapReady: _onMapReady,
        ),
        // 지도 로딩 중 오버레이
        if (!_isMapReady)
          MapLoadingWidget(
            accentColor: accentColor,
            message: '지도를 불러오는 중...',
            height: widget.height,
          ),
      ],
    );
  }

  void _onMapReady(KakaoMapController controller) async {
    _mapController = controller;
    setState(() => _isMapReady = true);
    
    await _drawRouteAndMarkers();
  }

  Future<void> _drawRouteAndMarkers() async {
    if (_mapController == null || !_isMapReady) return;

    // 경로 범위에 맞게 카메라 조정
    // 참고: kakao_maps_flutter SDK에서 폴리라인 지원이 제한적이므로
    // 현재는 카메라 이동으로 대체합니다.
    if (widget.routePoints != null && widget.routePoints!.length >= 2) {
      _fitBoundsToRoute();
    }
  }

  void _fitBoundsToRoute() {
    if (widget.routePoints == null || widget.routePoints!.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in widget.routePoints!) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final cameraUpdate = CameraUpdate.newCenterPosition(
      _createLatLng(centerLat, centerLng),
    );
    _mapController?.moveCamera(cameraUpdate);
  }

  LocationData _getMapCenter() {
    if (widget.centerLocation != null) {
      return widget.centerLocation!;
    }
    
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      final first = widget.routePoints!.first;
      return LocationData.fromCoordinates(first.latitude, first.longitude);
    }
    
    return LocationData.defaultLocation;
  }

  Widget _buildWebPlaceholder() {
    return _buildPlaceholder('지도 미리보기');
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(accentColor),
          ),
          
          // 경로 미리보기 (웹용)
          if (widget.routePoints != null && widget.routePoints!.length >= 2)
            CustomPaint(
              size: Size.infinite,
              painter: _RoutePreviewPainter(
                widget.routePoints!,
                widget.routeColor ?? accentColor,
              ),
            ),
          
          // 마커 미리보기 (웹용)
          if (widget.markerPoints != null)
            ...widget.markerPoints!.asMap().entries.map((entry) {
              return _buildMarkerPreview(entry.key, entry.value);
            }),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: accentColor.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: accentColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerPreview(int index, GeoPoint point) {
    if (widget.routePoints == null || widget.routePoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 경로 범위 계산
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final p in widget.routePoints!) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    if (latRange == 0 || lngRange == 0) return const SizedBox.shrink();

    // 정규화된 위치 계산
    final normalizedX = (point.longitude - minLng) / lngRange;
    final normalizedY = 1 - (point.latitude - minLat) / latRange;

    return Positioned(
      left: normalizedX * (widget.height * 1.5) + 20,
      top: normalizedY * (widget.height - 40) + 20,
      child: Icon(
        widget.markerIcon,
        size: 16,
        color: widget.markerColor ?? accentColor,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 30.0;

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

class _RoutePreviewPainter extends CustomPainter {
  final List<GeoPoint> routePoints;
  final Color color;

  _RoutePreviewPainter(this.routePoints, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2) return;

    // 경로 범위 계산
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    if (latRange == 0 && lngRange == 0) return;

    // 패딩
    const padding = 30.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    // 정규화된 포인트 계산
    final points = routePoints.map((point) {
      final x = lngRange > 0
          ? padding + (point.longitude - minLng) / lngRange * drawWidth
          : size.width / 2;
      final y = latRange > 0
          ? padding + (1 - (point.latitude - minLat) / latRange) * drawHeight
          : size.height / 2;
      return Offset(x, y);
    }).toList();

    // 경로 그리기
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // 시작점 마커
    final startPaint = Paint()..color = Colors.green;
    canvas.drawCircle(points.first, 6, startPaint);

    // 끝점 마커
    final endPaint = Paint()..color = Colors.red;
    canvas.drawCircle(points.last, 6, endPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
