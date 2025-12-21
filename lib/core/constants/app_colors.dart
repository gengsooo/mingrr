import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 앱 컬러 시스템
/// 포근한 노란톤을 기반으로 한 따뜻하고 귀여운 색상 팔레트
/// ============================================================
class AppColors {
  AppColors._(); // 인스턴스화 방지

  // ===== 메인 컬러 (Primary) =====
  /// 메인 노란색 - 앱의 주요 색상
  static const Color primary = Color(0xFFFFD54F);
  
  /// 진한 노란색 - 강조용
  static const Color primaryDark = Color(0xFFFFC107);
  
  /// 연한 노란색 - 배경용
  static const Color primaryLight = Color(0xFFFFF8E1);
  
  /// 매우 연한 노란색 - 카드 배경
  static const Color primaryPale = Color(0xFFFFFDE7);

  // ===== 보조 컬러 (Secondary) =====
  /// 코랄 오렌지 - 액센트 색상
  static const Color accent = Color(0xFFFF8A65);
  
  /// 연한 코랄 - 하이라이트
  static const Color accentLight = Color(0xFFFFCCBC);
  
  /// 민트 그린 - 성공/완료 상태
  static const Color mint = Color(0xFF81C784);
  
  /// 연한 민트 - 배경용
  static const Color mintLight = Color(0xFFE8F5E9);

  // ===== 중성 컬러 (Neutral) =====
  /// 진한 텍스트 색상
  static const Color textPrimary = Color(0xFF3E2723);
  
  /// 보조 텍스트 색상
  static const Color textSecondary = Color(0xFF795548);
  
  /// 힌트/비활성 텍스트
  static const Color textHint = Color(0xFFBCAAA4);
  
  /// 구분선 색상
  static const Color divider = Color(0xFFEEE0D5);
  
  /// 배경 색상
  static const Color background = Color(0xFFFFFBF5);
  
  /// 카드 배경
  static const Color cardBackground = Colors.white;
  
  /// 비활성 상태
  static const Color disabled = Color(0xFFD7CCC8);

  // ===== 상태 컬러 (Status) =====
  /// 에러/경고
  static const Color error = Color(0xFFE57373);
  
  /// 성공
  static const Color success = Color(0xFF81C784);
  
  /// 정보
  static const Color info = Color(0xFF64B5F6);
  
  /// 경고
  static const Color warning = Color(0xFFFFB74D);

  // ===== 기능별 컬러 =====
  /// 데이팅 - 핑크 계열
  static const Color dating = Color(0xFFFF8A80);
  
  /// 산책 - 그린 계열
  static const Color walk = Color(0xFF81C784);
  
  /// 건강 - 블루 계열
  static const Color health = Color(0xFF64B5F6);
  
  /// 마켓 - 오렌지 계열
  static const Color market = Color(0xFFFFB74D);
  
  /// 교배 - 퍼플 계열
  static const Color breeding = Color(0xFFCE93D8);
  
  /// 커뮤니티 - 틸 계열
  static const Color community = Color(0xFF4DB6AC);

  // ===== 그라데이션 =====
  /// 메인 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 따뜻한 그라데이션
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFE082), Color(0xFFFFCC80)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
