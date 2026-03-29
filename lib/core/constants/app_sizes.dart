import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 디자인 상수 통합 파일
/// 
/// 포함 클래스:
/// - AppSizes: 크기, 간격, 반경 등
/// - AppOpacity: 투명도 상수
/// - AppShadows: 그림자 프리셋
/// - AppDurations: 애니메이션 시간
/// ============================================================

// ═══════════════════════════════════════════════════════════════
// AppSizes - 크기/간격/반경 상수
// ═══════════════════════════════════════════════════════════════
class AppSizes {
  AppSizes._();

  // ===== 패딩/마진 (7단계: XXS, XS, S, M, L, XL, XXL) =====
  static const double paddingXXS = 2.0;   // 최소 패딩
  static const double paddingXS = 4.0;    // 아이콘 내부
  static const double paddingS = 8.0;     // 기본 패딩
  static const double paddingM = 12.0;    // 중간 패딩
  static const double paddingL = 16.0;    // 큰 패딩
  static const double paddingXL = 24.0;   // 섹션 패딩
  static const double paddingXXL = 32.0;  // 대형 패딩

  // ===== 간격/Gap (7단계: XXS, XS, S, M, L, XL, XXL) =====
  static const double gapXXS = 2.0;   // 최소 간격
  static const double gapXS = 4.0;    // 아이콘-텍스트 간격
  static const double gapS = 8.0;     // 기본 간격
  static const double gapM = 12.0;    // 중간 간격
  static const double gapL = 16.0;    // 큰 간격
  static const double gapXL = 24.0;   // 섹션 간격
  static const double gapXXL = 32.0;  // 대형 간격

  // ===== 아이콘 크기 (7단계: XXS, XS, S, M, L, XL, XXL) =====
  static const double iconXXS = 12.0;  // 배지 내 아이콘
  static const double iconXS = 14.0;   // 필터 칩 아이콘
  static const double iconS = 16.0;    // 작은 아이콘
  static const double iconM = 20.0;    // 기본 아이콘
  static const double iconL = 24.0;    // 큰 아이콘
  static const double iconXL = 32.0;   // 대형 아이콘
  static const double iconXXL = 48.0;  // 특대 아이콘

  // ===== 아바타 크기 (7단계: XXS, XS, S, M, L, XL, XXL) =====
  static const double avatarXXS = 24.0;   // 최소 아바타
  static const double avatarXS = 32.0;    // 채팅 리스트
  static const double avatarS = 40.0;     // 댓글, 리스트
  static const double avatarM = 48.0;     // 카드, 프로필
  static const double avatarL = 80.0;     // 상세 화면
  static const double avatarXL = 120.0;   // 프로필 편집
  static const double avatarXXL = 160.0;  // 대형 프로필

  // ===== 테두리 반경 (4단계: S, M, L, Full) =====
  static const double radiusS = 12.0;     // 태그, 칩, 작은 카드
  static const double radiusM = 14.0;     // 일반 카드, 버튼
  static const double radiusL = 16.0;     // 큰 카드, 바텀시트
  static const double radiusFull = 999.0; // 완전 원형

  // ===== 버튼 높이 (3단계: S, M, L) =====
  static const double buttonHeightS = 32.0;   // 작은 버튼
  static const double buttonHeightM = 44.0;   // 기본 버튼
  static const double buttonHeightL = 48.0;   // 큰 버튼

  // ===== 입력 필드 =====
  static const double inputHeight = 44.0;

  // ===== 썸네일 크기 (5단계: XS, S, M, L, XL) =====
  static const double thumbnailXS = 40.0;   // 최소 썸네일
  static const double thumbnailS = 56.0;    // 작은 썸네일
  static const double thumbnailM = 80.0;    // 중간 썸네일
  static const double thumbnailL = 120.0;   // 큰 썸네일
  static const double thumbnailXL = 200.0;  // 대형 썸네일

  // ===== Elevation (3단계: None, S, M) =====
  static const double elevationNone = 0.0;  // 플랫 디자인
  static const double elevationS = 2.0;     // 카드, 리스트 아이템
  static const double elevationM = 4.0;     // FAB, 모달

  // ===== Border Width (3단계: S, M, L) =====
  static const double borderWidthS = 1.0;   // 일반 테두리
  static const double borderWidthM = 1.5;   // 입력 필드
  static const double borderWidthL = 2.0;   // 강조 테두리

  // ===== 카드 =====
  static const double cardMinHeight = 80.0;

  // ===== 바텀 네비게이션 =====
  static const double bottomNavHeight = 56.0;
  static const double bottomNavIconSize = 22.0;

  // ===== 앱바 =====
  static const double appBarHeight = 56.0;

  // ===== 최대 너비 (반응형) =====
  static const double maxContentWidth = 600.0;
  static const double maxCardWidth = 400.0;

  // ===== 화면 레이아웃 (통일 기준) =====
  static const double screenPaddingH = 16.0;
  static const double sectionGap = 24.0;      // 섹션 간 간격
  static const double cardInnerPadding = 16.0; // 카드 내부 패딩
  static const double listItemGap = 12.0;     // 리스트 아이템 간격

  // ===== 바텀시트 =====
  static const double bottomSheetRadius = 20.0;
  static const double bottomSheetHandleWidth = 40.0;
  static const double bottomSheetHandleHeight = 4.0;
  static const double bottomSheetHandleRadius = bottomSheetHandleHeight / 2;  // 핸들 둥근 모서리
  static const double bottomSheetHandleTop = 12.0;
  static const double bottomSheetHandleBottom = 12.0;
  static const double bottomSheetButtonPaddingH = 16.0;
  static const double bottomSheetButtonPaddingV = 12.0;

  // ===== 로딩 타임아웃 =====
  static const Duration loadingTimeout = Duration(seconds: 15);
  static const Duration loadingTimeoutShort = Duration(seconds: 10);
  static const Duration loadingTimeoutLong = Duration(seconds: 30);
}

// ═══════════════════════════════════════════════════════════════
// AppOpacity - 투명도 상수 (숫자 기반 명명)
// ═══════════════════════════════════════════════════════════════
class AppOpacity {
  AppOpacity._();

  /// 5% 투명도 (그림자, 미세 배경)
  static const double o05 = 0.05;

  /// 10% 투명도 (테두리, 약한 배경)
  static const double o10 = 0.1;

  /// 15% 투명도 (약한 강조)
  static const double o15 = 0.15;

  /// 20% 투명도 (오버레이, 중간 강조)
  static const double o20 = 0.2;

  /// 30% 투명도 (강한 강조)
  static const double o30 = 0.3;

  /// 50% 투명도 (반투명 오버레이)
  static const double o50 = 0.5;

  /// 70% 투명도 (진한 오버레이)
  static const double o70 = 0.7;

  /// 80% 투명도 (거의 불투명)
  static const double o80 = 0.8;
}

// ═══════════════════════════════════════════════════════════════
// AppShadows - 그림자 프리셋 (다크모드 대응)
// ═══════════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  /// 작은 그림자 (카드, 리스트 아이템)
  static List<BoxShadow> shadowS(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// 중간 그림자 (모달, FAB)
  static List<BoxShadow> shadowM(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// 큰 그림자 (바텀시트, 오버레이)
  static List<BoxShadow> shadowL(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
      blurRadius: 20,
      offset: const Offset(0, -5),
    ),
  ];

  /// 그림자 없음
  static List<BoxShadow> get none => [];
}

