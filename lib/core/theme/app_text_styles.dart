import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 앱 텍스트 스타일 시스템
/// 
/// 자주 사용되는 텍스트 스타일을 공통화하여 일관성과 유지보수성을 향상시킵니다.
/// BuildContext를 통해 테마 색상에 접근하여 라이트/다크 모드를 자동 지원합니다.
/// 
/// 사용법:
/// ```dart
/// Text('제목', style: AppTextStyles.title(context));
/// Text('본문', style: AppTextStyles.body(context));
/// Text('힌트', style: AppTextStyles.hint(context));
/// ```
/// ============================================================
class AppTextStyles {
  AppTextStyles._(); // 인스턴스화 방지

  // ===== 제목 스타일 =====
  
  /// 대형 제목 (24px, Bold)
  static TextStyle headlineLarge(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 중형 제목 (20px, SemiBold)
  static TextStyle headlineMedium(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 소형 제목 (18px, SemiBold)
  static TextStyle headlineSmall(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 타이틀 스타일 =====
  
  /// 대형 타이틀 (16px, SemiBold)
  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 중형 타이틀 (14px, SemiBold) - 섹션 타이틀에 주로 사용
  static TextStyle titleMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 소형 타이틀 (13px, Medium)
  static TextStyle titleSmall(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 본문 스타일 =====
  
  /// 대형 본문 (16px, Regular)
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 중형 본문 (14px, Regular) - 기본 본문 텍스트
  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 소형 본문 (13px, Regular)
  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 보조 텍스트 스타일 =====
  
  /// 보조 텍스트 (13px, onSurfaceVariant) - 부가 설명에 사용
  static TextStyle secondary(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 보조 텍스트 소형 (12px, onSurfaceVariant)
  static TextStyle secondarySmall(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ===== 힌트/캡션 스타일 =====
  
  /// 힌트 텍스트 (12px, outlineVariant) - 플레이스홀더, 비활성 텍스트
  static TextStyle hint(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.outlineVariant,
  );

  /// 캡션 (11px, onSurfaceVariant) - 타임스탬프, 메타 정보
  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ===== 라벨 스타일 =====
  
  /// 대형 라벨 (14px, Medium)
  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 중형 라벨 (12px, Medium)
  static TextStyle labelMedium(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 소형 라벨 (11px, Medium)
  static TextStyle labelSmall(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 버튼 스타일 =====
  
  /// 버튼 텍스트 (16px, SemiBold)
  static TextStyle button(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  /// 소형 버튼 텍스트 (14px, Medium)
  static TextStyle buttonSmall(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  // ===== 특수 스타일 =====
  
  /// 에러 텍스트 (13px, error color)
  static TextStyle error(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.error,
  );

  /// 링크 텍스트 (14px, primary color)
  static TextStyle link(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.primary,
  );

  /// 가격 텍스트 (18px, Bold)
  static TextStyle price(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 배지 텍스트 (10px, Medium)
  static TextStyle badge(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  // ===== 카드용 스타일 =====
  
  /// 카드 제목 (15px, SemiBold)
  static TextStyle cardTitle(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 카드 부제목 (13px, Regular)
  static TextStyle cardSubtitle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 카드 메타 정보 (11px, onSurfaceVariant)
  static TextStyle cardMeta(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 카드 가격 (16px, Bold)
  static TextStyle cardPrice(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 리스트용 스타일 =====
  
  /// 리스트 제목 (15px, Medium)
  static TextStyle listTitle(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 리스트 부제목 (13px, onSurfaceVariant)
  static TextStyle listSubtitle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 리스트 트레일링 (12px, onSurfaceVariant)
  static TextStyle listTrailing(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ===== 배지/태그용 스타일 =====
  
  /// 배지 텍스트 소형 (9px, Medium)
  static TextStyle badgeSmall(BuildContext context) => TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  /// 태그 텍스트 (12px, Medium)
  static TextStyle tag(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 태그 텍스트 소형 (11px, Medium)
  static TextStyle tagSmall(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 오버레이용 스타일 (이미지 위 텍스트) =====
  
  /// 오버레이 제목 (16px, SemiBold, 흰색)
  static TextStyle overlayTitle(BuildContext context) => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// 오버레이 부제목 (13px, Regular, 흰색 70%)
  static TextStyle overlaySubtitle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.7),
  );

  /// 오버레이 메타 (11px, Medium, 흰색)
  static TextStyle overlayMeta(BuildContext context) => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // ===== 숫자/통계용 스타일 =====
  
  /// 대형 숫자 (24px, Bold)
  static TextStyle numberLarge(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 중형 숫자 (18px, SemiBold)
  static TextStyle numberMedium(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 소형 숫자 (14px, Medium)
  static TextStyle numberSmall(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 채팅용 스타일 =====
  
  /// 채팅 메시지 (14px, Regular)
  static TextStyle chatMessage(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
    height: 1.4,
  );

  /// 채팅 시간 (10px, onSurfaceVariant)
  static TextStyle chatTime(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 채팅 발신자 (12px, Medium)
  static TextStyle chatSender(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ===== 폼용 스타일 =====
  
  /// 폼 라벨 (14px, Medium)
  static TextStyle formLabel(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 폼 힌트 (13px, onSurfaceVariant)
  static TextStyle formHint(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 폼 헬퍼 텍스트 (12px, onSurfaceVariant)
  static TextStyle formHelper(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 폼 에러 텍스트 (12px, error)
  static TextStyle formError(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.error,
  );

  // ===== 섹션용 스타일 =====
  
  /// 섹션 제목 (16px, SemiBold)
  static TextStyle sectionTitle(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 섹션 부제목 (13px, onSurfaceVariant)
  static TextStyle sectionSubtitle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 섹션 더보기 (13px, primary)
  static TextStyle sectionMore(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.primary,
  );

  // ===== 필터용 스타일 =====
  
  /// 필터 타이틀 (12px, Bold) - 필터 섹션 제목
  static TextStyle filterTitle(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 필터 칩 텍스트 (11px, Regular) - 필터 칩 내부 텍스트
  static TextStyle filterChip(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 필터 칩 선택됨 (11px, SemiBold) - 선택된 필터 칩
  static TextStyle filterChipSelected(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ===== 점수/통계용 스타일 =====
  
  /// 대형 점수 (36px, Bold) - 꼬순내 점수 등
  static TextStyle scoreLarge(BuildContext context) => TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 중형 점수 (28px, Bold)
  static TextStyle scoreMedium(BuildContext context) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 소형 점수 (20px, SemiBold)
  static TextStyle scoreSmall(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ===== 로그인/온보딩용 스타일 =====
  
  /// 앱 타이틀 (36px, Bold) - 로그인 화면 앱 이름
  static TextStyle appTitle(BuildContext context) => TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 앱 슬로건 (14px, Regular) - 로그인 화면 슬로건
  static TextStyle appSlogan(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ===== 알림용 스타일 =====
  
  /// 알림 제목 (13px, Medium)
  static TextStyle notificationTitle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 알림 시간 (12px, onSurfaceVariant)
  static TextStyle notificationTime(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// TextStyle 확장 메서드 - 색상 변경 편의 기능
extension TextStyleExtension on TextStyle {
  /// 색상만 변경
  TextStyle withColor(Color color) => copyWith(color: color);
  
  /// 크기만 변경
  TextStyle withSize(double size) => copyWith(fontSize: size);
  
  /// 굵기만 변경
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  
  /// 높이 설정
  TextStyle withHeight(double height) => copyWith(height: height);
}
