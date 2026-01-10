import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/map/map_widgets.dart';
import '../../../../core/widgets/map/map_loading_widget.dart';
import '../../../../core/models/location_model.dart';
import '../../../../models/health_model.dart';

/// ============================================================
/// 산책 기록 상세 화면
/// 지도에 이동경로 표시 + 시간/거리 등 상세정보
/// ============================================================

class WalkRecordDetailScreen extends StatefulWidget {
  final WalkRecordModel record;
  final List<String> petNames;

  const WalkRecordDetailScreen({
    super.key,
    required this.record,
    this.petNames = const [],
  });

  @override
  State<WalkRecordDetailScreen> createState() => _WalkRecordDetailScreenState();
}

class _WalkRecordDetailScreenState extends State<WalkRecordDetailScreen> {
  KakaoMapController? _mapController;
  bool _isMapReady = false;
  
  /// LatLng 생성 헬퍼
  LatLng _createLatLng(double lat, double lng) => LatLng(lat, lng);
  
  WalkRecordModel get record => widget.record;
  List<String> get petNames => widget.petNames;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 지도 영역 (앱바 포함)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.walk,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => _shareRecord(context),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showMoreOptions(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMapArea(context),
            ),
          ),
          
          // 상세 정보
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 요약 카드
                _buildSummaryCard(),
                
                // 상세 통계
                _buildDetailStats(),
                
                // 함께한 반려동물
                _buildPetInfo(),
                
                // 메모
                if (record.notes != null && record.notes!.isNotEmpty)
                  _buildMemoSection(),
                
                // 사진
                if (record.photoUrls.isNotEmpty)
                  _buildPhotosSection(),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 지도 영역 (경로 표시)
  Widget _buildMapArea(BuildContext context) {
    // 웹이거나 경로가 없으면 플레이스홀더 표시
    if (kIsWeb || record.routePoints.isEmpty) {
      return _buildMapPlaceholder(context);
    }
    
    // 모바일에서 카카오맵 표시
    return _buildKakaoMapWithRoute();
  }
  
  /// 카카오맵에 경로 표시
  Widget _buildKakaoMapWithRoute() {
    final firstPoint = record.routePoints.first;
    
    return Stack(
      children: [
        KakaoMap(
          key: const ValueKey('walk_record_map'),
          option: KakaoMapOption(
            position: _createLatLng(firstPoint.latitude, firstPoint.longitude),
            zoomLevel: 15,
            mapType: MapType.normal,
          ),
          onMapReady: _onMapReady,
        ),
        // 지도 로딩 중 오버레이
        if (!_isMapReady)
          MapLoadingWidget.walk(message: '경로를 불러오는 중...'),
      ],
    );
  }
  
  /// 카카오맵 생성 완료 콜백
  void _onMapReady(KakaoMapController controller) async {
    _mapController = controller;
    setState(() => _isMapReady = true);
    
    // 경로 폴리라인 그리기
    await _drawRouteOnMap();
  }
  
  /// 지도에 경로 표시
  Future<void> _drawRouteOnMap() async {
    if (_mapController == null || record.routePoints.length < 2) return;
    
    try {
      // 경로 포인트를 LatLng 리스트로 변환
      final points = record.routePoints
          .map((gp) => _createLatLng(gp.latitude, gp.longitude))
          .toList();
      
      // 경로 그리기
      await _mapController!.routeLayer.addRoute(
        points,
        RouteStyle(AppColors.walk, 8),
      );
      
      // 경로 전체가 보이도록 카메라 조정
      _fitBoundsToRoute();
    } catch (e) {
      debugPrint('경로 그리기 실패: $e');
    }
  }
  
  /// 경로 범위에 맞게 카메라 조정
  void _fitBoundsToRoute() {
    if (record.routePoints.isEmpty) return;
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final point in record.routePoints) {
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
  
  /// 지도 플레이스홀더 (웹용 또는 경로 없을 때)
  Widget _buildMapPlaceholder(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: AppColors.walk.withOpacity(0.2),
          child: record.routePoints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 60, color: AppColors.walk.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text(
                        '경로 정보가 없습니다',
                        style: TextStyle(fontSize: 14, color: AppColors.walk.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
              : CustomPaint(
                  size: Size.infinite,
                  painter: _RoutePreviewPainter(record.routePoints, AppColors.walk),
                ),
        ),
        
        // 시작/종료 마커 (경로가 있을 때만)
        if (record.routePoints.isNotEmpty) ...[
          _buildRouteMarkers(context),
        ],
      ],
    );
  }
  
  /// 경로 마커 (시작/종료)
  Widget _buildRouteMarkers(BuildContext context) {
    return Stack(
      children: [
        // 시작점
        Positioned(
          left: 20,
          bottom: 80,
          child: _buildMarker('출발', AppColors.success),
        ),
        // 종료점
        if (record.routePoints.length > 1)
          Positioned(
            right: 20,
            bottom: 80,
            child: _buildMarker('도착', AppColors.error),
          ),
      ],
    );
  }

  Widget _buildMarker(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(Icons.location_on, color: color, size: 24),
      ],
    );
  }

  /// 요약 카드
  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 날짜/시간
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.walk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, color: AppColors.walk, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(record.startTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      record.endTime != null
                          ? '${_formatTime(record.startTime)} ~ ${_formatTime(record.endTime!)}'
                          : '${_formatTime(record.startTime)} (진행 중)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          
          // 주요 통계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.timer_outlined,
                value: record.durationString,
                label: '시간',
                color: AppColors.walk,
              ),
              _buildStatItem(
                icon: Icons.straighten,
                value: record.distanceString,
                label: '거리',
                color: AppColors.primary,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department_outlined,
                value: '${record.calories?.toInt() ?? 0}',
                label: 'kcal',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 상세 통계
  Widget _buildDetailStats() {
    return MingrrCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상세 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('경로 포인트', '${record.routePoints.length}개'),
          _buildDetailRow('발자국', '${record.footprints.length}개'),
          if (record.durationMinutes > 0)
            _buildDetailRow(
              '평균 속도',
              '${((record.distance / 1000) / (record.durationMinutes / 60)).toStringAsFixed(1)} km/h',
            ),
          _buildDetailRow('시작 시간', _formatTime(record.startTime)),
          if (record.endTime != null)
            _buildDetailRow('종료 시간', _formatTime(record.endTime!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 함께한 반려동물
  Widget _buildPetInfo() {
    return MingrrCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '함께한 반려동물',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (petNames.isNotEmpty ? petNames : ['반려동물']).map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.walk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.walk.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DefaultPetIcon(size: 16),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.walk,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 메모 섹션
  Widget _buildMemoSection() {
    return MingrrCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_outlined, size: 20, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                '메모',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.notes!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 사진 섹션
  Widget _buildPhotosSection() {
    return MingrrCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '사진',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${record.photoUrls.length}장',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: record.photoUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: AppColors.textHint,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _shareRecord(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능은 준비 중입니다')),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수정 기능은 준비 중입니다')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('삭제', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.walkRecordDelete,
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
    return '${meters.toInt()}m';
  }
}


/// 경로 미리보기 페인터 (웹용)
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
    const padding = 40.0;
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
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 그림자
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path.shift(const Offset(2, 2)), shadowPaint);

    // 경로
    canvas.drawPath(path, paint);

    // 시작점 마커
    final startPaint = Paint()..color = AppColors.success;
    canvas.drawCircle(points.first, 8, startPaint);
    canvas.drawCircle(points.first, 4, Paint()..color = Colors.white);

    // 끝점 마커
    final endPaint = Paint()..color = AppColors.error;
    canvas.drawCircle(points.last, 8, endPaint);
    canvas.drawCircle(points.last, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
