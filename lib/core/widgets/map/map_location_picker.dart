import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/location_model.dart';
import '../../services/geocoding_service.dart';

/// ============================================================
/// 지도 위치 선택 화면 (리팩토링)
/// 
/// 기능:
/// - 카카오맵 기반 위치 선택
/// - 역지오코딩으로 실제 주소 표시
/// - 현재 위치 버튼
/// - 웹 플레이스홀더 지원
/// ============================================================

/// 지도 위치 선택 다이얼로그 표시
Future<LocationData?> showMapLocationPicker({
  required BuildContext context,
  LocationData? initialLocation,
  Color accentColor = AppColors.primary,
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
  final Color accentColor;
  final String title;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    this.accentColor = AppColors.primary,
    this.title = '위치 선택',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LocationData? _selectedLocation;
  String? _displayAddress;
  bool _isLoading = true;
  bool _isLoadingAddress = false;
  KakaoMapController? _mapController;
  StreamSubscription<CameraMoveEndEvent>? _cameraMoveEndSubscription;
  Timer? _addressDebounceTimer;

  @override
  void dispose() {
    _cameraMoveEndSubscription?.cancel();
    _mapController?.dispose();
    _addressDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  Future<void> _initializePosition() async {
    if (widget.initialLocation != null) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _displayAddress = widget.initialLocation!.displayAddress;
        _isLoading = false;
      });
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      final location = LocationData.fromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLocation = location;
        _isLoading = false;
      });
      
      _fetchAddress(position.latitude, position.longitude);
    } catch (e) {
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _selectedLocation = LocationData.defaultLocation;
      _displayAddress = LocationData.defaultLocation.displayAddress;
      _isLoading = false;
    });
  }

  Future<void> _fetchAddress(double latitude, double longitude) async {
    setState(() => _isLoadingAddress = true);
    
    final result = await GeocodingService.reverseGeocode(latitude, longitude);
    
    if (mounted) {
      setState(() {
        _isLoadingAddress = false;
        if (result != null) {
          _displayAddress = result.shortAddress;
          _selectedLocation = LocationData(
            latitude: latitude,
            longitude: longitude,
            fullAddress: result.fullAddress,
            shortAddress: result.shortAddress,
            sido: result.sido,
            sigungu: result.sigungu,
            dong: result.dong,
          );
        } else {
          _displayAddress = null;
        }
      });
    }
  }

  void _onCameraMove(double latitude, double longitude) {
    setState(() {
      _selectedLocation = LocationData.fromCoordinates(latitude, longitude);
      _displayAddress = null;
    });
    
    _addressDebounceTimer?.cancel();
    _addressDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchAddress(latitude, longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : Stack(
              children: [
                _buildMapView(),
                _buildCenterPin(),
                _buildMyLocationButton(),
                _buildBottomPanel(),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: widget.accentColor),
          const SizedBox(height: 16),
          const Text(
            '위치를 가져오는 중...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (kIsWeb) {
      return _buildWebPlaceholder();
    }
    
    return KakaoMap(
      onMapCreated: _onMapCreated,
      initialPosition: LatLng(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      ),
    );
  }

  Widget _buildCenterPin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 48,
              color: widget.accentColor,
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: widget.accentColor,
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
      bottom: 160,
      child: FloatingActionButton.small(
        heroTag: 'myLocation',
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: _goToMyLocation,
        child: Icon(
          Icons.my_location,
          color: widget.accentColor,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddressDisplay(),
              const SizedBox(height: AppSizes.gapM),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 20,
            color: widget.accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _isLoadingAddress
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '주소를 가져오는 중...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayAddress ?? '주소 정보 없음',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedLocation?.fullAddress != null &&
                          _selectedLocation!.fullAddress != _displayAddress)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _selectedLocation!.fullAddress!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
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

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _selectedLocation != null
            ? () => Navigator.pop(context, _selectedLocation)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          '이 위치로 선택',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _onMapCreated(KakaoMapController controller) {
    _mapController = controller;
    
    _cameraMoveEndSubscription = controller.onCameraMoveEndStream.listen((event) {
      _onCameraMove(event.latitude, event.longitude);
    });
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
            widget.accentColor.withOpacity(0.1),
            widget.accentColor.withOpacity(0.2),
          ],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(widget.accentColor),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('위치 서비스를 활성화해주세요');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('위치 권한을 허용해주세요');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('설정에서 위치 권한을 허용해주세요');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (_mapController != null && !kIsWeb) {
        await _mapController!.moveCamera(
          cameraUpdate: CameraUpdate.fromLatLng(
            LatLng(latitude: position.latitude, longitude: position.longitude),
          ),
          animation: const CameraAnimation(
            duration: 500,
            autoElevation: false,
            isConsecutive: false,
          ),
        );
      }
    } catch (e) {
      _showError('현재 위치를 가져올 수 없습니다');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
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
