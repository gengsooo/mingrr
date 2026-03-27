import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 앱 텍스트 스타일 시스템 (V2)
/// 
/// 17개 핵심 스타일로 단순화하여 일관성과 유지보수성을 향상시킵니다.
/// BuildContext를 통해 테마 색상에 접근하여 라이트/다크 모드를 자동 지원합니다.
/// 
/// 사용법:
/// ```dart
/// Text('제목', style: AppTextStyles.headlineSmall(context));
/// Text('본문', style: AppTextStyles.bodyMedium(context));
/// Text('강조', style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w600));
/// Text('커스텀 색상', style: AppTextStyles.bodyMedium(context).withColor(Colors.red));
/// ```
/// ============================================================
class AppTextStyles {
  AppTextStyles._();

  // ═══════════════════════════════════════════════════════════════
  // 대형 디스플레이 (22-36px) - 점수, 앱타이틀, 대형 숫자
  // ═══════════════════════════════════════════════════════════════
  
  /// 28px, Bold - 대형 점수, 앱 타이틀
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 24px, Bold - 중형 점수
  static TextStyle displayMedium(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 22px, Bold - 소형 점수, 대형 숫자
  static TextStyle displaySmall(BuildContext context) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ═══════════════════════════════════════════════════════════════
  // 제목 (17-22px) - 화면/섹션 제목
  // ═══════════════════════════════════════════════════════════════
  
  /// 22px, Bold - 대형 제목 (화면 타이틀)
  static TextStyle headlineLarge(BuildContext context) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 20px, SemiBold - 중형 제목
  static TextStyle headlineMedium(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 17px, SemiBold - 소형 제목 (섹션 타이틀)
  static TextStyle headlineSmall(BuildContext context) => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ═══════════════════════════════════════════════════════════════
  // 타이틀 (14-16px) - 카드/리스트 제목, 버튼
  // ═══════════════════════════════════════════════════════════════
  
  /// 16px, SemiBold - 대형 타이틀 (버튼, 카드 가격)
  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 15px, Medium - 중형 타이틀 (카드 제목, 리스트 제목)
  static TextStyle titleMedium(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 14px, Medium - 소형 타이틀
  static TextStyle titleSmall(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ═══════════════════════════════════════════════════════════════
  // 본문 (13-15px) - 일반 텍스트
  // ═══════════════════════════════════════════════════════════════
  
  /// 15px, Regular - 대형 본문
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 14px, Regular - 중형 본문 (기본)
  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 13px, Regular - 소형 본문
  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ═══════════════════════════════════════════════════════════════
  // 라벨 (11-13px) - 태그, 배지, 메타 정보
  // ═══════════════════════════════════════════════════════════════
  
  /// 13px, Medium - 대형 라벨
  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 12px, Medium - 중형 라벨
  static TextStyle labelMedium(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// 11px, Medium - 소형 라벨 (배지, 메타)
  static TextStyle labelSmall(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ═══════════════════════════════════════════════════════════════
  // 캡션 (11-12px) - 보조 텍스트, 힌트, 타임스탬프
  // ═══════════════════════════════════════════════════════════════
  
  /// 12px, Regular, 보조색상 - 캡션, 타임스탬프
  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// 11px, Regular, 보조색상 - 소형 캡션
  static TextStyle captionSmall(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// TextStyle 확장 메서드 - 스타일 변경 편의 기능
extension TextStyleExtension on TextStyle {
  /// 색상만 변경
  TextStyle withColor(Color color) => copyWith(color: color);
  
  /// 굵기만 변경
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  
  /// 크기만 변경
  TextStyle withSize(double size) => copyWith(fontSize: size);
  
  /// 높이 설정
  TextStyle withHeight(double height) => copyWith(height: height);
  
  /// 밑줄 추가
  TextStyle withUnderline() => copyWith(decoration: TextDecoration.underline);
}
