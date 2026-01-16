import 'dart:math';
import '../../models/user_model.dart';
import '../../models/rating_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// ============================================================
/// 꼬순내 지수 서비스
/// 사용자 신뢰도/평판 점수 계산 (당근마켓 매너온도와 유사)
/// 
/// 하이브리드 방식:
/// - 원점수: 절대 평가 (0~100점) - 변하지 않음
/// - 등급: 상대 평가 (백분위 기반) - 주기적 조정
/// 
/// 점수 배분 (100점 만점):
/// - 평판 점수: 40점 (평가 점수 30점 + 평가 개수 보너스 10점)
/// - 활동 점수: 20점 (매칭/거래/교배)
/// - 신뢰도 점수: 20점 (인증/프로필/계정연령)
/// - 커뮤니티 점수: 10점 (게시글/댓글/좋아요/최근이용)
/// - 앱 활성도: 10점 (접속빈도)
/// - 감점 요소: 최대 -15점 (신고/노쇼)
/// 
/// 등급 체계 (백분위 기반 상대 평가):
/// - 빅뱅: 상위 10% (금색) - "우주 끝까지 퍼지는 향! 레전드"
/// - 화산: 상위 20% (주황) - "용암처럼 강렬한 냄새!"
/// - 뜨끈: 상위 30% (빨강) - "뜨끈뜨끈 따끈한 냄새!"
/// - 솔솔: 상위 50% (파랑) - "은은한 냄새가 솔솔~"
/// - 쑥쑥: 하위 50% (초록) - "냄새가 자라는 중! 더 놀아줘요"
/// ============================================================

class KkosunnaeService {
  static final _firebase = FirebaseService();

  // ===== 등급 정의 (백분위 기반) =====
  static const String gradeBigBang = '빅뱅';      // 상위 10%
  static const String gradeVolcano = '화산';      // 상위 20%
  static const String gradeHot = '뜨끈';          // 상위 30%
  static const String gradeSolsol = '솔솔';       // 상위 50%
  static const String gradeGrowing = '쑥쑥';      // 하위 50%

  // ===== 등급 구간 (동적 조정 - 초기 기본값) =====
  // 주기적으로 전체 유저 분포 분석 후 업데이트
  static int _thresholdBigBang = 90;   // 빅뱅 진입 점수
  static int _thresholdVolcano = 80;   // 화산 진입 점수
  static int _thresholdHot = 70;       // 뜨끈 진입 점수
  static int _thresholdSolsol = 50;    // 솔솔 진입 점수

  /// 등급 구간 정보 (UI 표시용)
  static GradeThresholds get gradeThresholds => GradeThresholds(
    bigBang: _thresholdBigBang,
    volcano: _thresholdVolcano,
    hot: _thresholdHot,
    solsol: _thresholdSolsol,
  );

  /// 꼬순내 지수 계산 (전체)
  static Future<KkosunnaeResult> calculateScore(String userId) async {
    // 사용자 정보 가져오기
    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists) {
      return KkosunnaeResult(
        totalScore: 50,
        grade: gradeSolsol,  // 기본값 50점 = 솔솔 등급
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
    final communityScore = await _calculateCommunityScore(userId);
    final activeScore = _calculateActiveScore(user);
    final penaltyScore = _calculatePenaltyScore(user, ratings);

    // 총점 계산 (최소 0, 최대 100)
    final totalScore = max(0, min(100, 
      reputationScore.score + 
      activityScore.score + 
      trustScore.score + 
      communityScore.score +
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
        community: communityScore,
        active: activeScore,
        penalty: penaltyScore,
      ),
    );
  }

  /// 꼬순내 지수 업데이트 (Firestore에 저장)
  /// 등급 변동 시 알림 발송
  static Future<void> updateScore(String userId) async {
    // 기존 점수 조회
    final userDoc = await _firebase.usersCollection.doc(userId).get();
    final oldScore = (userDoc.data()?['kkosunnaeScore'] as num?)?.toInt() ?? 50;
    final oldGrade = getSimpleGrade(oldScore);
    
    // 새 점수 계산
    final result = await calculateScore(userId);
    final newScore = result.totalScore;
    final newGrade = getSimpleGrade(newScore);
    
    // Firestore 업데이트
    await _firebase.usersCollection.doc(userId).update({
      'kkosunnaeScore': newScore.toDouble(),
    });
    
    // 등급 변동 시 알림 발송
    if (oldGrade != newGrade) {
      await NotificationService().sendGradeChangeNotification(
        recipientId: userId,
        oldGrade: oldGrade,
        newGrade: newGrade,
        oldScore: oldScore,
        newScore: newScore,
      );
    }
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

  // ===== 2. 활동 점수 (20점) =====
  static ScoreDetail _calculateActivityScore(UserModel user) {
    double score = 0;
    final details = <String>[];

    // A. 매칭 활동 (8점) - 1회당 1.6점
    final matchScore = min(8.0, user.matchCount * 1.6);
    score += matchScore;
    if (user.matchCount > 0) {
      details.add('매칭 ${user.matchCount}회 (+${matchScore.toStringAsFixed(1)}점)');
    }

    // B. 산책 활동 (5점) - 1회당 0.5점
    final walkScore = min(5.0, user.walkCount * 0.5);
    score += walkScore;
    if (user.walkCount > 0) {
      details.add('산책 ${user.walkCount}회 (+${walkScore.toStringAsFixed(1)}점)');
    }

    // C. 거래 활동 (5점) - 1회당 1점
    final transactionScore = min(5.0, user.transactionCount * 1.0);
    score += transactionScore;
    if (user.transactionCount > 0) {
      details.add('거래 ${user.transactionCount}회 (+${transactionScore.toStringAsFixed(1)}점)');
    }

    // D. 소모임 활동 (2점) - 1회당 0.4점
    final groupScore = min(2.0, user.groupCount * 0.4);
    score += groupScore;
    if (user.groupCount > 0) {
      details.add('소모임 ${user.groupCount}회 (+${groupScore.toStringAsFixed(1)}점)');
    }

    if (details.isEmpty) {
      details.add('아직 활동 기록이 없어요');
    }

    return ScoreDetail(
      score: score,
      maxScore: 20,
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

  // ===== 4. 커뮤니티 점수 (10점) =====
  static Future<ScoreDetail> _calculateCommunityScore(String userId) async {
    double score = 0;
    final details = <String>[];

    try {
      // A. 게시글 수 (3점) - 최대 10개
      final postsSnapshot = await _firebase.firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .limit(10)
          .get();
      final postCount = postsSnapshot.docs.length;
      final postScore = min(3.0, postCount * 0.3);
      score += postScore;
      if (postCount > 0) {
        details.add('게시글 $postCount개 (+${postScore.toStringAsFixed(1)}점)');
      }

      // B. 댓글 수 (3점) - 최대 15개
      final commentsSnapshot = await _firebase.firestore
          .collection('comments')
          .where('authorId', isEqualTo: userId)
          .limit(15)
          .get();
      final commentCount = commentsSnapshot.docs.length;
      final commentScore = min(3.0, commentCount * 0.2);
      score += commentScore;
      if (commentCount > 0) {
        details.add('댓글 $commentCount개 (+${commentScore.toStringAsFixed(1)}점)');
      }

      // C. 받은 좋아요 수 (2점) - 최대 20개
      final likesSnapshot = await _firebase.firestore
          .collection('likes')
          .where('targetUserId', isEqualTo: userId)
          .limit(20)
          .get();
      final likeCount = likesSnapshot.docs.length;
      final likeScore = min(2.0, likeCount * 0.1);
      score += likeScore;
      if (likeCount > 0) {
        details.add('받은 좋아요 $likeCount개 (+${likeScore.toStringAsFixed(1)}점)');
      }

      // D. 최근 커뮤니티 이용 (2점)
      // 최근 7일 내 게시글/댓글 작성 여부
      final recentDate = DateTime.now().subtract(const Duration(days: 7));
      final recentPostsSnapshot = await _firebase.firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: recentDate)
          .limit(1)
          .get();
      if (recentPostsSnapshot.docs.isNotEmpty) {
        score += 2;
        details.add('최근 커뮤니티 활동 (+2점)');
      }
    } catch (e) {
      // 오류 시 기본 점수
      score = 2;
      details.add('기본 점수 (+2점)');
    }

    if (details.isEmpty) {
      details.add('커뮤니티 활동을 시작해보세요');
    }

    return ScoreDetail(
      score: score,
      maxScore: 10,
      description: score >= 5 ? '활발한 커뮤니티 활동' : '커뮤니티 활동 중',
      details: details,
    );
  }

  // ===== 5. 앱 활성도 (10점) =====
  static ScoreDetail _calculateActiveScore(UserModel user) {
    double score = 0;
    final details = <String>[];

    // A. 접속 빈도 (7점) - 최근 접속 기준
    final daysSinceActive = DateTime.now().difference(user.lastActiveAt).inDays;
    if (daysSinceActive <= 1) {
      score += 7;
      details.add('최근 활동 (+7점)');
    } else if (daysSinceActive <= 3) {
      score += 5;
      details.add('3일 내 활동 (+5점)');
    } else if (daysSinceActive <= 7) {
      score += 3;
      details.add('7일 내 활동 (+3점)');
    } else if (daysSinceActive <= 14) {
      score += 1;
      details.add('2주 내 활동 (+1점)');
    }

    // B. 응답률 (3점) - 추후 구현
    // 현재는 기본 점수 부여
    score += 2;
    details.add('기본 응답 점수 (+2점)');

    return ScoreDetail(
      score: score,
      maxScore: 10,
      description: daysSinceActive <= 1 ? '활발히 활동 중' : '${daysSinceActive}일 전 활동',
      details: details,
    );
  }

  // ===== 6. 감점 요소 (최대 -15점) - 하이브리드 방식 =====
  /// 
  /// ## 감점 시스템 설계 철학
  /// 
  /// 기존 문제점:
  /// - 한 번 감점 → 영원히 100점 불가 (회복 불가능)
  /// - 시간이 지나도 감점 유지 (개선 의지 무시)
  /// 
  /// 하이브리드 방식 해결책:
  /// 1. **시간 감쇠 (Time Decay)**: 오래된 감점은 영향력 감소
  /// 2. **선행 상쇄 (Good Behavior Offset)**: 좋은 평가로 감점 일부 상쇄
  /// 3. **최대 감점 상한**: 아무리 나빠도 -15점 초과 불가
  /// 
  /// ## 감점 구성
  /// 
  /// ### A. 신고 감점 (최대 -10점)
  /// - 최근 6개월 신고: 100% 반영 (1회: -3점, 2회: -6점, 3회+: -10점)
  /// - 6개월~1년 신고: 50% 반영
  /// - 1년 이상 신고: 20% 반영 (최대 -2점)
  /// 
  /// ### B. 노쇼 감점 (최대 -8점)
  /// - 최근 90일 노쇼: 100% 반영 (1회당 -2점)
  /// - 90일~180일 노쇼: 50% 반영 (1회당 -1점)
  /// - 180일 이상 노쇼: 반영 안 함 (만료)
  /// 
  /// ### C. 선행 상쇄 (최대 +5점 회복)
  /// - 최근 6개월 긍정 평가(4점 이상) 10개당 +1점 회복
  /// - 감점의 최대 30%까지만 상쇄 가능
  /// 
  /// ## 100점 달성 시나리오
  /// - 신고/노쇼 후 6개월~1년 경과 → 감점 50% 감소
  /// - 긍정 평가 누적 → 추가 30% 상쇄
  /// - 1년 이상 경과 + 활발한 활동 → 100점 달성 가능
  /// 
  static ScoreDetail _calculatePenaltyScore(UserModel user, List<RatingModel> ratings) {
    double penalty = 0;
    final details = <String>[];
    final now = DateTime.now();
    
    // ========================================
    // A. 신고 감점 (시간 감쇠 적용, 최대 -10점)
    // ========================================
    // 
    // 현재 UserModel에는 신고 날짜가 없으므로,
    // reportCount를 기준으로 계산하되, 시간 감쇠는
    // 계정 연령을 고려하여 적용
    // 
    // TODO: 향후 ReportModel 도입 시 날짜별 감쇠 적용
    // 
    final reportCount = user.reportCount;
    if (reportCount > 0) {
      // 계정 연령에 따른 감쇠율 계산
      // - 신규 유저(30일 미만): 100% 반영 (아직 회복 기회 없음)
      // - 중간 유저(30~180일): 80% 반영
      // - 오래된 유저(180일+): 60% 반영 (시간이 지나며 감쇠)
      final accountAgeDays = now.difference(user.createdAt).inDays;
      double decayRate = 1.0;
      if (accountAgeDays >= 180) {
        decayRate = 0.6;
      } else if (accountAgeDays >= 30) {
        decayRate = 0.8;
      }
      
      // 기본 신고 감점 계산
      double baseReportPenalty = 0;
      if (reportCount >= 3) {
        baseReportPenalty = 10;
      } else if (reportCount == 2) {
        baseReportPenalty = 6;
      } else if (reportCount == 1) {
        baseReportPenalty = 3;
      }
      
      // 시간 감쇠 적용
      final reportPenalty = baseReportPenalty * decayRate;
      penalty += reportPenalty;
      
      if (reportPenalty > 0) {
        details.add('신고 ${reportCount}회 (-${reportPenalty.toStringAsFixed(1)}점)');
        if (decayRate < 1.0) {
          details.add('  └ 시간 경과로 ${((1 - decayRate) * 100).toInt()}% 감쇠');
        }
      }
    }

    // ========================================
    // B. 노쇼 감점 (기간별 차등, 최대 -8점)
    // ========================================
    // 
    // 노쇼는 RatingModel의 createdAt으로 정확한 날짜 확인 가능
    // 
    // 기간별 감점:
    // - 최근 90일: 1회당 -2점 (100% 반영)
    // - 90~180일: 1회당 -1점 (50% 반영)
    // - 180일 이상: 반영 안 함 (만료)
    // 
    final noShowRatings = ratings.where((r) => r.result == ActivityResult.noShow).toList();
    
    // 최근 90일 노쇼
    final recentNoShows = noShowRatings.where((r) => 
      r.createdAt.isAfter(now.subtract(const Duration(days: 90)))
    ).length;
    final recentNoShowPenalty = min(6.0, recentNoShows * 2.0);
    
    // 90~180일 노쇼 (50% 감쇠)
    final midNoShows = noShowRatings.where((r) => 
      r.createdAt.isAfter(now.subtract(const Duration(days: 180))) &&
      r.createdAt.isBefore(now.subtract(const Duration(days: 90)))
    ).length;
    final midNoShowPenalty = min(2.0, midNoShows * 1.0);
    
    // 180일 이상 노쇼는 만료 (반영 안 함)
    final expiredNoShows = noShowRatings.where((r) => 
      r.createdAt.isBefore(now.subtract(const Duration(days: 180)))
    ).length;
    
    final totalNoShowPenalty = min(8.0, recentNoShowPenalty + midNoShowPenalty);
    penalty += totalNoShowPenalty;
    
    if (noShowRatings.isNotEmpty) {
      if (recentNoShows > 0) {
        details.add('최근 노쇼 ${recentNoShows}회 (-${recentNoShowPenalty.toStringAsFixed(0)}점)');
      }
      if (midNoShows > 0) {
        details.add('과거 노쇼 ${midNoShows}회 (-${midNoShowPenalty.toStringAsFixed(0)}점, 50% 감쇠)');
      }
      if (expiredNoShows > 0) {
        details.add('만료된 노쇼 ${expiredNoShows}회 (6개월 경과, 반영 안 함)');
      }
    }

    // ========================================
    // C. 선행 상쇄 (Good Behavior Offset)
    // ========================================
    // 
    // 최근 6개월 긍정 평가로 감점 일부 회복
    // - 4점 이상 평가 10개당 +1점 회복
    // - 최대 감점의 30%까지만 상쇄 가능 (최대 +5점)
    // 
    // 이유: 완전 상쇄 시 악성 유저가 평가 조작으로 악용 가능
    // 
    if (penalty > 0) {
      final recentPositiveRatings = ratings.where((r) => 
        r.score >= 4 && 
        r.result == ActivityResult.completed &&
        r.createdAt.isAfter(now.subtract(const Duration(days: 180)))
      ).length;
      
      // 긍정 평가 10개당 1점 회복
      final rawOffset = recentPositiveRatings / 10.0;
      
      // 최대 상쇄: 감점의 30% 또는 5점 중 작은 값
      final maxOffset = min(5.0, penalty * 0.3);
      final actualOffset = min(maxOffset, rawOffset);
      
      if (actualOffset > 0) {
        penalty -= actualOffset;
        details.add('긍정 평가 ${recentPositiveRatings}개로 +${actualOffset.toStringAsFixed(1)}점 회복');
      }
    }

    // ========================================
    // D. 최종 감점 상한 적용
    // ========================================
    // 
    // 아무리 나빠도 -15점 초과 불가
    // 이유: 극단적 감점은 유저 이탈 유발
    // 
    penalty = min(15.0, max(0, penalty));

    if (details.isEmpty) {
      details.add('감점 요소 없음 ✨');
    }

    return ScoreDetail(
      score: penalty,
      maxScore: 15,
      description: penalty > 0 ? '${penalty.toStringAsFixed(1)}점 감점' : '감점 없음',
      details: details,
    );
  }

  // ===== 등급 결정 (동적 구간 기반) =====
  static String _getGrade(int score) {
    if (score >= _thresholdBigBang) return gradeBigBang;
    if (score >= _thresholdVolcano) return gradeVolcano;
    if (score >= _thresholdHot) return gradeHot;
    if (score >= _thresholdSolsol) return gradeSolsol;
    return gradeGrowing;
  }

  /// 등급 색상 가져오기 (동적 구간 기반)
  static int getGradeColor(int score) {
    if (score >= _thresholdBigBang) return 0xFFFFD700; // 금색 (빅뱅)
    if (score >= _thresholdVolcano) return 0xFFFF9500; // 주황색 (화산)
    if (score >= _thresholdHot) return 0xFFFF6B6B;     // 빨간색 (뜨끈)
    if (score >= _thresholdSolsol) return 0xFF4A90D9; // 파란색 (솔솔)
    return 0xFF4CAF50;                                 // 초록색 (쑥쑥)
  }

  /// 배지 표시 여부 (빅뱅 등급)
  static bool shouldShowBadge(int score) => score >= _thresholdBigBang;

  /// 점수 텍스트 포맷
  static String formatScore(int score) => '$score점';

  /// 등급명 가져오기 (동적 구간 기반)
  static String getSimpleGrade(int score) {
    if (score >= _thresholdBigBang) return '빅뱅';
    if (score >= _thresholdVolcano) return '화산';
    if (score >= _thresholdHot) return '뜨끈';
    if (score >= _thresholdSolsol) return '솔솔';
    return '쑥쑥';
  }

  // ===== 등급 구간 동적 업데이트 =====
  
  /// 전체 유저 점수 분포 분석 후 등급 구간 업데이트
  /// 주기적으로 호출 (Cloud Functions 또는 앱 초기화 시)
  static Future<void> updateGradeThresholds() async {
    try {
      // 전체 유저 점수 조회
      final usersSnapshot = await _firebase.usersCollection.get();
      final scores = usersSnapshot.docs
          .map((doc) => (doc.data()['kkosunnaeScore'] as num?)?.toInt() ?? 50)
          .toList();
      
      // 최소 유저 수 미달 시 기본값 유지
      if (scores.length < 100) {
        return;
      }
      
      // 점수 정렬 (내림차순)
      scores.sort((a, b) => b.compareTo(a));
      
      // 백분위 계산
      _thresholdBigBang = scores[(scores.length * 0.10).floor()]; // 상위 10%
      _thresholdVolcano = scores[(scores.length * 0.20).floor()]; // 상위 20%
      _thresholdHot = scores[(scores.length * 0.30).floor()];     // 상위 30%
      _thresholdSolsol = scores[(scores.length * 0.50).floor()];  // 상위 50%
      
      // Firestore에 구간 정보 저장 (선택적)
      await _firebase.firestore.collection('config').doc('kkosunnae').set({
        'thresholdBigBang': _thresholdBigBang,
        'thresholdVolcano': _thresholdVolcano,
        'thresholdHot': _thresholdHot,
        'thresholdSolsol': _thresholdSolsol,
        'updatedAt': DateTime.now().toIso8601String(),
        'userCount': scores.length,
      });
    } catch (e) {
      // 실패 시 기본값 유지
    }
  }

  /// 저장된 등급 구간 로드 (앱 초기화 시 호출)
  static Future<void> loadGradeThresholds() async {
    try {
      final doc = await _firebase.firestore.collection('config').doc('kkosunnae').get();
      if (doc.exists) {
        final data = doc.data()!;
        _thresholdBigBang = data['thresholdBigBang'] ?? 90;
        _thresholdVolcano = data['thresholdVolcano'] ?? 80;
        _thresholdHot = data['thresholdHot'] ?? 70;
        _thresholdSolsol = data['thresholdSolsol'] ?? 50;
      }
    } catch (e) {
      // 실패 시 기본값 유지
    }
  }

  /// 등급별 설명 문구 가져오기 (동적 구간 기반)
  static String getGradeDescription(int score) {
    if (score >= _thresholdBigBang) return '✨ 우주 끝까지 퍼지는 향! 레전드 ✨';
    if (score >= _thresholdVolcano) return '용암처럼 강렬한 냄새! 냄새 폭발';
    if (score >= _thresholdHot) return '뜨끈뜨끈 따끈한 냄새! 컹컹컹';
    if (score >= _thresholdSolsol) return '은은한 냄새가 솔솔~ 킁킁킁';
    return '냄새가 자라는 중~ 더 놀아줘요';
  }

  /// 등급별 이모지 가져오기 (동적 구간 기반)
  static String getGradeEmoji(int score) {
    if (score >= _thresholdBigBang) return '✨';
    if (score >= _thresholdVolcano) return '🌋';
    if (score >= _thresholdHot) return '🔥';
    if (score >= _thresholdSolsol) return '💨';
    return '🌱';
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
  final ScoreDetail community;
  final ScoreDetail active;
  final ScoreDetail penalty;

  KkosunnaeBreakdown({
    required this.reputation,
    required this.activity,
    required this.trust,
    required this.community,
    required this.active,
    required this.penalty,
  });

  factory KkosunnaeBreakdown.empty() {
    return KkosunnaeBreakdown(
      reputation: ScoreDetail(score: 20, maxScore: 40, description: '', details: []),
      activity: ScoreDetail(score: 0, maxScore: 20, description: '', details: []),
      trust: ScoreDetail(score: 0, maxScore: 20, description: '', details: []),
      community: ScoreDetail(score: 0, maxScore: 10, description: '', details: []),
      active: ScoreDetail(score: 5, maxScore: 10, description: '', details: []),
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

/// 등급 구간 정보 (UI 표시용)
class GradeThresholds {
  final int bigBang;   // 빅뱅 진입 점수
  final int volcano;   // 화산 진입 점수
  final int hot;       // 뜨끈 진입 점수
  final int solsol;    // 솔솔 진입 점수

  const GradeThresholds({
    required this.bigBang,
    required this.volcano,
    required this.hot,
    required this.solsol,
  });

  /// 등급별 점수 범위 문자열 (안내 팝업용)
  String getBigBangRange() => '$bigBang ~ 100점';
  String getVolcanoRange() => '$volcano ~ ${bigBang - 1}점';
  String getHotRange() => '$hot ~ ${volcano - 1}점';
  String getSolsolRange() => '$solsol ~ ${hot - 1}점';
  String getGrowingRange() => '0 ~ ${solsol - 1}점';
}
