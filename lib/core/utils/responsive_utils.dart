/// ============================================================
/// 반응형 유틸리티
/// 
/// MediaQuery 호출을 간소화하고 코드 가독성을 높입니다.
/// Safe Area, 키보드 높이, 화면 크기 관련 유틸리티를 제공합니다.
/// ============================================================

import 'package:flutter/material.dart';

/// 반응형 유틸리티 클래스
/// 
/// 사용 예시:
/// ```dart
/// // Safe Area 하단 패딩
/// ResponsiveUtils.bottomSafeArea(context)
/// 
/// // 키보드 높이
/// ResponsiveUtils.keyboardHeight(context)
/// 
/// // 화면 높이의 70%
/// ResponsiveUtils.heightPercent(context, 0.7)
/// ```
class ResponsiveUtils {
  ResponsiveUtils._();
  
  // ===== Safe Area =====
  
  /// Safe Area 하단 패딩 (홈 인디케이터 영역)
  static double bottomSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;
  
  /// Safe Area 상단 패딩 (노치/다이나믹 아일랜드 영역)
  static double topSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.top;
  
  /// Safe Area 전체 패딩
  static EdgeInsets safeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;
  
  // ===== 키보드 =====
  
  /// 키보드 높이 (키보드가 올라왔을 때의 높이)
  static double keyboardHeight(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;
  
  /// 키보드가 올라와 있는지 여부
  static bool isKeyboardVisible(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;
  
  // ===== 화면 크기 =====
  
  /// 화면 높이
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  
  /// 화면 너비
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  
  /// 화면 높이 비율 (0.0 ~ 1.0)
  /// 
  /// 예: `heightPercent(context, 0.7)` = 화면 높이의 70%
  static double heightPercent(BuildContext context, double percent) =>
      MediaQuery.of(context).size.height * percent;
  
  /// 화면 너비 비율 (0.0 ~ 1.0)
  /// 
  /// 예: `widthPercent(context, 0.5)` = 화면 너비의 50%
  static double widthPercent(BuildContext context, double percent) =>
      MediaQuery.of(context).size.width * percent;
  
  // ===== 복합 유틸리티 =====
  
  /// 바텀시트/다이얼로그용 최대 높이 (화면의 85%)
  static double maxSheetHeight(BuildContext context) =>
      heightPercent(context, 0.85);
  
  /// 컨텐츠 영역 높이 (Safe Area 제외)
  static double contentHeight(BuildContext context) =>
      screenHeight(context) - topSafeArea(context) - bottomSafeArea(context);
  
  /// 하단 패딩 + 추가 간격 (버튼, 입력창 등에 사용)
  static double bottomPaddingWith(BuildContext context, double extra) =>
      bottomSafeArea(context) + extra;
  
  /// 키보드 또는 Safe Area 중 큰 값 (입력 폼에 사용)
  static double bottomInsetOrSafeArea(BuildContext context) {
    final keyboard = keyboardHeight(context);
    final safeArea = bottomSafeArea(context);
    return keyboard > 0 ? keyboard : safeArea;
  }
}
