import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/location_model.dart';
import '../services/geocoding_service.dart';

/// ============================================================
/// 지도 위치 선택 화면 (레거시 호환용)
/// 
/// 새로운 코드에서는 아래 파일을 사용하세요:
/// - lib/core/widgets/map/map_location_picker.dart
/// - lib/core/widgets/map/map_view_widget.dart
/// - lib/core/widgets/map/location_display_card.dart
/// ============================================================

/// 위치 좌표 클래스 (레거시 호환용 - 새 코드에서는 LocationData 사용)
@Deprecated('Use LocationData from core/models/location_model.dart instead')
class LocationCoord {
  final double latitude;
  final double longitude;

  const LocationCoord({required this.latitude, required this.longitude});
  
  /// LocationData로 변환
  LocationData toLocationData() => LocationData(
    latitude: latitude,
    longitude: longitude,
  );
  
  /// LocationData에서 생성
  factory LocationCoord.fromLocationData(LocationData data) => LocationCoord(
    latitude: data.latitude,
    longitude: data.longitude,
  );
}

/// 지도 위치 선택 다이얼로그 표시 (레거시 호환용)
@Deprecated('Use showMapLocationPicker from core/widgets/map/map_location_picker.dart instead')
Future<LocationCoord?> showMapLocationPicker({
  required BuildContext context,
  LocationCoord? initialPosition,
  Color accentColor = AppColors.market,
  String title = '위치 선택',
}) async {
  return Navigator.push<LocationCoord>(
    context,
    MaterialPageRoute(
      builder: (context) => MapLocationPickerPlaceholder(
        initialPosition: initialPosition,
        accentColor: accentColor,
        title: title,
      ),
    ),
  );
}

class MapLocationPickerPlaceholder extends StatefulWidget {
  final LocationCoord? initialPosition;
  final Color accentColor;
  final String title;

  const MapLocationPickerPlaceholder({
    super.key,
    this.initialPosition,
    this.accentColor = AppColors.market,
    this.title = '위치 선택',
  });

  @override
  State<MapLocationPickerPlaceholder> createState() => _MapLocationPickerPlaceholderState();
}

class _MapLocationPickerPlaceholderState extends State<MapLocationPickerPlaceholder> {
  LocationCoord? _selectedPosition;
  bool _isLoading = true;
  KakaoMapController? _mapController;
  StreamSubscription<CameraMoveEndEvent>? _cameraMoveEndSubscription;

  // 기본 위치 (서울 시청)
  static const LocationCoord _defaultPosition = LocationCoord(latitude: 37.5665, longitude: 126.9780);
  
  @override
  void dispose() {
    _cameraMoveEndSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  Future<void> _initializePosition() async {
    if (widget.initialPosition != null) {
      setState(() {
        _selectedPosition = widget.initialPosition;
        _isLoading = false;
      });
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _selectedPosition = _defaultPosition;
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _selectedPosition = _defaultPosition;
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedPosition = _defaultPosition;
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      setState(() {
        _selectedPosition = LocationCoord(latitude: position.latitude, longitude: position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedPosition = _defaultPosition;
        _isLoading = false;
      });
    }
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
          ? Center(
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
            )
          : Stack(
              children: [
                // 카카오맵 또는 웹 플레이스홀더
                if (kIsWeb)
                  _buildWebPlaceholder()
                else
                  Builder(
                    builder: (context) {
                      debugPrint('🗺️ KakaoMap 위젯 빌드 시작');
                      debugPrint('🗺️ 초기 위치: ${_selectedPosition!.latitude}, ${_selectedPosition!.longitude}');
                      return KakaoMap(
                        onMapCreated: _onMapCreated,
                        initialPosition: LatLng(
                          latitude: _selectedPosition!.latitude,
                          longitude: _selectedPosition!.longitude,
                        ),
                      );
                    },
                  ),

                // 중앙 핀 (고정)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 50,
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

                // 내 위치 버튼
                Positioned(
                  right: AppSizes.paddingM,
                  bottom: 140,
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
                ),

                // 하단 확인 버튼
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingL),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          // 선택된 좌표 표시
                          if (_selectedPosition != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.gapM),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: widget.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '위도: ${_selectedPosition!.latitude.toStringAsFixed(6)}, 경도: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, _selectedPosition);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.accentColor,
                                foregroundColor: Colors.white,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// 카카오맵 생성 콜백
  void _onMapCreated(KakaoMapController controller) {
    debugPrint('✅ KakaoMap 생성 완료!');
    _mapController = controller;
    
    // 카메라 이동 완료 이벤트 리스너 - 중앙 위치 업데이트
    _cameraMoveEndSubscription = controller.onCameraMoveEndStream.listen((event) {
      debugPrint('📍 카메라 이동: ${event.latitude}, ${event.longitude}');
      setState(() {
        _selectedPosition = LocationCoord(
          latitude: event.latitude,
          longitude: event.longitude,
        );
      });
    });
  }
  
  /// 웹용 플레이스홀더
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
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 서비스를 활성화해주세요'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 권한을 허용해주세요'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('설정에서 위치 권한을 허용해주세요'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _selectedPosition = LocationCoord(latitude: position.latitude, longitude: position.longitude);
      });
      
      // 카카오맵 카메라 이동
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
      debugPrint('현재 위치 가져오기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재 위치를 가져올 수 없습니다. 잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// 격자 패턴 페인터
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
