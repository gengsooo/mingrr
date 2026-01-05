import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: 실제 기기 테스트 시 주석 해제
// import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

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
  
  // TODO: 실제 기기 테스트 시 주석 해제
  // 카카오 맵 컨트롤러
  // KakaoMapController? _mapController;
  // LatLng? _currentPosition;
  // bool _isMapReady = false;
  
  // 임시 위치 (에뮬레이터용)
  Position? _currentPosition;
  
  // 선택된 반려동물 ID 목록 (중복 선택 가능)
  final Set<String> _selectedPetIds = {};
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentPosition = null);
        return;
      }
      
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentPosition = null);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentPosition = null);
        return;
      }
      
      // 현재 위치 가져오기 (타임아웃 5초)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
      setState(() => _currentPosition = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ===== 상단 영역 (SafeArea + 반려동물 선택) =====
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 상단 바
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  child: Row(
                    children: [
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
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 반려동물 선택 패널 (산책 중이 아닐 때만)
                if (!_isWalking) _buildPetSelectionPanel(),
                
                // 산책 중 정보 패널
                if (_isWalking) _buildWalkingInfoPanel(),
              ],
            ),
          ),
          
          // ===== 지도 영역 =====
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXL),
              ),
              child: _buildKakaoMap(),
            ),
          ),
          
          // ===== 하단 컨트롤 =====
          _buildBottomControlsSimple(),
        ],
      ),
    );
  }

  /// 지도 위젯 (플랫폼별 분기)
  Widget _buildKakaoMap() {
    // 웹에서는 단순 플레이스홀더 표시
    if (kIsWeb) {
      return _buildWebMapPlaceholder();
    }
    
    // 모바일에서는 카카오맵 (설정 전에는 플레이스홀더)
    return _buildMobileMapPlaceholder();
  }
  
  /// 웹용 지도 플레이스홀더
  Widget _buildWebMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(0.3),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            const Text(
              '지도 영역',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '모바일 앱에서 확인 가능',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 모바일용 지도 플레이스홀더 (카카오맵 SDK 설정 전)
  Widget _buildMobileMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.walk.withOpacity(0.1),
            AppColors.walk.withOpacity(0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 격자 패턴 (지도 느낌)
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),
          // 중앙 마커
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.walk.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 40,
                    color: AppColors.walk,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: Text(
                    _currentPosition != null
                        ? '위치: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                        : '위치를 가져오는 중...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '카카오맵 SDK 설정 후 지도가 표시됩니다',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 반려동물 선택 패널
  Widget _buildPetSelectionPanel() {
    final petsAsync = ref.watch(userPetsProvider);
    
    return petsAsync.when(
      data: (pets) {
        if (pets.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // 첫 로드 시 모든 반려동물 선택
        if (_selectedPetIds.isEmpty && pets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedPetIds.addAll(pets.map((p) => p.id));
            });
          });
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
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
                      '함께 산책할 반려동물',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedPetIds.length}마리 선택',
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
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      final isSelected = _selectedPetIds.contains(pet.id);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPetIds.remove(pet.id);
                            } else {
                              _selectedPetIds.add(pet.id);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: AppSizes.gapM),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.walk : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: MingrrAvatar(
                                      size: 50,
                                      imageUrl: pet.profileImageUrl,
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: AppColors.walk,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pet.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.walk : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 산책 중 정보 패널
  Widget _buildWalkingInfoPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
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

  /// 하단 컨트롤 (Column용)
  Widget _buildBottomControlsSimple() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    _showWalkSummary();
                  }
                });
              },
            ),
          ],
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

/// 지도 격자 패턴 페인터 (플레이스홀더용)
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.walk.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 40.0;
    
    // 가로선
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // 세로선
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
