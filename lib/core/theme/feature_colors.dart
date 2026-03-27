import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 기능별 색상 시스템 (ThemeExtension)
/// 
/// Material 3 ColorScheme을 확장하여 앱의 기능별 색상을 관리합니다.
/// 라이트/다크 모드에서 자동으로 적절한 색상이 적용됩니다.
/// 
/// 사용법:
/// ```dart
/// final features = Theme.of(context).extension<FeatureColors>()!;
/// Container(color: features.datingContainer);
/// Icon(Icons.favorite, color: features.dating);
/// ```
/// ============================================================
@immutable
class FeatureColors extends ThemeExtension<FeatureColors> {
  const FeatureColors({
    // 데이팅
    required this.dating,
    required this.datingContainer,
    required this.onDating,
    // 마켓
    required this.market,
    required this.marketContainer,
    required this.onMarket,
    // 소셜 (소모임 + 커뮤니티 게시판)
    required this.social,
    required this.socialContainer,
    required this.onSocial,
    // 건강
    required this.health,
    required this.healthContainer,
    required this.onHealth,
    // 산책
    required this.walk,
    required this.walkContainer,
    required this.onWalk,
    // 채팅
    required this.chat,
    required this.chatContainer,
    required this.onChat,
    // 교배
    required this.breeding,
    required this.breedingContainer,
    required this.onBreeding,
    // 상태 색상
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    // 그라데이션
    required this.warmGradient,
    required this.primaryGradient,
  });

  // ===== 데이팅 (로즈 핑크) =====
  final Color dating;
  final Color datingContainer;
  final Color onDating;

  // ===== 마켓 (인디고) =====
  final Color market;
  final Color marketContainer;
  final Color onMarket;

  // ===== 소셜 (틸) - 소모임/커뮤니티 게시판 공통 =====
  final Color social;
  final Color socialContainer;
  final Color onSocial;

  // ===== 건강 (블루) =====
  final Color health;
  final Color healthContainer;
  final Color onHealth;

  // ===== 산책 (그린) =====
  final Color walk;
  final Color walkContainer;
  final Color onWalk;

  // ===== 채팅 (앰버/오렌지) =====
  final Color chat;
  final Color chatContainer;
  final Color onChat;

  // ===== 교배 (퍼플) =====
  final Color breeding;
  final Color breedingContainer;
  final Color onBreeding;

  // ===== 상태 색상 =====
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  // ===== 그라데이션 =====
  final LinearGradient warmGradient;
  final LinearGradient primaryGradient;

  // ===== 라이트 테마 색상 =====
  // V3 리팩토링: 모든 기능별 색상을 동일한 accent(코럴)로 통합
  static const light = FeatureColors(
    // 데이팅 → 통합 코럴
    dating: Color(0xFFFF8A65),
    datingContainer: Color(0xFFF5F5F5),
    onDating: Colors.white,
    // 마켓 → 통합 코럴
    market: Color(0xFFFF8A65),
    marketContainer: Color(0xFFF5F5F5),
    onMarket: Colors.white,
    // 소셜 → 통합 코럴
    social: Color(0xFFFF8A65),
    socialContainer: Color(0xFFF5F5F5),
    onSocial: Colors.white,
    // 건강 → 통합 코럴
    health: Color(0xFFFF8A65),
    healthContainer: Color(0xFFF5F5F5),
    onHealth: Colors.white,
    // 산책 → 통합 코럴
    walk: Color(0xFFFF8A65),
    walkContainer: Color(0xFFF5F5F5),
    onWalk: Colors.white,
    // 채팅 → 통합 코럴
    chat: Color(0xFFFF8A65),
    chatContainer: Color(0xFFF5F5F5),
    onChat: Colors.white,
    // 교배 → 통합 코럴
    breeding: Color(0xFFFF8A65),
    breedingContainer: Color(0xFFF5F5F5),
    onBreeding: Colors.white,
    // 상태 색상 (독립 유지)
    success: Color(0xFF66BB6A),
    successContainer: Color(0xFFE8F5E9),
    warning: Color(0xFFFFA726),
    warningContainer: Color(0xFFFFF3E0),
    info: Color(0xFF42A5F5),
    infoContainer: Color(0xFFE3F2FD),
    // 그라데이션
    warmGradient: LinearGradient(
      colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ===== 다크 테마 색상 =====
  // V3 리팩토링: 모든 기능별 색상을 동일한 accent(코럴)로 통합
  static const dark = FeatureColors(
    dating: Color(0xFFFFAB91),
    datingContainer: Color(0xFF1E1E1E),
    onDating: Colors.white,
    market: Color(0xFFFFAB91),
    marketContainer: Color(0xFF1E1E1E),
    onMarket: Colors.white,
    social: Color(0xFFFFAB91),
    socialContainer: Color(0xFF1E1E1E),
    onSocial: Colors.white,
    health: Color(0xFFFFAB91),
    healthContainer: Color(0xFF1E1E1E),
    onHealth: Colors.white,
    walk: Color(0xFFFFAB91),
    walkContainer: Color(0xFF1E1E1E),
    onWalk: Colors.white,
    chat: Color(0xFFFFAB91),
    chatContainer: Color(0xFF1E1E1E),
    onChat: Colors.white,
    breeding: Color(0xFFFFAB91),
    breedingContainer: Color(0xFF1E1E1E),
    onBreeding: Colors.white,
    // 상태 색상 (다크모드)
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1D3D1F),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF5D3A1A),
    info: Color(0xFF64B5F6),
    infoContainer: Color(0xFF1A3A5C),
    // 그라데이션 (다크모드)
    warmGradient: LinearGradient(
      colors: [Color(0xFF1E1E1E), Color(0xFF171717)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF5D4A00), Color(0xFF3D3D00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  FeatureColors copyWith({
    Color? dating,
    Color? datingContainer,
    Color? onDating,
    Color? market,
    Color? marketContainer,
    Color? onMarket,
    Color? social,
    Color? socialContainer,
    Color? onSocial,
    Color? health,
    Color? healthContainer,
    Color? onHealth,
    Color? walk,
    Color? walkContainer,
    Color? onWalk,
    Color? chat,
    Color? chatContainer,
    Color? onChat,
    Color? breeding,
    Color? breedingContainer,
    Color? onBreeding,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    LinearGradient? warmGradient,
    LinearGradient? primaryGradient,
  }) {
    return FeatureColors(
      dating: dating ?? this.dating,
      datingContainer: datingContainer ?? this.datingContainer,
      onDating: onDating ?? this.onDating,
      market: market ?? this.market,
      marketContainer: marketContainer ?? this.marketContainer,
      onMarket: onMarket ?? this.onMarket,
      social: social ?? this.social,
      socialContainer: socialContainer ?? this.socialContainer,
      onSocial: onSocial ?? this.onSocial,
      health: health ?? this.health,
      healthContainer: healthContainer ?? this.healthContainer,
      onHealth: onHealth ?? this.onHealth,
      walk: walk ?? this.walk,
      walkContainer: walkContainer ?? this.walkContainer,
      onWalk: onWalk ?? this.onWalk,
      chat: chat ?? this.chat,
      chatContainer: chatContainer ?? this.chatContainer,
      onChat: onChat ?? this.onChat,
      breeding: breeding ?? this.breeding,
      breedingContainer: breedingContainer ?? this.breedingContainer,
      onBreeding: onBreeding ?? this.onBreeding,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      warmGradient: warmGradient ?? this.warmGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  FeatureColors lerp(ThemeExtension<FeatureColors>? other, double t) {
    if (other is! FeatureColors) return this;
    return FeatureColors(
      dating: Color.lerp(dating, other.dating, t)!,
      datingContainer: Color.lerp(datingContainer, other.datingContainer, t)!,
      onDating: Color.lerp(onDating, other.onDating, t)!,
      market: Color.lerp(market, other.market, t)!,
      marketContainer: Color.lerp(marketContainer, other.marketContainer, t)!,
      onMarket: Color.lerp(onMarket, other.onMarket, t)!,
      social: Color.lerp(social, other.social, t)!,
      socialContainer: Color.lerp(socialContainer, other.socialContainer, t)!,
      onSocial: Color.lerp(onSocial, other.onSocial, t)!,
      health: Color.lerp(health, other.health, t)!,
      healthContainer: Color.lerp(healthContainer, other.healthContainer, t)!,
      onHealth: Color.lerp(onHealth, other.onHealth, t)!,
      walk: Color.lerp(walk, other.walk, t)!,
      walkContainer: Color.lerp(walkContainer, other.walkContainer, t)!,
      onWalk: Color.lerp(onWalk, other.onWalk, t)!,
      chat: Color.lerp(chat, other.chat, t)!,
      chatContainer: Color.lerp(chatContainer, other.chatContainer, t)!,
      onChat: Color.lerp(onChat, other.onChat, t)!,
      breeding: Color.lerp(breeding, other.breeding, t)!,
      breedingContainer: Color.lerp(breedingContainer, other.breedingContainer, t)!,
      onBreeding: Color.lerp(onBreeding, other.onBreeding, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      warmGradient: LinearGradient.lerp(warmGradient, other.warmGradient, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
    );
  }
}

/// FeatureColors 확장 메서드 - 편의성을 위한 getter
extension FeatureColorsExtension on BuildContext {
  /// 현재 테마의 FeatureColors를 가져옵니다.
  FeatureColors get features => Theme.of(this).extension<FeatureColors>()!;
  
  /// 현재 테마의 ColorScheme을 가져옵니다.
  ColorScheme get colors => Theme.of(this).colorScheme;
  
  /// 현재 테마가 다크모드인지 확인합니다.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
