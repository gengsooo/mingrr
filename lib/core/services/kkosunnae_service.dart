import 'dart:math';
import '../../models/user_model.dart';
import '../../models/rating_model.dart';
import 'firebase_service.dart';

/// ============================================================
/// 꼬순내 지수 서비스
/// 사용자 신뢰도/평판 점수 계산 (당근마켓 매너온도와 유사)
/// 
/// 점수 배분 (100점 만점):
/// - 평판 점수: 40점 (평가 점수 30점 + 평가 개수 보너스 10점)
/// - 활동 점수: 25점 (매칭/산책/거래/소모임)
/// - 신뢰도 점수: 20점 (인증/프로필/계정연령)
/// - 앱 활성도: 15점 (접속빈도/응답률)
/// - 감점 요소: 최대 -15점 (신고/노쇼)
/// ============================================================

class KkosunnaeService {
  static final _firebase = FirebaseService();

  // ===== 등급 정의 =====
  static const String gradeMaster = '꼬순내 마스터';
  static const String gradeVeteran = '꼬순내 베테랑';
  static const String gradeFriend = '꼬순내 친구';
  static const String gradeGrowing = '꼬순내 성장중';
  static const String gradeNewbie = '꼬순내 새싹';

  /// 꼬순내 지수 계산 (전체)
  static Future<KkosunnaeResult> calculateScore(String userId) async {
    // 사용자 정보 가져오기
    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists) {
      return KkosunnaeResult(
        totalScore: 50,
        grade: gradeNewbie,
        breakdown: KkosunnaeBreakdown.empty(),
      );
    }

    final user = UserModel.fromFirestore(userDoc.data()!, id: userDoc.id);

    // 받은 평가 목록 가져오기
    final ratingsSnapshot = await _firebase.firestore
        .collection('ratings')
        .where('targetId', isEqualTo: userId)
        .get();
    
    final ratings = ratingsSnapshot.docs
        .map((doc) => RatingModel.fromFirestore(doc.data(), id: doc.id))
        .toList();

    // 각 카테고리별 점수 계산
    final reputationScore = _calculateReputationScore(ratings);
    final activityScore = _calculateActivityScore(user);
    final trustScore = _calculateTrustScore(user);
    final activeScore = _calculateActiveScore(user);
    final penaltyScore = _calculatePenaltyScore(user, ratings);

    // 총점 계산 (최소 0, 최대 100)
    final totalScore = max(0, min(100, 
      reputationScore.score + 
      activityScore.score + 
      trustScore.score + 
      activeScore.score - 
      penaltyScore.score
    )).round();

    // 등급 결정
    final grade = _getGrade(totalScore);

    return KkosunnaeResult(
      totalScore: totalScore,
      grade: grade,
      breakdown: KkosunnaeBreakdown(
        reputation: reputationScore,
        activity: activityScore,
        trust: trustScore,
        active: activeScore,
        penalty: penaltyScore,
      ),
    );
  }

  /// 꼬순내 지수 업데이트 (Firestore에 저장)
  static Future<void> updateScore(String userId) async {
    final result = await calculateScore(userId);
    
    await _firebase.usersCollection.doc(userId).update({
      'kkosunnaeScore': result.totalScore.toDouble(),
    });
  }

  // ===== 1. 평판 점수 (40점) =====
  static ScoreDetail _calculateReputationScore(List<RatingModel> ratings) {
    if (ratings.isEmpty) {
      return ScoreDetail(
        score: 20, // 기본 점수
        maxScore: 40,
        description: '아직 받은 평가가 없어요',
        details: ['평가를 받으면 점수가 올라가요'],
      );
    }

    // 완료된 평가만 필터링
    final completedRatings = ratings
        .where((r) => r.result == ActivityResult.completed)
        .toList();

    if (completedRatings.isEmpty) {
      return ScoreDetail(
        score: 15,
        maxScore: 40,
        description: '완료된 활동이 없어요',
        details: ['활동을 완료하고 평가를 받아보세요'],
      );
    }

    // A. 평균 평점 (30점)
    final avgScore = completedRatings.map((r) => r.score).reduce((a, b) => a + b) / 
                     completedRatings.length;
    final ratingScore = (avgScore / 5 * 30).round(); // 5점 만점 → 30점 환산

    // B. 평가 개수 보너스 (10점)
    int countBonus = 0;
    final count = completedRatings.length;
    if (count >= 50) {
      countBonus = 10;
    } else if (count >= 30) {
      countBonus = 8;
    } else if (count >= 15) {
      countBonus = 6;
    } else if (count >= 5) {
      countBonus = 4;
    } else if (count >= 3) {
      countBonus = 2;
    }

    final totalScore = ratingScore + countBonus;
    final details = <String>[
      '평균 평점: ${avgScore.toStringAsFixed(1)}점 (+$ratingScore점)',
      '평가 ${count}개 (+${countBonus}점)',
    ];

    return ScoreDetail(
      score: totalScore.toDouble(),
      maxScore: 40,
      description: '평균 ${avgScore.toStringAsFixed(1)}점 (${count}개 평가)',
      details: details,
    );
  }

  // ===== 2. 활동 점수 (25점) =====
  static ScoreDetail _calculateActivityScore(UserModel user) {
    double score = 0;
    final details = <String>[];

    // A. 매칭 활동 (10점) - 1회당 2점
    final matchScore = min(10, user.matchCount * 2);
    score += matchScore;
    if (user.matchCount > 0) {
      details.add('매칭 ${user.matchCount}회 (+$matchScore점)');
    }

    // B. 산책 활동 (6점) - 1회당 0.6점
    final walkScore = min(6.0, user.walkCount * 0.6);
    score += walkScore;
    if (user.walkCount > 0) {
      details.add('산책 ${user.walkCount}회 (+${walkScore.toStringAsFixed(1)}점)');
    }

    // C. 거래 활동 (6점) - 1회당 1.2점
    final transactionScore = min(6.0, user.transactionCount * 1.2);
    score += transactionScore;
    if (user.transactionCount > 0) {
      details.add('거래 ${user.transactionCount}회 (+${transactionScore.toStringAsFixed(1)}점)');
    }

    // D. 소모임 활동 (3점) - 1회당 0.6점
    final groupScore = min(3.0, user.groupCount * 0.6);
    score += groupScore;
    if (user.groupCount > 0) {
      details.add('소모임 ${user.groupCount}회 (+${groupScore.toStringAsFixed(1)}점)');
    }

    if (details.isEmpty) {
      details.add('아직 활동 기록이 없어요');
    }

    return ScoreDetail(
      score: score,
      maxScore: 25,
      description: '총 ${(user.matchCount + user.walkCount + user.transactionCount + user.groupCount)}회 활동',
      details: details,
    );
  }

  // ===== 3. 신뢰도 점수 (20점) =====
  static ScoreDetail _calculateTrustScore(UserModel user) {
    double score = 0;
    final details = <String>[];

    // A. 인증 현황 (12점)
    if (user.isIdentityVerified) {
      score += 5;
      details.add('본인 인증 완료 (+5점)');
    }
    if (user.isLocationVerified) {
      score += 4;
      details.add('위치 인증 완료 (+4점)');
    }
    if (user.isVerified) {
      score += 3;
      details.add('동물등록 인증 완료 (+3점)');
    }

    // B. 프로필 완성도 (5점)
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      score += 2;
      details.add('프로필 사진 등록 (+2점)');
    }
    if (user.bio != null && user.bio!.isNotEmpty) {
      score += 1;
      details.add('자기소개 작성 (+1점)');
    }
    if (user.petIds.isNotEmpty) {
      score += 2;
      details.add('반려동물 등록 (+2점)');
    }

    // C. 계정 연령 (3점)
    final accountAge = DateTime.now().difference(user.createdAt).inDays;
    if (accountAge >= 180) {
      score += 3;
      details.add('6개월 이상 회원 (+3점)');
    } else if (accountAge >= 90) {
      score += 2;
      details.add('3개월 이상 회원 (+2점)');
    } else if (accountAge >= 30) {
      score += 1;
      details.add('1개월 이상 회원 (+1점)');
    }

    if (details.isEmpty) {
      details.add('인증을 완료하면 점수가 올라가요');
    }

    return ScoreDetail(
      score: score,
      maxScore: 20,
      description: '${details.length}개 항목 완료',
      details: details,
    );
  }

  // ===== 4. 앱 활성도 (15점) =====
  static ScoreDetail _calculateActiveScore(UserModel user) {
    double score = 0;
    final details = <String>[];

    // A. 접속 빈도 (10점) - 최근 접속 기준
    final daysSinceActive = DateTime.now().difference(user.lastActiveAt).inDays;
    if (daysSinceActive <= 1) {
      score += 10;
      details.add('최근 활동 (+10점)');
    } else if (daysSinceActive <= 3) {
      score += 7;
      details.add('3일 내 활동 (+7점)');
    } else if (daysSinceActive <= 7) {
      score += 4;
      details.add('7일 내 활동 (+4점)');
    } else if (daysSinceActive <= 14) {
      score += 2;
      details.add('2주 내 활동 (+2점)');
    }

    // B. 응답률 (5점) - 추후 구현
    // 현재는 기본 점수 부여
    score += 3;
    details.add('기본 응답 점수 (+3점)');

    return ScoreDetail(
      score: score,
      maxScore: 15,
      description: daysSinceActive <= 1 ? '활발히 활동 중' : '${daysSinceActive}일 전 활동',
      details: details,
    );
  }

  // ===== 5. 감점 요소 (최대 -15점) =====
  static ScoreDetail _calculatePenaltyScore(UserModel user, List<RatingModel> ratings) {
    double penalty = 0;
    final details = <String>[];

    // A. 신고 이력
    final reportCount = user.reportCount;
    if (reportCount >= 3) {
      penalty += 15;
      details.add('신고 ${reportCount}회 (-15점)');
    } else if (reportCount == 2) {
      penalty += 7;
      details.add('신고 2회 (-7점)');
    } else if (reportCount == 1) {
      penalty += 3;
      details.add('신고 1회 (-3점)');
    }

    // B. 노쇼 이력
    final noShowCount = ratings.where((r) => r.result == ActivityResult.noShow).length;
    final noShowPenalty = min(10.0, noShowCount * 2.0);
    if (noShowPenalty > 0) {
      penalty += noShowPenalty;
      details.add('노쇼 ${noShowCount}회 (-${noShowPenalty.toStringAsFixed(0)}점)');
    }

    if (details.isEmpty) {
      details.add('감점 요소 없음');
    }

    return ScoreDetail(
      score: penalty,
      maxScore: 15,
      description: penalty > 0 ? '${penalty.toStringAsFixed(0)}점 감점' : '감점 없음',
      details: details,
    );
  }

  // ===== 등급 결정 =====
  static String _getGrade(int score) {
    if (score >= 90) return gradeMaster;
    if (score >= 75) return gradeVeteran;
    if (score >= 55) return gradeFriend;
    if (score >= 35) return gradeGrowing;
    return gradeNewbie;
  }

  /// 등급 색상 가져오기
  static int getGradeColor(int score) {
    if (score >= 90) return 0xFFFFD700; // 금색
    if (score >= 75) return 0xFFFF6B6B; // 코랄
    if (score >= 55) return 0xFF4ECDC4; // 민트
    if (score >= 35) return 0xFF95E1D3; // 연민트
    return 0xFFB8B8B8; // 회색
  }

  /// 배지 표시 여부 (90점 이상)
  static bool shouldShowBadge(int score) => score >= 90;

  /// 점수를 온도로 변환 (36.5°C 기준)
  static double scoreToTemperature(int score) {
    // 50점 = 36.5°C, 100점 = 99°C, 0점 = 0°C
    return 36.5 + (score - 50) * 0.5;
  }

  /// 점수 텍스트 포맷
  static String formatScore(int score) => '$score%';

  /// 간단한 등급 텍스트 (이모지 제외)
  static String getSimpleGrade(int score) {
    if (score >= 90) return '마스터';
    if (score >= 75) return '베테랑';
    if (score >= 55) return '친구';
    if (score >= 35) return '성장중';
    return '새싹';
  }
}

/// 꼬순내 지수 결과
class KkosunnaeResult {
  final int totalScore;
  final String grade;
  final KkosunnaeBreakdown breakdown;

  KkosunnaeResult({
    required this.totalScore,
    required this.grade,
    required this.breakdown,
  });
}

/// 꼬순내 지수 상세 내역
class KkosunnaeBreakdown {
  final ScoreDetail reputation;
  final ScoreDetail activity;
  final ScoreDetail trust;
  final ScoreDetail active;
  final ScoreDetail penalty;

  KkosunnaeBreakdown({
    required this.reputation,
    required this.activity,
    required this.trust,
    required this.active,
    required this.penalty,
  });

  factory KkosunnaeBreakdown.empty() {
    return KkosunnaeBreakdown(
      reputation: ScoreDetail(score: 20, maxScore: 40, description: '', details: []),
      activity: ScoreDetail(score: 0, maxScore: 25, description: '', details: []),
      trust: ScoreDetail(score: 0, maxScore: 20, description: '', details: []),
      active: ScoreDetail(score: 10, maxScore: 15, description: '', details: []),
      penalty: ScoreDetail(score: 0, maxScore: 15, description: '', details: []),
    );
  }
}

/// 점수 상세 정보
class ScoreDetail {
  final double score;
  final double maxScore;
  final String description;
  final List<String> details;

  ScoreDetail({
    required this.score,
    required this.maxScore,
    required this.description,
    required this.details,
  });
}
