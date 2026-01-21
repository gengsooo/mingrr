/// ============================================================
/// MINGRR 앱 사이즈 상수
/// 일관된 간격, 크기, 반경 등을 정의하여 디자인 일관성 유지
/// ============================================================
class AppSizes {
  AppSizes._();

  // ===== 패딩/마진 =====
  static const double paddingXXS = 2.0;
  static const double paddingXS = 4.0;
  static const double paddingSM = 6.0;   // XS와 S 사이
  static const double paddingS = 8.0;
  static const double paddingMS = 10.0;  // S와 M 사이
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // ===== 간격 (Gap) - SizedBox용 =====
  static const double gapXXS = 2.0;   // 최소 간격
  static const double gapXS = 4.0;    // 아이콘-텍스트 간격
  static const double gapSM = 6.0;    // XS와 S 사이
  static const double gapS = 8.0;     // 기본 간격
  static const double gapMS = 10.0;   // S와 M 사이
  static const double gapM = 12.0;    // 중간 간격
  static const double gapL = 16.0;    // 큰 간격
  static const double gapLL = 20.0;   // L과 XL 사이
  static const double gapXL = 24.0;   // 섹션 간격
  static const double gapXXL = 32.0;  // 대형 간격

    // ===== 아이콘 크기 =====
  static const double iconXXS = 12.0;  // 배지 내 아이콘
  static const double iconXS = 14.0;   // 필터 칩 아이콘
  static const double iconS = 16.0;    // 작은 아이콘
  static const double iconSM = 18.0;   // S와 M 사이
  static const double iconM = 20.0;    // 기본 아이콘
  static const double iconML = 22.0;   // M과 L 사이
  static const double iconL = 24.0;    // 큰 아이콘
  static const double iconXL = 32.0;   // 대형 아이콘
  static const double iconXXL = 48.0;  // 특대 아이콘
  static const double iconHuge = 64.0; // 초대형 아이콘

    // ===== 아바타/프로필 이미지 크기 =====
  static const double avatarXS = 32.0;
  static const double avatarS = 40.0;
  static const double avatarM = 56.0;
  static const double avatarL = 80.0;
  static const double avatarXL = 120.0;

  // ===== 테두리 반경 (동글동글한 느낌) =====
  static const double radiusXXS = 4.0;  // 태그, 작은 뱃지
  static const double radiusXS = 8.0;   // 작은 카드, 칩
  static const double radiusS = 12.0;   // 일반 카드, 버튼
  static const double radiusM = 16.0;   // 중간 카드, 입력 필드
  static const double radiusL = 20.0;   // 큰 카드, 바텀시트
  static const double radiusXL = 24.0;  // 대형 컨테이너
  static const double radiusXXL = 32.0; // 특수 용도
  static const double radiusFull = 999.0; // 완전 원형

  // ===== 버튼 높이 =====
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // ===== 카드 크기 =====
  static const double cardElevation = 2.0;
  static const double cardMinHeight = 80.0;

  // ===== 입력 필드 =====
  static const double inputHeight = 52.0;
  static const double inputBorderWidth = 1.5;

  // ===== 바텀 네비게이션 =====
  static const double bottomNavHeight = 80.0;
  static const double bottomNavIconSize = 26.0;

  // ===== 앱바 =====
  static const double appBarHeight = 56.0;

  // ===== 이미지 =====
  static const double thumbnailS = 60.0;
  static const double thumbnailM = 100.0;
  static const double thumbnailL = 150.0;

  // ===== 최대 너비 (반응형) =====
  static const double maxContentWidth = 600.0;
  static const double maxCardWidth = 400.0;

  // ===== 바텀시트 =====
  static const double bottomSheetRadius = 20.0;
  static const double bottomSheetHandleWidth = 40.0;
  static const double bottomSheetHandleHeight = 4.0;
  static const double bottomSheetHandleTop = 16.0;
  static const double bottomSheetHandleBottom = 12.0;
  
  // 바텀시트 버튼 영역 패딩 (키보드 대응 바텀시트용)
  static const double bottomSheetButtonPaddingH = 20.0;
  static const double bottomSheetButtonPaddingV = 16.0;

  // ===== 로딩 타임아웃 =====
  static const Duration loadingTimeout = Duration(seconds: 15);
  static const Duration loadingTimeoutShort = Duration(seconds: 10);
  static const Duration loadingTimeoutLong = Duration(seconds: 30);
}
