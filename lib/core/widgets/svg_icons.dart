import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ============================================================
/// SVG 아이콘 관리 클래스
/// 
/// 앱에서 사용하는 모든 SVG 아이콘을 중앙에서 관리합니다.
/// 동적 색상 적용을 지원합니다.
/// ============================================================

/// SVG 아이콘 경로 상수
class SvgAssets {
  SvgAssets._();
  
  // 아이콘
  static const String logo = 'assets/icons/logo.svg';
  static const String logoText = 'assets/icons/logo_text.svg';
  static const String defaultPet = 'assets/icons/default_pet.svg';
  static const String pawPrint = 'assets/icons/paw_print.svg';
  static const String walkingDog = 'assets/icons/walking_dog.svg';
  
  // 빈 상태 이미지
  static const String emptyPet = 'assets/images/empty_pet.svg';
  static const String emptyChat = 'assets/images/empty_chat.svg';
  static const String emptyMessage = 'assets/images/empty_message.svg';
  static const String emptyNotification = 'assets/images/empty_notification.svg';
  static const String emptySearch = 'assets/images/empty_search.svg';
  static const String emptyList = 'assets/images/empty_list.svg';
  static const String emptyHeart = 'assets/images/empty_heart.svg';
  static const String emptyMatch = 'assets/images/empty_match.svg';
  static const String emptyTransaction = 'assets/images/empty_transaction.svg';
  static const String emptyWishlist = 'assets/images/empty_wishlist.svg';
  static const String emptyGroup = 'assets/images/empty_group.svg';
  static const String emptySchedule = 'assets/images/empty_schedule.svg';
  
  // 에러 상태 이미지
  static const String errorLocation = 'assets/images/error_location.svg';
  static const String errorNetwork = 'assets/images/error_network.svg';
  static const String errorServer = 'assets/images/error_server.svg';
  static const String errorDatabase = 'assets/images/error_database.svg';
  static const String errorPermission = 'assets/images/error_permission.svg';
  
  // 온보딩 이미지
  static const String onboarding1 = 'assets/images/onboarding_1.svg';
  static const String onboarding2 = 'assets/images/onboarding_2.svg';
  static const String onboarding3 = 'assets/images/onboarding_3.svg';
  static const String onboarding4 = 'assets/images/onboarding_4.svg';
}

/// 동적 색상을 지원하는 SVG 아이콘 위젯
class MingrrSvgIcon extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const MingrrSvgIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  State<MingrrSvgIcon> createState() => _MingrrSvgIconState();
}

class _MingrrSvgIconState extends State<MingrrSvgIcon> {
  String? _svgString;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(MingrrSvgIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath || 
        oldWidget.color != widget.color) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    try {
      final rawSvg = await rootBundle.loadString(widget.assetPath);
      
      if (widget.color != null) {
        // 색상 치환
        final colorHex = '#${widget.color!.value.toRadixString(16).substring(2).toUpperCase()}';
        final lightColorHex = _getLighterColor(widget.color!);
        final darkColorHex = _getDarkerColor(widget.color!);
        
        final coloredSvg = rawSvg
            .replaceAll('#FF9800', colorHex)
            .replaceAll('#FFB74D', lightColorHex)
            .replaceAll('#E65100', darkColorHex)
            .replaceAll('#4CAF50', colorHex); // 로고 배경색도 변경
        
        if (mounted) {
          setState(() => _svgString = coloredSvg);
        }
      } else {
        if (mounted) {
          setState(() => _svgString = rawSvg);
        }
      }
    } catch (e) {
      debugPrint('SVG 로드 실패: ${widget.assetPath} - $e');
    }
  }

  String _getLighterColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0));
    return '#${lighter.toColor().value.toRadixString(16).substring(2).toUpperCase()}';
  }

  String _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0));
    return '#${darker.toColor().value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    if (_svgString == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    return SvgPicture.string(
      _svgString!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

/// 기본 반려동물 프로필 아이콘
class DefaultPetIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DefaultPetIcon({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrSvgIcon(
      assetPath: SvgAssets.defaultPet,
      width: size,
      height: size,
      color: color,
    );
  }
}

/// 발바닥 아이콘
class PawPrintIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const PawPrintIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrSvgIcon(
      assetPath: SvgAssets.pawPrint,
      width: size,
      height: size,
      color: color,
    );
  }
}

/// 앱 로고 아이콘
class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogoIcon({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrSvgIcon(
      assetPath: SvgAssets.logo,
      width: size,
      height: size,
      color: color,
    );
  }
}

/// 앱 로고 + 텍스트
class AppLogoWithText extends StatelessWidget {
  final double height;

  const AppLogoWithText({
    super.key,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrSvgIcon(
      assetPath: SvgAssets.logoText,
      height: height,
    );
  }
}
