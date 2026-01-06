import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/confirm_bottom_sheet.dart';

/// ============================================================
/// 산책 기록 상세 화면
/// 지도에 이동경로 표시 + 시간/거리 등 상세정보
/// ============================================================

class WalkRecordDetailScreen extends StatelessWidget {
  final WalkRecord record;

  const WalkRecordDetailScreen({
    super.key,
    required this.record,
  });

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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              background: _buildMapArea(),
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
                if (record.memo != null && record.memo!.isNotEmpty)
                  _buildMemoSection(),
                
                // 사진
                if (record.photos.isNotEmpty)
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
  Widget _buildMapArea() {
    return Stack(
      children: [
        // 지도 플레이스홀더 (실제 기기에서는 카카오 지도로 대체)
        Container(
          color: AppColors.walk.withOpacity(0.3),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 60,
                  color: AppColors.walk.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '산책 경로',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.walk.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '실제 기기에서 지도가 표시됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.walk.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 경로 시뮬레이션 (데모용)
        CustomPaint(
          size: const Size(double.infinity, 300),
          painter: _RoutePathPainter(record.routePoints),
        ),
        
        // 시작/종료 마커
        Positioned(
          left: 50,
          top: 100,
          child: _buildMarker('출발', AppColors.success),
        ),
        Positioned(
          right: 50,
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
                      _formatDate(record.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_formatTime(record.startTime)} ~ ${_formatTime(record.endTime)}',
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
                value: _formatDuration(record.duration),
                label: '시간',
                color: AppColors.walk,
              ),
              _buildStatItem(
                icon: Icons.straighten,
                value: _formatDistance(record.distance),
                label: '거리',
                color: AppColors.primary,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department_outlined,
                value: '${record.calories}',
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
          _buildDetailRow('평균 속도', '${record.avgSpeed.toStringAsFixed(1)} km/h'),
          _buildDetailRow('최고 속도', '${record.maxSpeed.toStringAsFixed(1)} km/h'),
          _buildDetailRow('걸음 수', '${record.steps} 걸음'),
          _buildDetailRow('휴식 시간', _formatDuration(record.restTime)),
          _buildDetailRow('날씨', record.weather),
          _buildDetailRow('기온', '${record.temperature}°C'),
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
            children: record.petNames.map((name) {
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
                    const Text('🐶', style: TextStyle(fontSize: 16)),
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
            record.memo!,
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
                '${record.photos.length}장',
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
              itemCount: record.photos.length,
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
    showConfirmBottomSheet(
      context,
      type: ConfirmType.walkRecordDelete,
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

/// 산책 기록 데이터 모델
class WalkRecord {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // 분
  final double distance; // 미터
  final int calories;
  final double avgSpeed;
  final double maxSpeed;
  final int steps;
  final int restTime; // 분
  final String weather;
  final int temperature;
  final List<String> petNames;
  final String? memo;
  final List<String> photos;
  final List<Offset> routePoints;

  const WalkRecord({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.calories,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.steps,
    required this.restTime,
    required this.weather,
    required this.temperature,
    required this.petNames,
    this.memo,
    this.photos = const [],
    this.routePoints = const [],
  });

  /// 데모용 산책 기록 생성
  factory WalkRecord.demo({int index = 0}) {
    final now = DateTime.now().subtract(Duration(days: index));
    final startTime = DateTime(now.year, now.month, now.day, 14 - index % 8, 0);
    final duration = 30 + index * 5;
    
    return WalkRecord(
      id: 'walk_$index',
      date: now,
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: duration)),
      duration: duration,
      distance: 1200 + index * 300,
      calories: 80 + index * 15,
      avgSpeed: 3.5 + index * 0.2,
      maxSpeed: 5.0 + index * 0.3,
      steps: 2500 + index * 500,
      restTime: 5 + index,
      weather: ['맑음', '흐림', '구름 조금'][index % 3],
      temperature: 15 + index % 10,
      petNames: index % 2 == 0 ? ['뽀삐'] : ['뽀삐', '코코'],
      memo: index % 3 == 0 ? '오늘 산책은 정말 좋았어요! 뽀삐가 신나게 뛰어다녔습니다.' : null,
      photos: List.generate(index % 4, (i) => 'photo_$i'),
      routePoints: _generateDemoRoute(),
    );
  }

  static List<Offset> _generateDemoRoute() {
    return [
      const Offset(0.2, 0.3),
      const Offset(0.3, 0.4),
      const Offset(0.4, 0.35),
      const Offset(0.5, 0.5),
      const Offset(0.6, 0.45),
      const Offset(0.7, 0.6),
      const Offset(0.8, 0.7),
    ];
  }
}

/// 경로 그리기 페인터
class _RoutePathPainter extends CustomPainter {
  final List<Offset> points;

  _RoutePathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = AppColors.walk
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final scaledPoints = points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
    
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
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

    // 점선 효과를 위한 점들
    final dotPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final point in scaledPoints) {
      canvas.drawCircle(point, 4, Paint()..color = AppColors.walk);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
