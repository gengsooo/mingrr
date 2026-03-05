import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../constants/location_constants.dart';
import '../theme/app_text_styles.dart';
import '../theme/feature_colors.dart';
import '../services/firebase_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../providers/location_verification_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/dialogs/dialog_buttons.dart';

/// ============================================================
/// 위치 인증 헬퍼
/// 
/// 앱 전역에서 위치 인증 다이얼로그를 호출할 수 있는 유틸리티
/// 데이팅, 마켓, 소모임 화면에서 위치 미인증 시 사용
/// ============================================================
class LocationVerificationHelper {
  LocationVerificationHelper._();

  /// 위치 인증 다이얼로그 표시
  /// 
  /// [context]: BuildContext
  /// [ref]: WidgetRef (Riverpod)
  /// 반환값: 인증 성공 시 true, 실패/취소 시 false
  static Future<bool> showVerificationDialog(BuildContext context, WidgetRef ref) async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LocationVerificationDialog(
        userId: userId,
        ref: ref,
      ),
    );

    return result ?? false;
  }
}

/// ============================================================
/// 위치 인증 통합 다이얼로그
/// 
/// 로딩 → 결과 화면을 하나의 다이얼로그에서 처리하여 깜빡임 방지
/// ============================================================
class LocationVerificationDialog extends StatefulWidget {
  final String userId;
  final WidgetRef ref;

  const LocationVerificationDialog({
    super.key,
    required this.userId,
    required this.ref,
  });

  @override
  State<LocationVerificationDialog> createState() => _LocationVerificationDialogState();
}

class _LocationVerificationDialogState extends State<LocationVerificationDialog> {
  // 상태
  bool _isLoading = true;
  String _statusMessage = 'GPS 신호를 찾고 있습니다...';
  String? _errorMessage;
  
  // 결과 데이터
  Position? _position;
  String? _addressText;
  GeoPoint? _savedLocation;
  double? _distance;
  bool _isFirstTime = true;
  
  @override
  void initState() {
    super.initState();
    _startLocationVerification();
  }
  
  Future<void> _startLocationVerification() async {
    try {
      // 1. 위치 서비스 확인
      setState(() => _statusMessage = '위치 서비스 확인 중...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = '위치 서비스가 꺼져 있습니다.\n설정에서 위치 서비스를 켜주세요.';
        });
        return;
      }
      
      // 2. 위치 권한 확인
      setState(() => _statusMessage = '위치 권한 확인 중...');
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10), onTimeout: () => LocationPermission.denied);
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = '위치 권한이 필요합니다.\n앱 설정에서 위치 권한을 허용해주세요.';
        });
        return;
      }
      
      // 3. 위치 획득
      setState(() => _statusMessage = '현재 위치 확인 중...');
      Position? position;
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          position = lastPosition;
        } else {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(const Duration(seconds: 8));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'GPS 신호를 찾을 수 없습니다.\n실외에서 다시 시도해주세요.';
        });
        return;
      }
      
      _position = position;
      
      // 4. 주소 변환
      setState(() => _statusMessage = '주소 확인 중...');
      final addressResult = await GeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      _addressText = addressResult?.fullAddress ?? '주소를 확인할 수 없습니다';
      
      // 5. 기존 위치와 비교
      setState(() => _statusMessage = '위치 정보 확인 중...');
      final userDoc = await FirebaseService().usersCollection.doc(widget.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _savedLocation = data['homeLocation'] as GeoPoint?;
        
        if (_savedLocation != null) {
          _isFirstTime = false;
          _distance = LocationService.calculateDistanceFromGeoPoints(
            _savedLocation!,
            GeoPoint(position.latitude, position.longitude),
          );
        }
      }
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '위치 확인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      });
    }
  }
  
  Future<void> _handleVerification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '위치 인증 중...';
    });
    
    try {
      if (_isFirstTime) {
        await LocationVerificationService.verifyLocation(
          userId: widget.userId,
          currentPosition: _position!,
          address: _addressText!,
          isFirstTime: true,
        );
      } else if (_distance != null && _distance! <= LocationConstants.verificationRadiusMeters) {
        await LocationVerificationService.verifyLocation(
          userId: widget.userId,
          currentPosition: _position!,
          address: _addressText!,
        );
      } else {
        await LocationVerificationService.updateLocation(
          userId: widget.userId,
          currentPosition: _position!,
          address: _addressText!,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '위치 인증에 실패했습니다.\n잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: _isLoading
            ? _buildLoadingContent(colorScheme, color)
            : _errorMessage != null
                ? _buildErrorContent(colorScheme)
                : _buildResultContent(colorScheme, color),
      ),
    );
  }
  
  Widget _buildLoadingContent(ColorScheme colorScheme, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: MingrrLoadingIndicator(strokeWidth: 3, customColor: color),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapL),
        Text(
          '현재 위치 확인 중',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
      ],
    );
  }
  
  Widget _buildErrorContent(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: const Icon(AppIcons.locationOff, size: 28, color: Colors.red),
        ),
        const SizedBox(height: AppSizes.gapL),
        Text(
          '위치 확인 실패',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(context).copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: AppSizes.gapL),
        MingrrButton(
          text: '확인',
          onPressed: () => Navigator.pop(context, false),
          backgroundColor: colorScheme.primary,
          textColor: Colors.white,
          height: 48,
        ),
      ],
    );
  }
  
  Widget _buildResultContent(ColorScheme colorScheme, Color color) {
    // 거리에 따른 상태 결정
    final bool canVerify = _isFirstTime || 
        (_distance != null && _distance! <= LocationConstants.verificationRadiusMeters);
    final bool isTooFar = !_isFirstTime && 
        _distance != null && 
        _distance! > LocationConstants.verificationRadiusMeters &&
        _distance! <= LocationConstants.verificationNearbyMeters;
    final bool needsLocationChange = !_isFirstTime && 
        _distance != null && 
        _distance! > LocationConstants.verificationNearbyMeters;
    
    // 색상 결정
    final themeColor = canVerify 
        ? (_isFirstTime ? color : context.features.success)
        : (needsLocationChange ? color : Colors.orange);
    
    // 제목 결정
    String title;
    String message;
    String buttonText;
    IconData icon;
    
    if (canVerify) {
      if (_isFirstTime) {
        title = '위치 인증';
        message = '현재 위치를 내 동네로 등록하시겠습니까?';
        buttonText = '인증하기';
        icon = AppIcons.location;
      } else {
        title = '위치 인증 갱신';
        message = '현재 위치에서 인증을 갱신하시겠습니까?';
        buttonText = '인증 갱신';
        icon = AppIcons.checkCircle;
      }
    } else if (isTooFar) {
      title = '조금 더 가까이';
      message = '설정한 동네에서 ${_distance!.round()}m 떨어져 있어요.\n저장된 동네 근처(500m 이내)에서 인증할 수 있습니다.';
      buttonText = '확인';
      icon = AppIcons.nearMe;
    } else {
      title = '동네 변경';
      message = '현재 위치가 저장된 동네와\n${LocationService.formatDistance(_distance!)} 떨어져 있어요.';
      buttonText = '동네 변경';
      icon = AppIcons.swap;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: themeColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          title,
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 메시지
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context).copyWith(height: 1.4),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 주소 표시
        if (_addressText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(AppIcons.myLocation, color: themeColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _addressText!,
                        style: AppTextStyles.labelLarge(context),
                      ),
                      if (!_isFirstTime && _distance != null) ...[
                        const SizedBox(height: AppSizes.gapXXS),
                        Text(
                          '저장된 위치에서 ${_distance!.round()}m',
                          style: AppTextStyles.caption(context).copyWith(color: themeColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSizes.gapL),
        
        // 버튼
        if (isTooFar)
          // 조금 더 가까이: 확인 버튼만
          MingrrButton(
            text: buttonText,
            onPressed: () => Navigator.pop(context, false),
            backgroundColor: themeColor,
            textColor: Colors.white,
            height: 48,
          )
        else
          // 인증/동네변경: 취소/확인 버튼
          MingrrDialogButtons(
            cancelText: '취소',
            confirmText: buttonText,
            onCancel: () => Navigator.pop(context, false),
            onConfirm: _handleVerification,
            confirmColor: themeColor,
          ),
      ],
    );
  }
}
