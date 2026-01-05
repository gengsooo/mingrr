import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/pet_constants.dart';
import '../services/location_service.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';

/// ============================================================
/// 추천 매칭 알고리즘 서비스 (V3)
/// 
/// 점수 배분 (총 100점):
/// - 체형 궁합: 18점 (크기 10점 + 체중 8점)
/// - 나이 궁합: 15점 (나이차 9점 + 생애단계 6점)
/// - 성격 궁합: 15점 (보완 6점 + 동일 5점 + 에너지 4점)
/// - 거리: 14점
/// - 보호자 인증: 12점
/// - 꼬순내 지수: 10점
/// - 품종 궁합: 6점
/// - 인기도: 6점
/// - 앱 활성도: 4점
/// ============================================================

class MatchingService {
  MatchingService._();

  /// 궁합 점수 계산 (0~100)
  static MatchResult calculateCompatibility({
    required PetModel myPet,
    required PetModel otherPet,
    required UserModel? myUser,
    required UserModel? otherUser,
    double? distanceMeters,
  }) {
    double totalScore = 0;
    final details = <String, double>{};

    // ===== 1. 체형 궁합 (18점) =====
    final bodyScore = _calculateBodyScore(myPet, otherPet);
    details['body'] = bodyScore;
    totalScore += bodyScore;

    // ===== 2. 나이 궁합 (15점) =====
    final ageScore = _calculateAgeScore(myPet, otherPet);
    details['age'] = ageScore;
    totalScore += ageScore;

    // ===== 3. 성격 궁합 (15점) =====
    final traitScore = _calculateTraitScore(myPet, otherPet);
    details['traits'] = traitScore;
    totalScore += traitScore;

    // ===== 4. 거리 (14점) =====
    final distanceScore = _calculateDistanceScore(distanceMeters);
    details['distance'] = distanceScore;
    totalScore += distanceScore;

    // ===== 5. 보호자 인증 (12점) =====
    final verificationScore = _calculateVerificationScore(otherUser);
    details['verification'] = verificationScore;
    totalScore += verificationScore;

    // ===== 6. 꼬순내 지수 (10점) =====
    final activityScore = _calculateActivityScore(otherUser);
    details['activity'] = activityScore;
    totalScore += activityScore;

    // ===== 7. 품종 궁합 (6점) =====
    final breedScore = _calculateBreedScore(myPet, otherPet);
    details['breed'] = breedScore;
    totalScore += breedScore;

    // ===== 8. 인기도 (6점) =====
    final popularityScore = _calculatePopularityScore(otherPet);
    details['popularity'] = popularityScore;
    totalScore += popularityScore;

    // ===== 9. 앱 활성도 (4점) =====
    final activeScore = _calculateActiveScore(otherUser);
    details['active'] = activeScore;
    totalScore += activeScore;

    return MatchResult(
      score: min(100, totalScore.round()),
      details: details,
      distanceMeters: distanceMeters,
    );
  }

  // ===== 1. 체형 궁합 (18점) =====
  static double _calculateBodyScore(PetModel myPet, PetModel otherPet) {
    double score = 0;

    // A. 크기 매칭 (10점)
    final mySize = myPet.size;
    final otherSize = otherPet.size;
    
    if (mySize != null && otherSize != null) {
      if (mySize == otherSize) {
        score += 10;
      } else {
        final sizeDiff = (mySize.index - otherSize.index).abs();
        if (sizeDiff == 1) score += 5;
        else if (sizeDiff == 2) score += 2;
      }
    } else {
      score += 5; // 정보 없으면 중간 점수
    }

    // B. 체중 차이 (8점)
    if (myPet.weight != null && otherPet.weight != null) {
      final weightDiff = (myPet.weight! - otherPet.weight!).abs();
      if (weightDiff <= 1) score += 8;
      else if (weightDiff <= 2) score += 6;
      else if (weightDiff <= 3) score += 4;
      else if (weightDiff <= 5) score += 2;
    } else {
      score += 4; // 정보 없으면 중간 점수
    }

    return score;
  }

  // ===== 2. 나이 궁합 (15점) =====
  static double _calculateAgeScore(PetModel myPet, PetModel otherPet) {
    double score = 0;
    final myAge = myPet.ageYears;
    final otherAge = otherPet.ageYears;

    // A. 나이 차이 (9점)
    if (myAge != null && otherAge != null) {
      final ageDiff = (myAge - otherAge).abs();
      if (ageDiff == 0) score += 9;
      else if (ageDiff == 1) score += 7;
      else if (ageDiff == 2) score += 5;
      else if (ageDiff == 3) score += 3;
      else score += 1;

      // B. 생애 단계 매칭 (6점)
      final myStage = _getLifeStage(myAge);
      final otherStage = _getLifeStage(otherAge);
      final stageDiff = (myStage - otherStage).abs();
      
      if (stageDiff == 0) score += 6;
      else if (stageDiff == 1) score += 3;
      else score += 1;
    } else {
      score += 7.5; // 정보 없으면 중간 점수
    }

    return score;
  }

  /// 생애 단계 (0: 퍼피, 1: 청년, 2: 성견, 3: 시니어)
  static int _getLifeStage(int ageYears) {
    if (ageYears < 1) return 0;
    if (ageYears < 3) return 1;
    if (ageYears < 7) return 2;
    return 3;
  }

  // ===== 3. 성격 궁합 (15점) =====
  static double _calculateTraitScore(PetModel myPet, PetModel otherPet) {
    if (myPet.traits.isEmpty || otherPet.traits.isEmpty) {
      return 7.5;
    }

    double score = 0;

    // A. 상호 보완 특성 (6점)
    final synergyPairs = [
      (PetTrait.active, PetTrait.calm, 3.0),
      (PetTrait.curious, PetTrait.gentle, 2.0),
      (PetTrait.playful, PetTrait.gentle, 2.0),
      (PetTrait.independent, PetTrait.affectionate, 1.5),
      (PetTrait.brave, PetTrait.shy, 1.5),
    ];

    for (final (trait1, trait2, points) in synergyPairs) {
      if ((myPet.traits.contains(trait1) && otherPet.traits.contains(trait2)) ||
          (myPet.traits.contains(trait2) && otherPet.traits.contains(trait1))) {
        score += points;
        if (score >= 6) break;
      }
    }
    score = min(6, score);

    // B. 같은 특성 매칭 (5점)
    final commonCount = myPet.traits.where((t) => otherPet.traits.contains(t)).length;
    score += min(5, commonCount * 1.0);

    // C. 에너지 레벨 매칭 (4점)
    final myEnergy = _getEnergyLevel(myPet.traits);
    final otherEnergy = _getEnergyLevel(otherPet.traits);
    if (myEnergy == otherEnergy) {
      score += 4;
    } else if ((myEnergy - otherEnergy).abs() == 1) {
      score += 2;
    }

    // D. 충돌 특성 감점
    final conflictPairs = [
      (PetTrait.dominant, PetTrait.dominant, -2.0),
      (PetTrait.territorial, PetTrait.territorial, -2.0),
      (PetTrait.fearfulOfPets, PetTrait.dominant, -1.5),
    ];

    for (final (trait1, trait2, penalty) in conflictPairs) {
      if (myPet.traits.contains(trait1) && otherPet.traits.contains(trait2)) {
        score += penalty;
      }
    }

    return max(0, min(15, score));
  }

  /// 에너지 레벨 (0: 낮음, 1: 보통, 2: 높음)
  static int _getEnergyLevel(List<PetTrait> traits) {
    final highEnergy = [PetTrait.active, PetTrait.playful, PetTrait.highEnergy];
    final lowEnergy = [PetTrait.calm, PetTrait.lazy, PetTrait.lowEnergy];

    int highCount = traits.where((t) => highEnergy.contains(t)).length;
    int lowCount = traits.where((t) => lowEnergy.contains(t)).length;

    if (highCount > lowCount) return 2;
    if (lowCount > highCount) return 0;
    return 1;
  }

  // ===== 4. 거리 (14점) =====
  static double _calculateDistanceScore(double? distanceMeters) {
    if (distanceMeters == null) return 7;

    if (distanceMeters <= 300) return 14;
    if (distanceMeters <= 500) return 12;
    if (distanceMeters <= 1000) return 10;
    if (distanceMeters <= 2000) return 8;
    if (distanceMeters <= 3000) return 6;
    if (distanceMeters <= 5000) return 4;
    if (distanceMeters <= 10000) return 2;
    return 1;
  }

  // ===== 5. 보호자 인증 (12점) =====
  static double _calculateVerificationScore(UserModel? user) {
    if (user == null) return 0;

    double score = 0;
    if (user.isIdentityVerified) score += 5;
    if (user.isLocationVerified) score += 4;
    if (user.isVerified) score += 3; // 동물등록 인증
    return min(12, score);
  }

  // ===== 6. 꼬순내 지수 (10점) =====
  static double _calculateActivityScore(UserModel? user) {
    if (user == null) return 0;

    // 활동 점수 계산
    final activityPoints = 
        (user.matchCount * 4) + 
        (user.walkCount * 2) + 
        (user.transactionCount * 3) + 
        (user.groupCount * 1);

    // 상위 퍼센트 기준 점수 (임시 기준값)
    if (activityPoints >= 50) return 10;  // 상위 5%
    if (activityPoints >= 30) return 8;   // 상위 15%
    if (activityPoints >= 15) return 6;   // 상위 30%
    if (activityPoints >= 5) return 4;    // 상위 50%
    return 2;
  }

  // ===== 7. 품종 궁합 (6점) =====
  static double _calculateBreedScore(PetModel myPet, PetModel otherPet) {
    double score = 0;

    // A. 품종 매칭 (4점)
    if (myPet.breed == null || otherPet.breed == null) {
      score += 2;
    } else if (myPet.breed == otherPet.breed) {
      score += 4;
    } else if (_isSameBreedGroup(myPet.breed!, otherPet.breed!)) {
      score += 2;
    } else {
      score += 1;
    }

    // B. 털 타입 매칭 (2점) - 품종으로 추정
    // 같은 품종이면 같은 털 타입
    if (myPet.breed == otherPet.breed) {
      score += 2;
    } else {
      score += 1;
    }

    return score;
  }

  /// 같은 품종 그룹인지 확인
  static bool _isSameBreedGroup(String breed1, String breed2) {
    final breedGroups = {
      'toy': ['말티즈', '치와와', '푸들', '비숑프리제', '시츄', '요크셔테리어', '포메라니안', '파피용'],
      'terrier': ['요크셔테리어', '웨스트하이랜드', '스코티시테리어', '잭러셀테리어', '불테리어'],
      'spitz': ['포메라니안', '사모예드', '시바이누', '스피츠', '허스키', '말라뮤트'],
      'retriever': ['골든리트리버', '래브라도리트리버', '플랫코티드리트리버'],
      'herding': ['보더콜리', '셔틀랜드쉽독', '웰시코기', '저먼셰퍼드', '벨지안셰퍼드'],
      'hound': ['비글', '바셋하운드', '닥스훈트', '그레이하운드', '아프간하운드'],
      'bulldog': ['프렌치불독', '잉글리시불독', '보스턴테리어', '퍼그'],
    };

    for (final group in breedGroups.values) {
      if (group.contains(breed1) && group.contains(breed2)) {
        return true;
      }
    }
    return false;
  }

  // ===== 8. 인기도 (6점) =====
  static double _calculatePopularityScore(PetModel pet) {
    final likes = pet.likeCount;
    if (likes >= 100) return 6;
    if (likes >= 50) return 5;
    if (likes >= 20) return 4;
    if (likes >= 10) return 3;
    if (likes >= 5) return 2;
    if (likes >= 1) return 1;
    return 0;
  }

  // ===== 9. 앱 활성도 (4점) =====
  static double _calculateActiveScore(UserModel? user) {
    if (user == null) return 0;

    final lastActive = user.lastActiveAt;
    if (lastActive == null) return 0;

    final minutesAgo = DateTime.now().difference(lastActive).inMinutes;

    if (minutesAgo <= 5) return 4;      // 현재 온라인
    if (minutesAgo <= 60) return 3;     // 1시간 내
    if (minutesAgo <= 1440) return 2;   // 24시간 내
    if (minutesAgo <= 10080) return 1;  // 7일 내
    return 0;
  }

  /// 추천 목록 생성 (점수순 정렬 + 다양성 확보)
  static List<MatchedPet> generateRecommendations({
    required PetModel myPet,
    required UserModel? myUser,
    required List<PetCandidate> candidates,
    int maxResults = 15,
  }) {
    final results = candidates.map((candidate) {
      final result = calculateCompatibility(
        myPet: myPet,
        otherPet: candidate.pet,
        myUser: myUser,
        otherUser: candidate.owner,
        distanceMeters: candidate.distanceMeters,
      );
      return MatchedPet(
        pet: candidate.pet,
        owner: candidate.owner,
        matchResult: result,
        distanceMeters: candidate.distanceMeters,
      );
    }).toList();

    // 점수순 정렬
    results.sort((a, b) => b.matchResult.score.compareTo(a.matchResult.score));

    // 다양성 확보: 상위 30개 중 랜덤 선택
    if (results.length > maxResults * 2) {
      final topCandidates = results.take(maxResults * 2).toList();
      topCandidates.shuffle(Random());
      return topCandidates.take(maxResults).toList();
    }

    return results.take(maxResults).toList();
  }
}

/// 매칭 결과
class MatchResult {
  final int score;
  final Map<String, double> details;
  final double? distanceMeters;

  const MatchResult({
    required this.score,
    required this.details,
    this.distanceMeters,
  });

  String get grade {
    if (score >= 85) return '최고';
    if (score >= 70) return '좋음';
    if (score >= 55) return '보통';
    if (score >= 40) return '낮음';
    return '매우 낮음';
  }

  String get description {
    if (score >= 85) return '환상의 궁합이에요! 🎉';
    if (score >= 70) return '잘 맞는 친구예요! 😊';
    if (score >= 55) return '괜찮은 친구가 될 수 있어요';
    if (score >= 40) return '조금 맞춰가야 할 수 있어요';
    return '서로 다른 점이 많아요';
  }

  String get distanceString {
    if (distanceMeters == null) return '';
    return LocationService.formatDistance(distanceMeters!);
  }
}

/// 후보 반려동물 (주인 정보 포함)
class PetCandidate {
  final PetModel pet;
  final UserModel? owner;
  final double? distanceMeters;

  const PetCandidate({
    required this.pet,
    this.owner,
    this.distanceMeters,
  });
}

/// 매칭된 반려동물 (결과용)
class MatchedPet {
  final PetModel pet;
  final UserModel? owner;
  final MatchResult matchResult;
  final double? distanceMeters;

  const MatchedPet({
    required this.pet,
    this.owner,
    required this.matchResult,
    this.distanceMeters,
  });

  String get distanceString {
    if (distanceMeters == null) return '';
    return LocationService.formatDistance(distanceMeters!);
  }
}
