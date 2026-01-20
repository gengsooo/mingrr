import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_sizes.dart';
import '../../theme/feature_colors.dart';
import '../../services/location_helper.dart';
import '../loading_widgets.dart';

/// ============================================================
/// 지도 로딩 위젯 (공통 컴포넌트)
/// 
/// 지도가 로딩되는 동안 표시되는 플레이스홀더
/// 걸어가는 귀여운 반려동물 애니메이션 + 진행 상태 표시
/// ============================================================

/// 로딩 위젯 타입 (색상 결정용)
enum MapLoadingType { walk, market, profile, dating, custom }

class MapLoadingWidget extends StatefulWidget {
  /// 메인 색상 (null이면 타입에 따라 자동 결정)
  final Color? accentColor;
  
  /// 로딩 위젯 타입
  final MapLoadingType type;
  
  /// 로딩 메시지
  final String message;
  
  /// 서브 메시지
  final String? subMessage;
  
  /// 높이 (null이면 무한대)
  final double? height;
  
  /// 진행 상태 (null이면 기본 메시지 사용)
  final LocationProgress? progress;

  const MapLoadingWidget({
    super.key,
    this.accentColor,
    this.type = MapLoadingType.custom,
    this.message = '지도를 불러오는 중...',
    this.subMessage,
    this.height,
    this.progress,
  });
  
  /// 산책용 로딩 위젯
  factory MapLoadingWidget.walk({String? message, LocationProgress? progress}) {
    return MapLoadingWidget(
      type: MapLoadingType.walk,
      message: message ?? '위치를 가져오는 중...',
      subMessage: '현재 위치를 중심으로 지도가 표시됩니다',
      progress: progress,
    );
  }
  
  /// 마켓용 로딩 위젯
  factory MapLoadingWidget.market({String? message, LocationProgress? progress}) {
    return MapLoadingWidget(
      type: MapLoadingType.market,
      message: message ?? '지도를 불러오는 중...',
      subMessage: '거래 희망 지역을 선택해주세요',
      progress: progress,
    );
  }
  
  /// 프로필용 로딩 위젯
  factory MapLoadingWidget.profile({String? message, LocationProgress? progress}) {
    return MapLoadingWidget(
      type: MapLoadingType.profile,
      message: message ?? '지도를 불러오는 중...',
      subMessage: '내 위치를 선택해주세요',
      progress: progress,
    );
  }
  
  /// 데이팅용 로딩 위젯
  factory MapLoadingWidget.dating({String? message, LocationProgress? progress}) {
    return MapLoadingWidget(
      type: MapLoadingType.dating,
      message: message ?? '지도를 불러오는 중...',
      progress: progress,
    );
  }

  @override
  State<MapLoadingWidget> createState() => _MapLoadingWidgetState();
}

class _MapLoadingWidgetState extends State<MapLoadingWidget>
    with TickerProviderStateMixin {
  /// 타입에 따른 색상 결정
  Color get _accentColor {
    if (widget.accentColor != null) return widget.accentColor!;
    final features = context.features;
    switch (widget.type) {
      case MapLoadingType.walk:
        return features.walk;
      case MapLoadingType.market:
        return features.market;
      case MapLoadingType.dating:
        return features.dating;
      case MapLoadingType.profile:
      case MapLoadingType.custom:
        return Theme.of(context).colorScheme.primary;
    }
  }
  
  late AnimationController _walkController;
  late AnimationController _legController;
  late Animation<double> _walkAnimation;
  late Animation<double> _legAnimation;
  
  String? _svgString;

  @override
  void initState() {
    super.initState();
    
    // SVG 파일 로드
    _loadSvg();
    
    // 걷기 애니메이션 (좌우 이동)
    _walkController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _walkAnimation = Tween<double>(begin: -40, end: 40).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
    );
    
    // 다리 움직임 애니메이션 (걷는 모션)
    _legController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    
    _legAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _legController, curve: Curves.easeInOut),
    );
  }
  
  /// SVG 파일 로드 및 색상 치환
  Future<void> _loadSvg() async {
    final rawSvg = await rootBundle.loadString('assets/icons/walking_dog.svg');
    
    // accentColor를 HEX 문자열로 변환
    final colorHex = '#${_accentColor.value.toRadixString(16).substring(2).toUpperCase()}';
    final lightColorHex = _getLighterColor(_accentColor);
    final darkColorHex = _getDarkerColor(_accentColor);
    
    // SVG 내 색상 치환 (원본 색상 → 동적 색상)
    final coloredSvg = rawSvg
        .replaceAll('#FF9800', colorHex)      // 메인 색상 (몸통, 머리, 다리)
        .replaceAll('#FFB74D', lightColorHex) // 밝은 색상 (털 효과)
        .replaceAll('#E65100', darkColorHex); // 어두운 색상 (귀)
    
    if (mounted) {
      setState(() => _svgString = coloredSvg);
    }
  }
  
  /// 밝은 색상 생성
  String _getLighterColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0));
    return '#${lighter.toColor().value.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  /// 어두운 색상 생성
  String _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0));
    return '#${darker.toColor().value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  void dispose() {
    _walkController.dispose();
    _legController.dispose();
    super.dispose();
  }
  
  /// 진행 상태에 따른 메시지
  String get _progressMessage {
    if (widget.progress == null) return widget.message;
    
    switch (widget.progress!) {
      case LocationProgress.checkingPermission:
        return '위치 권한 확인 중...';
      case LocationProgress.checkingCache:
        return '위치 확인 중...';
      case LocationProgress.gettingGpsMedium:
        return 'GPS 신호 찾는 중...';
      case LocationProgress.gettingGpsLow:
        return '거의 다 됐어요!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height ?? double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 걸어가는 귀여운 반려동물 애니메이션
            AnimatedBuilder(
              animation: Listenable.merge([_walkAnimation, _legAnimation]),
              builder: (context, child) {
                final isMovingRight = _walkController.status == AnimationStatus.forward;
                return Transform.translate(
                  offset: Offset(_walkAnimation.value, 0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(isMovingRight ? 1.0 : -1.0, 1.0),
                    child: _buildWalkingPet(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.gapXL),
            // 발자국 트레일
            _buildPawPrints(),
            const SizedBox(height: AppSizes.gapXL),
            // 메시지
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_progressMessage),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL, vertical: AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MingrrLoadingIndicator(
                      size: 18,
                      strokeWidth: 2.5,
                      customColor: _accentColor,
                    ),
                    const SizedBox(width: AppSizes.gapM),
                    Text(
                      _progressMessage,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 서브 메시지
            if (widget.subMessage != null) ...[
              const SizedBox(height: AppSizes.gapM),
              Text(
                widget.subMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 걷는 반려동물 위젯 (SVG 파일 로드 + 동적 색상 적용)
  Widget _buildWalkingPet() {
    // SVG 로드 전에는 로딩 표시
    if (_svgString == null) {
      return SizedBox(
        width: 100,
        height: 80,
        child: Center(
          child: MingrrLoadingIndicator(
            strokeWidth: 2,
            customColor: _accentColor,
          ),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _legAnimation,
      builder: (context, child) {
        // 걷는 모션: 위아래로 살짝 움직임
        final bounceOffset = _legAnimation.value * 15;
        return Transform.translate(
          offset: Offset(0, bounceOffset),
          child: SvgPicture.string(
            _svgString!,
            width: 100,
            height: 80,
          ),
        );
      },
    );
  }
  
  /// 발자국 트레일 위젯
  Widget _buildPawPrints() {
    return AnimatedBuilder(
      animation: _walkAnimation,
      builder: (context, child) {
        final progress = (_walkAnimation.value + 40) / 80; // 0 ~ 1
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final opacity = _calculatePawOpacity(index, progress);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  Icons.pets,
                  size: 16,
                  color: _accentColor.withValues(alpha: 0.6),
                ),
              ),
            );
          }),
        );
      },
    );
  }
  
  /// 발자국 투명도 계산
  double _calculatePawOpacity(int index, double progress) {
    final pawProgress = (progress * 5 - index).clamp(0.0, 1.0);
    if (pawProgress <= 0) return 0.2;
    if (pawProgress >= 1) return 0.4;
    return 0.2 + (pawProgress * 0.6);
  }
}

