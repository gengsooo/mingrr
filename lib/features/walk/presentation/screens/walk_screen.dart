import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 산책 화면
/// 위치 기반 산책 기능 - 발자국 남기기, 근처 친구 알림
/// 포켓몬GO 스타일의 지도 기반 인터랙션
/// ============================================================
class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  bool _isWalking = false;
  int _walkDuration = 0; // 초 단위
  double _walkDistance = 0; // 미터 단위

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ===== 지도 영역 (플레이스홀더) =====
          _buildMapPlaceholder(),
          
          // ===== 상단 정보 바 =====
          _buildTopBar(),
          
          // ===== 근처 산책 중인 친구들 =====
          if (!_isWalking) _buildNearbyWalkersPanel(),
          
          // ===== 산책 중 정보 패널 =====
          if (_isWalking) _buildWalkingInfoPanel(),
          
          // ===== 하단 컨트롤 =====
          _buildBottomControls(),
        ],
      ),
    );
  }

  /// 지도 플레이스홀더 (실제 구현 시 GoogleMap 위젯으로 교체)
  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.walk.withOpacity(0.1),
            AppColors.primaryLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // 그리드 패턴 (지도 느낌)
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),
          
          // 중앙 마커 (현재 위치)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.walk,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.walk.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    '현재 위치',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 데모용 다른 반려동물 마커들
          ..._buildDemoMarkers(),
        ],
      ),
    );
  }

  /// 데모용 마커들
  List<Widget> _buildDemoMarkers() {
    final markers = [
      {'top': 150.0, 'left': 80.0, 'name': '뽀삐'},
      {'top': 200.0, 'right': 60.0, 'name': '초코'},
      {'bottom': 250.0, 'left': 120.0, 'name': '콩이'},
      {'bottom': 300.0, 'right': 100.0, 'name': '몽이'},
    ];

    return markers.map((marker) {
      return Positioned(
        top: marker['top'] as double?,
        left: marker['left'] as double?,
        right: marker['right'] as double?,
        bottom: marker['bottom'] as double?,
        child: _buildPetMarker(marker['name'] as String),
      );
    }).toList();
  }

  /// 반려동물 마커
  Widget _buildPetMarker(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.pets,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 상단 정보 바
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              // 뒤로가기 / 메뉴
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              const Spacer(),
              
              // 산책 기록 버튼
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('산책 기록'),
                  onPressed: () {
                    // TODO: 산책 기록 화면으로 이동
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 근처 산책 중인 친구들 패널
  Widget _buildNearbyWalkersPanel() {
    return Positioned(
      top: 100,
      left: AppSizes.paddingM,
      right: AppSizes.paddingM,
      child: MingrrCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.walk,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.gapS),
                const Text(
                  '근처에서 산책 중인 친구들',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '4마리',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.walk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.gapM),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: AppSizes.gapM),
                    child: Column(
                      children: [
                        const MingrrAvatar(
                          size: 45,
                          isOnline: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['뽀삐', '초코', '콩이', '몽이'][index],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 산책 중 정보 패널
  Widget _buildWalkingInfoPanel() {
    return Positioned(
      top: 100,
      left: AppSizes.paddingM,
      right: AppSizes.paddingM,
      child: MingrrCard(
        margin: EdgeInsets.zero,
        backgroundColor: AppColors.walk,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWalkStat(
                  icon: Icons.timer,
                  value: _formatDuration(_walkDuration),
                  label: '시간',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white30,
                ),
                _buildWalkStat(
                  icon: Icons.straighten,
                  value: _formatDistance(_walkDistance),
                  label: '거리',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white30,
                ),
                _buildWalkStat(
                  icon: Icons.local_fire_department,
                  value: '${(_walkDistance * 0.05).toInt()}',
                  label: 'kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 산책 통계 아이템
  Widget _buildWalkStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 하단 컨트롤
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXL),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 발자국 남기기 버튼
              if (_isWalking)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.gapM),
                  child: MingrrButton(
                    text: '🐾 발자국 남기기',
                    isOutlined: true,
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      // TODO: 발자국 남기기
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('발자국을 남겼습니다! 🐾'),
                          backgroundColor: AppColors.walk,
                        ),
                      );
                    },
                  ),
                ),
              
              // 산책 시작/종료 버튼
              MingrrButton(
                text: _isWalking ? '산책 종료' : '산책 시작',
                backgroundColor: _isWalking ? AppColors.error : AppColors.walk,
                textColor: Colors.white,
                icon: _isWalking ? Icons.stop : Icons.play_arrow,
                onPressed: () {
                  setState(() {
                    _isWalking = !_isWalking;
                    if (!_isWalking) {
                      // 산책 종료 시 기록 저장
                      _showWalkSummary();
                    }
                  });
                },
              ),
              
              if (!_isWalking) ...[
                const SizedBox(height: AppSizes.gapM),
                Text(
                  '산책을 시작하면 근처 친구들에게 알림이 갑니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 산책 종료 요약 다이얼로그
  void _showWalkSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.walk),
            SizedBox(width: 8),
            Text('산책 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow('시간', _formatDuration(_walkDuration)),
            _buildSummaryRow('거리', _formatDistance(_walkDistance)),
            _buildSummaryRow('칼로리', '${(_walkDistance * 0.05).toInt()} kcal'),
            const SizedBox(height: AppSizes.gapM),
            const Text(
              '오늘도 건강한 산책 완료! 🎉',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    
    // 초기화
    _walkDuration = 0;
    _walkDistance = 0;
  }

  /// 요약 행
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 시간 포맷팅
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 거리 포맷팅
  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.toInt()}m';
  }
}

/// 그리드 패턴 페인터 (지도 느낌)
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withOpacity(0.3)
      ..strokeWidth = 1;

    const spacing = 50.0;

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
