// ============================================================
// 평가 시스템 상수
// 
// 평가 관련 모든 상수를 중앙 관리
// ============================================================

class RatingConstants {
  RatingConstants._();

  // ===== 평가 점수 =====
  
  /// 최소 평점
  static const int minScore = 1;
  
  /// 최대 평점
  static const int maxScore = 5;
  
  /// 기본 평점 (평가 없을 때)
  static const int defaultScore = 3;

  // ===== 평가 정책 =====
  
  /// 동일 대상 재평가 쿨다운 기간 (일)
  static const int cooldownDays = 30;
  
  /// 평가 만료 기간 (일) - 활동 완료 후 이 기간 내에만 평가 가능
  static const int expirationDays = 14;

  // ===== 이상 탐지 =====
  
  /// 1시간 내 최대 평가 횟수
  static const int maxRatingsPerHour = 5;
  
  /// 하루 최대 평가 횟수
  static const int maxRatingsPerDay = 20;

  // ===== 평가 가중치 =====
  
  /// 최근 평가 가중치 기준 기간 (일)
  static const int recentRatingDays = 30;
  
  /// 최근 평가 가중치 배율
  static const double recentRatingWeight = 1.2;
  
  /// 인증 완료 사용자 평가 가중치
  static const double verifiedUserWeight = 1.2;
  
  /// 높은 꼬순내 지수 사용자 평가 가중치
  static const double highScoreUserWeight = 1.1;
  
  /// 높은 꼬순내 지수 기준 점수
  static const int highScoreThreshold = 70;
  
  /// 다수 평가 작성자 가중치
  static const double frequentRaterWeight = 1.05;
  
  /// 다수 평가 작성 기준 개수
  static const int frequentRaterThreshold = 50;

  // ===== UI 표시 =====
  
  /// 태그 최대 표시 개수
  static const int maxDisplayTags = 3;
  
  /// 평가 개수 보너스 구간
  static const List<RatingCountBonus> countBonuses = [
    RatingCountBonus(threshold: 50, bonus: 10),
    RatingCountBonus(threshold: 30, bonus: 8),
    RatingCountBonus(threshold: 15, bonus: 6),
    RatingCountBonus(threshold: 5, bonus: 4),
    RatingCountBonus(threshold: 3, bonus: 2),
  ];

  // ===== 상호 평가 =====
  
  /// 상호 평가 대기 기간 (일) - 이 기간 후 자동 공개
  static const int mutualRatingWaitDays = 14;
}

/// 평가 개수 보너스 구간
class RatingCountBonus {
  final int threshold;
  final int bonus;

  const RatingCountBonus({
    required this.threshold,
    required this.bonus,
  });
}
