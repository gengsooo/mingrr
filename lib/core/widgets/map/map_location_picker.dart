import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import '../../constants/app_icons.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../../models/location_model.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_helper.dart';
import '../common_widgets.dart';
import '../dialogs/dialogs.dart';
import '../loading/loading_widgets.dart';
import '../../utils/app_logger.dart';
import 'map_loading_widget.dart';

/// ============================================================
/// 지도 위치 선택 화면 (V2 - 리팩토링)
/// 
/// 개선사항:
/// - LocationHelper 사용으로 위치 로직 통합
/// - 주소 표시 영역 분리로 지도 리렌더링 방지
/// - ValueNotifier 사용으로 효율적인 상태 관리
/// ============================================================

/// 지도 위치 선택 다이얼로그 표시
Future<LocationData?> showMapLocationPicker({
  required BuildContext context,
  LocationData? initialLocation,
  Color? accentColor,
  String title = '위치 선택',
}) async {
  return Navigator.push<LocationData>(
    context,
    MaterialPageRoute(
      builder: (context) => MapLocationPicker(
        initialLocation: initialLocation,
        accentColor: accentColor,
        title: title,
      ),
    ),
  );
}

class MapLocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  final Color? accentColor;
  final String title;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    this.accentColor,
    this.title = '위치 선택',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  // accentColor getter (nullable 처리)
  Color get _accentColor => widget.accentColor ?? Theme.of(context).colorScheme.primary;
  
  // 지도 관련 상태 (지도 영역에서만 사용)
  bool _isInitializing = true;
  KakaoMapController? _mapController;
  LatLng? _initialMapPosition;
  
  // 주소 관련 상태 (ValueNotifier로 분리 - 지도 리렌더링 방지)
  final ValueNotifier<AddressState> _addressState = ValueNotifier(
    const AddressState(isLoading: true, address: null, location: null),
  );
  
  Timer? _addressDebounceTimer;
  
  // 위치 로딩 진행 상태
  LocationProgress? _locationProgress;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  @override
  void dispose() {
    _addressDebounceTimer?.cancel();
    _addressState.dispose();
    super.dispose();
  }

  /// LatLng 생성 헬퍼
  LatLng _createLatLng(double lat, double lng) => LatLng(lat, lng);

  /// 초기 위치 설정 (3단계 전략)
  Future<void> _initializePosition() async {
    AppLogger.debug('MapLocationPicker', '=== 초기 위치 설정 시작 ===');
    AppLogger.debug('MapLocationPicker', 'initialLocation: ${widget.initialLocation != null}');
    
    setState(() {
      _isInitializing = true;
      _locationProgress = null;
    });
    
    // 초기 위치가 제공된 경우
    if (widget.initialLocation != null) {
      AppLogger.debug('MapLocationPicker', '초기 위치 사용: ${widget.initialLocation!.latitude}, ${widget.initialLocation!.longitude}');
      _initialMapPosition = _createLatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _addressState.value = AddressState(
        isLoading: false,
        address: widget.initialLocation!.displayAddress,
        location: widget.initialLocation,
      );
      setState(() {
        _isInitializing = false;
        _locationProgress = null;
      });
      return;
    }

    // LocationHelper를 사용하여 현재 위치 가져오기 (3단계 전략)
    final result = await LocationHelper.getCurrentLocation(
      purpose: LocationPurpose.map,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _locationProgress = progress);
        }
      },
    );
    
    AppLogger.debug('MapLocationPicker', '위치 결과: isSuccess=${result.isSuccess}, source=${result.source}, errorType=${result.errorType}');
    
    if (!mounted) {
      AppLogger.warning('MapLocationPicker', 'mounted=false, 상태 업데이트 스킵');
      return;
    }
    
    // 위치 가져오기 실패 시 오류 팝업 표시
    if (!result.isSuccess || result.position == null) {
      AppLogger.warning('MapLocationPicker', '위치 가져오기 실패 - 오류 팝업 표시');
      setState(() {
        _isInitializing = false;
        _locationProgress = null;
      });
      _showLocationErrorDialog();
      return;
    }
    
    AppLogger.info('MapLocationPicker', '위치 획득 (source: ${result.source}): ${result.latitude}, ${result.longitude}');
    
    _initialMapPosition = _createLatLng(result.latitude, result.longitude);
    
    final location = LocationData.fromCoordinates(result.latitude, result.longitude);
    _addressState.value = AddressState(
      isLoading: true,
      address: null,
      location: location,
    );
    
    setState(() {
      _isInitializing = false;
      _locationProgress = null;
    });
    
    // 주소 조회
    _fetchAddress(result.latitude, result.longitude);
    
    // 백그라운드에서 high 정확도 위치 업데이트
    _updateHighAccuracyPosition(result.position!);
  }
  
  /// 백그라운드에서 high 정확도 위치 업데이트
  Future<void> _updateHighAccuracyPosition(Position currentPosition) async {
    if (!mounted) return;
    
    final highPosition = await LocationHelper.getHighAccuracyPosition();
    if (highPosition == null || !mounted) return;
    
    // 50m 이상 차이나면 지도 업데이트
    if (LocationHelper.shouldUpdatePosition(currentPosition, highPosition)) {
      AppLogger.debug('MapLocationPicker', 'high 정확도 위치로 업데이트 (50m+ 차이)');
      
      // 지도 카메라 부드럽게 이동
      if (_mapController != null) {
        final cameraUpdate = CameraUpdate.newCenterPosition(
          _createLatLng(highPosition.latitude, highPosition.longitude),
        );
        await _mapController!.moveCamera(
          cameraUpdate,
          animation: const CameraAnimation(500),
        );
        
        // 주소도 업데이트
        _fetchAddress(highPosition.latitude, highPosition.longitude);
      }
    } else {
      AppLogger.debug('MapLocationPicker', 'high 정확도 위치 차이 50m 미만 - 업데이트 스킵');
    }
  }
  
  /// 위치 관련 상태 초기화 (재시도 시 깨끗한 상태에서 시작)
  void _resetLocationState() {
    AppLogger.debug('MapLocationPicker', '위치 상태 초기화');
    _initialMapPosition = null;
    _mapController = null;
    _addressState.value = const AddressState(isLoading: true, address: null, location: null);
  }
  
  /// 위치 오류 다이얼로그 표시
  Future<void> _showLocationErrorDialog() async {
    if (!mounted) return;
    
    final dialogResult = await showErrorDialog(
      context,
      type: ErrorType.location,
      themeColor: _accentColor,
    );
    
    if (dialogResult == ErrorResult.retry) {
      // 재시도 - 상태 초기화 후 다시 시도
      _resetLocationState();
      _initializePosition();
    } else {
      // 취소 - 이전 화면으로 돌아가기
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// 주소 조회 (지도 리렌더링 없이 주소만 업데이트)
  Future<void> _fetchAddress(double latitude, double longitude) async {
    _addressState.value = AddressState(
      isLoading: true,
      address: null,
      location: LocationData.fromCoordinates(latitude, longitude),
    );
    
    final result = await GeocodingService.reverseGeocode(latitude, longitude);
    
    if (!mounted) return;
    
    if (result != null) {
      _addressState.value = AddressState(
        isLoading: false,
        address: result.shortAddress,
        location: LocationData(
          latitude: latitude,
          longitude: longitude,
          fullAddress: result.fullAddress,
          shortAddress: result.shortAddress,
          sido: result.sido,
          sigungu: result.sigungu,
          dong: result.dong,
        ),
      );
    } else {
      _addressState.value = AddressState(
        isLoading: false,
        address: null,
        location: LocationData.fromCoordinates(latitude, longitude),
      );
    }
  }

  /// 카메라 이동 완료 콜백 (setState 없음 - 지도 리렌더링 방지)
  void _onCameraMoveEnd(CameraPosition position) {
    final lat = position.position.latitude;
    final lng = position.position.longitude;
    
    // 디바운스로 주소 조회 (지도 setState 없이 ValueNotifier만 업데이트)
    _addressDebounceTimer?.cancel();
    _addressDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchAddress(lat, lng);
    });
    
    // 즉시 로딩 상태로 변경 (지도 리렌더링 없음)
    _addressState.value = AddressState(
      isLoading: true,
      address: null,
      location: LocationData.fromCoordinates(lat, lng),
    );
  }

  /// 내 위치로 이동
  Future<void> _goToMyLocation() async {
    final result = await LocationHelper.getCurrentLocation();
    
    if (!result.isSuccess || result.position == null) {
      _showError(result.message ?? '현재 위치를 가져올 수 없습니다');
      return;
    }
    
    if (_mapController != null && !kIsWeb) {
      final cameraUpdate = CameraUpdate.newCenterPosition(
        _createLatLng(result.latitude, result.longitude),
      );
      await _mapController!.moveCamera(
        cameraUpdate,
        animation: const CameraAnimation(500),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      MingrrSnackBar.warning(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MingrrAppBar.form(
        title: widget.title,
        onClose: () => Navigator.pop(context),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isInitializing
          ? _buildLoadingView()
          : Column(
              children: [
                // 지도 영역 (독립적)
                Expanded(
                  child: Stack(
                    children: [
                      _buildMapView(),
                      _buildCenterPin(),
                      _buildMyLocationButton(),
                    ],
                  ),
                ),
                // 하단 패널 (ValueNotifier로 독립적 업데이트)
                _AddressPanel(
                  addressState: _addressState,
                  accentColor: _accentColor,
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    if (_accentColor == context.features.market) {
      return MapLoadingWidget.market(progress: _locationProgress);
    } else if (_accentColor == context.features.walk) {
      return MapLoadingWidget.walk(progress: _locationProgress);
    } else {
      return MapLoadingWidget.profile(progress: _locationProgress);
    }
  }

  Widget _buildMapView() {
    AppLogger.debug('MapLocationPicker', '_buildMapView: kIsWeb=$kIsWeb, _initialMapPosition=${_initialMapPosition != null}');
    
    if (kIsWeb) {
      AppLogger.debug('MapLocationPicker', '웹 플레이스홀더 표시');
      return _buildWebPlaceholder();
    }
    
    // 위치 정보가 없으면 오류 표시
    if (_initialMapPosition == null) {
      AppLogger.warning('MapLocationPicker', '위치 없음, 오류 화면 표시');
      return _buildLocationErrorView();
    }
    
    AppLogger.debug('MapLocationPicker', '카카오맵 렌더링: ${_initialMapPosition!.latitude}, ${_initialMapPosition!.longitude}');
    
    return KakaoMap(
      key: const ValueKey('kakao_map_picker_v2'),
      option: KakaoMapOption(
        position: _initialMapPosition!,
        zoomLevel: 16,
        mapType: MapType.normal,
      ),
      onMapReady: (controller) {
        AppLogger.debug('MapLocationPicker', 'onMapReady 호출됨');
        _mapController = controller;
      },
      onCameraMoveEnd: (position, gestureType) => _onCameraMoveEnd(position),
    );
  }
  
  Widget _buildLocationErrorView() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.locationOff,
              size: 64,
              color: _accentColor.withValues(alpha: AppOpacity.o50),
            ),
            const SizedBox(height: AppSizes.gapL),
            Text(
              '위치를 가져올 수 없습니다',
              style: AppTextStyles.headlineSmall(context).withWeight(FontWeight.w600).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.gapS),
            TextButton.icon(
              onPressed: () {
                setState(() => _isInitializing = true);
                _initializePosition();
              },
              icon: Icon(AppIcons.refresh),
              label: const Text('다시 시도'),
              style: TextButton.styleFrom(
                foregroundColor: _accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.location,
              size: 48,
              color: _accentColor,
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      right: AppSizes.paddingM,
      bottom: AppSizes.paddingM,
      child: FloatingActionButton.small(
        heroTag: 'myLocation_v2',
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: AppSizes.elevationM,
        onPressed: _goToMyLocation,
        child: Icon(
          AppIcons.myLocation,
          color: _accentColor,
        ),
      ),
    );
  }

  Widget _buildWebPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accentColor.withValues(alpha: AppOpacity.o10),
            _accentColor.withValues(alpha: AppOpacity.o20),
          ],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(_accentColor),
      ),
    );
  }
}

/// 주소 표시 패널 (별도 위젯으로 분리 - 지도 리렌더링 방지)
class _AddressPanel extends StatelessWidget {
  final ValueNotifier<AddressState> addressState;
  final Color accentColor;

  const _AddressPanel({
    required this.addressState,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 주소 표시 (ValueListenableBuilder로 독립적 업데이트)
            ValueListenableBuilder<AddressState>(
              valueListenable: addressState,
              builder: (context, state, _) => _buildAddressDisplay(context, state),
            ),
            const SizedBox(height: AppSizes.gapM),
            // 확인 버튼
            ValueListenableBuilder<AddressState>(
              valueListenable: addressState,
              builder: (context, state, _) => _buildConfirmButton(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDisplay(BuildContext context, AddressState state) {
    // 높이 고정으로 레이아웃 변경 방지 (꿀렁거림 해결)
    // 로딩/주소 표시 상태 모두 동일한 높이 유지
    const double fixedHeight = 56.0;
    
    return Container(
      height: fixedHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.locationOutlined,
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: state.isLoading
                ? Row(
                    children: [
                      MingrrLoadingIndicator(
                        size: 14,
                        strokeWidth: 2,
                        customColor: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '주소를 가져오는 중...',
                        style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.address ?? '주소 정보 없음',
                        style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (state.location?.fullAddress != null &&
                          state.location!.fullAddress != state.address)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSizes.paddingXXS),
                          child: Text(
                            state.location!.fullAddress!,
                            style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, AddressState state) {
    return MingrrButton(
      text: '이 위치로 선택',
      onPressed: state.location != null && !state.isLoading
          ? () => Navigator.pop(context, state.location)
          : null,
      isLoading: state.isLoading,
      backgroundColor: accentColor,
      textColor: Colors.white,
      height: 52,
    );
  }
}

/// 주소 상태 클래스
class AddressState {
  final bool isLoading;
  final String? address;
  final LocationData? location;

  const AddressState({
    required this.isLoading,
    required this.address,
    required this.location,
  });
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: AppOpacity.o15)
      ..strokeWidth = 1;

    const spacing = 40.0;

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
