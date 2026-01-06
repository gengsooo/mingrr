import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 지도 위치 선택 화면 (플레이스홀더)
/// 실제 기기에서는 카카오 지도 사용
/// 에뮬레이터에서는 좌표 직접 입력 방식
/// ============================================================

/// 위치 좌표 클래스 (카카오 LatLng 대체)
class LocationCoord {
  final double latitude;
  final double longitude;

  const LocationCoord({required this.latitude, required this.longitude});
}

/// 지도 위치 선택 다이얼로그 표시
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

  // 기본 위치 (서울 시청)
  static const LocationCoord _defaultPosition = LocationCoord(latitude: 37.5665, longitude: 126.9780);

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
                // 지도 플레이스홀더
                Container(
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
                        child: const Text(
                          '실제 기기에서 지도가 표시됩니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
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

      setState(() {
        _selectedPosition = LocationCoord(latitude: position.latitude, longitude: position.longitude);
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
