import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 지도 위치 선택 화면
/// 핀을 이동하여 위치를 선택할 수 있는 전체 화면 지도
/// ============================================================
class MapLocationPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final Color accentColor;
  final String title;

  const MapLocationPicker({
    super.key,
    this.initialPosition,
    this.accentColor = AppColors.market,
    this.title = '위치 선택',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  KakaoMapController? _mapController;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  StreamSubscription<CameraMoveEndEvent>? _cameraMoveEndSubscription;

  // 기본 위치 (서울 시청)
  static const LatLng _defaultPosition = LatLng(latitude: 37.5665, longitude: 126.9780);

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }
  
  @override
  void dispose() {
    _cameraMoveEndSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
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
        _selectedPosition = LatLng(latitude: position.latitude, longitude: position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedPosition = _defaultPosition;
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(KakaoMapController controller) {
    _mapController = controller;
    
    // 카메라 이동 완료 이벤트 리스너
    _cameraMoveEndSubscription = controller.onCameraMoveEndStream.listen((event) {
      setState(() {
        _selectedPosition = LatLng(
          latitude: event.latitude,
          longitude: event.longitude,
        );
      });
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
                // 지도
                KakaoMap(
                  onMapCreated: _onMapCreated,
                  initialPosition: _selectedPosition!,
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
                  bottom: 120,
                  child: FloatingActionButton.small(
                    heroTag: 'myLocation',
                    backgroundColor: Colors.white,
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

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      final newPosition = LatLng(latitude: position.latitude, longitude: position.longitude);
      
      _mapController?.moveCamera(
        cameraUpdate: CameraUpdate.fromLatLng(newPosition),
        animation: const CameraAnimation(
          duration: 500,
          autoElevation: false,
          isConsecutive: false,
        ),
      );
      
      setState(() {
        _selectedPosition = newPosition;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재 위치를 가져올 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// 지도 위치 선택 화면을 표시하는 함수
Future<LatLng?> showMapLocationPicker({
  required BuildContext context,
  LatLng? initialPosition,
  Color accentColor = AppColors.market,
  String title = '위치 선택',
}) async {
  return Navigator.push<LatLng>(
    context,
    MaterialPageRoute(
      builder: (context) => MapLocationPicker(
        initialPosition: initialPosition,
        accentColor: accentColor,
        title: title,
      ),
    ),
  );
}
