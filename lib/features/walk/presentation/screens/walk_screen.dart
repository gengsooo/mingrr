import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/map/map_loading_widget.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_helper.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../health/presentation/providers/health_provider.dart';

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
  
  // 카카오 맵 컨트롤러
  KakaoMapController? _mapController;
  LatLng? _currentMapPosition;
  bool _isMapReady = false;
  bool _isLocationLoading = true; // 위치 로딩 상태
  LatLng? _initialMapPosition; // 초기 지도 위치 (한 번만 설정)
  
  /// LatLng 생성 헬퍼
  LatLng _createLatLng(double lat, double lng) => LatLng(lat, lng);
  
  // 위치 추적
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _walkTimer;
  
  // 산책 기록
  String? _currentWalkRecordId;
  final List<GeoPoint> _routePoints = [];
  final List<GeoPoint> _footprints = [];
  Position? _lastPosition;
  
  // 선택된 반려동물 ID 목록 (중복 선택 가능)
  final Set<String> _selectedPetIds = {};
  
  // 위치 로딩 진행 상태
  LocationProgress? _locationProgress;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _walkTimer?.cancel();
    super.dispose();
  }
  
  /// 현재 위치 가져오기 (LocationHelper 사용 - 3단계 전략)
  Future<void> _getCurrentLocation() async {
    debugPrint('\n📍 [WalkScreen] === 위치 가져오기 시작 ===');
    debugPrint('📍 [WalkScreen] mounted: $mounted');
    
    setState(() {
      _isLocationLoading = true;
      _locationProgress = null;
    });
    
    final result = await LocationHelper.getCurrentLocation(
      purpose: LocationPurpose.map,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _locationProgress = progress);
        }
      },
    );
    
    debugPrint('📍 [WalkScreen] 위치 결과: isSuccess=${result.isSuccess}, source=${result.source}, errorType=${result.errorType}');
    if (result.position != null) {
      debugPrint('📍 [WalkScreen] 위치: ${result.position!.latitude}, ${result.position!.longitude}');
    }
    
    if (!mounted) {
      debugPrint('📍 [WalkScreen] ⚠️ mounted=false, 상태 업데이트 스킵');
      return;
    }
    
    if (result.isSuccess && result.position != null) {
      debugPrint('📍 [WalkScreen] ✅ 위치 가져오기 성공 (source: ${result.source})');
      setState(() {
        _currentPosition = result.position;
        _isLocationLoading = false;
        _locationProgress = null;
      });
      
      // 백그라운드에서 high 정확도 위치 업데이트
      _updateHighAccuracyPosition();
    } else {
      debugPrint('📍 [WalkScreen] ❌ 위치 가져오기 실패 - 오류 팝업 표시');
      setState(() {
        _isLocationLoading = false;
        _locationProgress = null;
      });
      _showLocationErrorDialog();
    }
  }
  
  /// 백그라운드에서 high 정확도 위치 업데이트
  Future<void> _updateHighAccuracyPosition() async {
    if (!mounted || _currentPosition == null) return;
    
    final highPosition = await LocationHelper.getHighAccuracyPosition();
    if (highPosition == null || !mounted) return;
    
    // 50m 이상 차이나면 지도 업데이트
    if (LocationHelper.shouldUpdatePosition(_currentPosition!, highPosition)) {
      debugPrint('📍 [WalkScreen] 🔄 high 정확도 위치로 업데이트 (50m+ 차이)');
      
      setState(() => _currentPosition = highPosition);
      
      // 지도 카메라 부드럽게 이동
      if (_mapController != null && _isMapReady) {
        final cameraUpdate = CameraUpdate.newCenterPosition(
          _createLatLng(highPosition.latitude, highPosition.longitude),
        );
        await _mapController!.moveCamera(
          cameraUpdate,
          animation: const CameraAnimation(500),
        );
      }
    } else {
      debugPrint('📍 [WalkScreen] high 정확도 위치 차이 50m 미만 - 업데이트 스킵');
    }
  }
  
  /// 위치 오류 다이얼로그 표시
  Future<void> _showLocationErrorDialog() async {
    if (!mounted) return;
    
    final dialogResult = await showErrorDialog(
      context,
      type: ErrorType.location,
      themeColor: AppColors.walk,
    );
    
    if (dialogResult == ErrorResult.retry) {
      // 재시도 - 상태 초기화 후 다시 시도
      _resetLocationState();
      _getCurrentLocation();
    } else {
      // 취소 - 이전 화면으로 돌아가기
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
  
  /// 위치 관련 상태 초기화 (재시도 시 깨끗한 상태에서 시작)
  void _resetLocationState() {
    debugPrint('📍 [WalkScreen] 🔄 위치 상태 초기화');
    setState(() {
      _currentPosition = null;
      _initialMapPosition = null;
      _isMapReady = false;
      _locationProgress = null;
    });
    _mapController = null;
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
                      const MingrrBackButton(),
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
                          icon: const Icon(Icons.history, size: 18, color: AppColors.walk),
                          label: const Text('산책 기록', style: TextStyle(color: AppColors.walk)),
                          onPressed: () => _showWalkHistory(context),
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
              child: Stack(
                children: [
                  _buildKakaoMap(),
                  // 현재 위치 핀 (중앙)
                  if (_currentPosition != null && !_isWalking)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.walk.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets,
                              size: 32,
                              color: AppColors.walk,
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.walk,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.walk.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // 현재 위치 버튼
                  Positioned(
                    right: AppSizes.paddingM,
                    bottom: AppSizes.paddingL,
                    child: FloatingActionButton.small(
                      heroTag: 'walkMyLocation',
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: _goToMyLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.walk,
                      ),
                    ),
                  ),
                ],
              ),
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
    debugPrint('📍 [WalkScreen] _buildKakaoMap: kIsWeb=$kIsWeb, _isLocationLoading=$_isLocationLoading, _currentPosition=${_currentPosition != null}');
    
    // 웹에서는 단순 플레이스홀더 표시
    if (kIsWeb) {
      debugPrint('📍 [WalkScreen] → 웹 플레이스홀더 표시');
      return _buildWebMapPlaceholder();
    }
    
    // 위치 로딩 중이면 로딩 위젯 표시
    if (_isLocationLoading) {
      debugPrint('📍 [WalkScreen] → 로딩 위젯 표시 (progress: $_locationProgress)');
      return MapLoadingWidget.walk(progress: _locationProgress);
    }
    
    // 모바일에서는 카카오맵
    if (_currentPosition != null) {
      // 초기 위치 설정 (한 번만)
      _initialMapPosition ??= _createLatLng(
        _currentPosition!.latitude, 
        _currentPosition!.longitude,
      );
      
      debugPrint('📍 [WalkScreen] → 카카오맵 렌더링: ${_initialMapPosition!.latitude}, ${_initialMapPosition!.longitude}');
      
      return KakaoMap(
        key: const ValueKey('kakao_map_walk'), // 리빌드 방지
        option: KakaoMapOption(
          position: _initialMapPosition!,
          zoomLevel: 17,
          mapType: MapType.normal,
        ),
        onMapReady: _onMapReady,
        onCameraMoveEnd: (position, gestureType) => _onCameraMoveEnd(position),
      );
    }
    
    // 위치 정보가 없으면 로딩 위젯
    debugPrint('📍 [WalkScreen] → 위치 없음, 오류 메시지 표시');
    return MapLoadingWidget.walk(message: '위치를 확인할 수 없습니다');
  }
  
  /// 카카오맵 생성 완료 콜백
  void _onMapReady(KakaoMapController controller) {
    debugPrint('📍 [WalkScreen] onMapReady 호출됨');
    _mapController = controller;
    setState(() => _isMapReady = true);
  }
  
  /// 카메라 이동 완료 콜백
  void _onCameraMoveEnd(CameraPosition position) {
    _currentMapPosition = position.position;
  }
  
  /// 지도에 경로 폴리라인 그리기
  /// 참고: kakao_map_sdk에서 경로 그리기는 controller.routeLayer를 통해 접근
  Future<void> _drawRoutePolyline() async {
    if (_mapController == null || _routePoints.length < 2) return;
    
    try {
      // 경로 포인트를 LatLng 리스트로 변환
      final points = _routePoints
          .map((gp) => _createLatLng(gp.latitude, gp.longitude))
          .toList();
      
      // 경로 그리기
      await _mapController!.routeLayer.addRoute(
        points,
        RouteStyle(AppColors.walk, 8),
      );
      
      // 최신 위치로 카메라 이동
      final lastPoint = _routePoints.last;
      final cameraUpdate = CameraUpdate.newCenterPosition(
        _createLatLng(lastPoint.latitude, lastPoint.longitude),
      );
      await _mapController!.moveCamera(
        cameraUpdate,
        animation: const CameraAnimation(300),
      );
    } catch (e) {
      debugPrint('경로 그리기 실패: $e');
    }
  }
  
  /// 현재 위치로 카메라 이동
  Future<void> _moveCameraToCurrentPosition() async {
    if (_mapController == null || _currentPosition == null) return;
    
    try {
      final cameraUpdate = CameraUpdate.newCenterPosition(
        _createLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
      await _mapController!.moveCamera(
        cameraUpdate,
        animation: const CameraAnimation(500),
      );
    } catch (e) {
      debugPrint('카메라 이동 실패: $e');
    }
  }
  
  /// 내 위치로 이동 버튼 (LocationHelper 사용)
  Future<void> _goToMyLocation() async {
    final result = await LocationHelper.getCurrentLocation();
    
    if (!result.isSuccess || result.position == null) {
      // 위치 가져오기 실패 - 오류 팝업 표시
      _showLocationErrorDialog();
      return;
    }
    
    setState(() {
      _currentPosition = result.position;
    });
    
    // 카카오맵 카메라 이동
    if (_mapController != null) {
      final cameraUpdate = CameraUpdate.newCenterPosition(
        _createLatLng(result.latitude, result.longitude),
      );
      await _mapController!.moveCamera(
        cameraUpdate,
        animation: const CameraAnimation(500),
      );
    }
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
  
  /// 모바일용 카카오맵
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
                  '현재 위치를 중심으로 지도가 표시됩니다',
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
                          if (isSelected && _selectedPetIds.length <= 1) {
                            // 최소 1마리는 선택되어야 함
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('최소 1마리의 반려동물을 선택해야 합니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
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
            // 안내 문구 (산책 전)
            if (!_isWalking)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.gapM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 16, color: AppColors.walk),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '산책을 시작하면 이동 경로에 발바닥이 자동으로 남아요!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            
            // 산책 중 정보 (발바닥 개수)
            if (_isWalking)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.gapM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PawPrintIcon(size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '발바닥 ${_footprints.length}개 남김',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.walk,
                      ),
                    ),
                  ],
                ),
              ),
            
            // 산책 시작/종료 버튼
            MingrrButton(
              text: _isWalking ? '산책 종료' : '산책 시작',
              backgroundColor: _isWalking ? AppColors.error : AppColors.walk,
              textColor: Colors.white,
              icon: _isWalking ? Icons.stop : Icons.play_arrow,
              onPressed: _isWalking ? _stopWalk : _startWalk,
            ),
          ],
        ),
      ),
    );
  }

  /// 산책 시작
  Future<void> _startWalk() async {
    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('함께 산책할 반려동물을 선택해주세요')),
      );
      return;
    }
    
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보를 가져오는 중입니다. 잠시 후 다시 시도해주세요')),
      );
      return;
    }
    
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;
      
      final healthService = ref.read(healthServiceProvider);
      final startLocation = GeoPoint(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      // Firebase에 산책 기록 시작
      final recordId = await healthService.startWalkRecord(
        userId: user.uid,
        petId: _selectedPetIds.first,
        petIds: _selectedPetIds.toList(),
        startLocation: startLocation,
      );
      
      setState(() {
        _isWalking = true;
        _currentWalkRecordId = recordId;
        _walkDuration = 0;
        _walkDistance = 0;
        _routePoints.clear();
        _routePoints.add(startLocation);
        _footprints.clear();
        _lastPosition = _currentPosition;
      });
      
      // 타이머 시작 (1초마다)
      _walkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _walkDuration++;
        });
      });
      
      // 위치 추적 시작 (10초마다)
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10미터 이상 이동 시 업데이트
        ),
      ).listen((Position position) {
        _updateWalkRoute(position);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('산책을 시작했습니다! 🐾'),
          backgroundColor: AppColors.walk,
        ),
      );
    } catch (e) {
      debugPrint('산책 시작 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('산책 시작 중 오류가 발생했습니다: $e')),
      );
    }
  }
  
  /// 산책 경로 업데이트
  Future<void> _updateWalkRoute(Position position) async {
    if (!_isWalking || _currentWalkRecordId == null) return;
    
    try {
      final newLocation = GeoPoint(position.latitude, position.longitude);
      
      // 이전 위치와의 거리 계산
      if (_lastPosition != null) {
        final distance = LocationService.calculateDistance(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        final previousDistance = _walkDistance;
        
        setState(() {
          _walkDistance += distance;
          _currentPosition = position;
          _lastPosition = position;
          _routePoints.add(newLocation);
        });
        
        // 50m마다 자동으로 발바닥 남기기
        final previousFootprintCount = (previousDistance / 50).floor();
        final currentFootprintCount = (_walkDistance / 50).floor();
        
        if (currentFootprintCount > previousFootprintCount) {
          setState(() {
            _footprints.add(newLocation);
          });
          
          // Firebase에 발바닥 추가
          final healthService = ref.read(healthServiceProvider);
          await healthService.addFootprint(
            recordId: _currentWalkRecordId!,
            location: newLocation,
          );
        }
        
        // 지도에 경로 폴리라인 업데이트
        await _drawRoutePolyline();
        
        // Firebase 경로 업데이트
        final healthService = ref.read(healthServiceProvider);
        await healthService.updateWalkRoute(
          recordId: _currentWalkRecordId!,
          newLocation: newLocation,
          totalDistance: _walkDistance,
        );
      }
    } catch (e) {
      debugPrint('경로 업데이트 오류: $e');
    }
  }
  
  /// 발자국 남기기
  Future<void> _addFootprint() async {
    if (!_isWalking || _currentWalkRecordId == null || _currentPosition == null) {
      return;
    }
    
    try {
      final location = GeoPoint(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      setState(() {
        _footprints.add(location);
      });
      
      final healthService = ref.read(healthServiceProvider);
      await healthService.addFootprint(
        recordId: _currentWalkRecordId!,
        location: location,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('발자국을 남겼습니다! 🐾'),
          backgroundColor: AppColors.walk,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('발자국 추가 오류: $e');
    }
  }
  
  /// 산책 종료
  Future<void> _stopWalk() async {
    if (!_isWalking || _currentWalkRecordId == null) return;
    
    try {
      // 타이머 및 위치 추적 중지
      _walkTimer?.cancel();
      _positionStreamSubscription?.cancel();
      
      // 칼로리 계산 (간단한 공식: 거리(km) * 50)
      final calories = (_walkDistance / 1000) * 50;
      
      // Firebase에 산책 종료 저장
      final healthService = ref.read(healthServiceProvider);
      await healthService.endWalkRecord(
        recordId: _currentWalkRecordId!,
        totalDistance: _walkDistance,
        calories: calories,
      );
      
      // 요약 다이얼로그 표시
      _showWalkSummary();
      
      setState(() {
        _isWalking = false;
        _currentWalkRecordId = null;
      });
    } catch (e) {
      debugPrint('산책 종료 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('산책 종료 중 오류가 발생했습니다: $e')),
      );
    }
  }
  
  /// 산책 기록 보기
  void _showWalkHistory(BuildContext context) {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      '산책 기록',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 산책 기록 목록
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('walk_records')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('startTime', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets, size: 64, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          const Text(
                            '아직 산책 기록이 없어요',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '산책을 시작하면 기록이 저장됩니다',
                            style: TextStyle(fontSize: 13, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final startTime = (data['startTime'] as Timestamp?)?.toDate();
                      final distance = (data['totalDistance'] as num?)?.toDouble() ?? 0;
                      final duration = data['duration'] as int? ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.walk.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_walk, color: AppColors.walk),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    startTime != null
                                        ? '${startTime.month}월 ${startTime.day}일 산책'
                                        : '산책 기록',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDistance(distance)} · ${_formatDuration(duration)}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textHint),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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
            _buildSummaryRow('칼로리', '${(_walkDistance / 1000 * 50).toInt()} kcal'),
            _buildSummaryRow('발자국', '${_footprints.length}개'),
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
