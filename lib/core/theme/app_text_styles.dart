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
