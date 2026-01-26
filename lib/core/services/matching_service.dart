import 'dart:math';
import '../constants/pet_constants.dart';
import '../services/location_service.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';

/// ============================================================
/// 추천 매칭 알고리즘 서비스 (V4 - 기획서 기준 리팩토링)
/// 
/// 점수 배분 (총 100%):
/// - 체형 궁합: 20% (크기 12% + 체중 8%)
/// - 성격 궁합: 20% (보완 8% + 동일 7% + 에너지 5%)
/// - 거리: 15%
/// - 보호자 신뢰도: 15% (인증 9% + 꼬순내지수 6%)
/// - 인기도: 10% (상대적 계산 + 신규 부스트)
/// - 앱 활성도: 10%
/// - 나이 궁합: 5% (나이차 3% + 생애단계 2%)
/// - 품종 궁합: 5%
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

    // ===== 1. 체형 궁합 (20%) =====
    final bodyScore = _calculateBodyScore(myPet, otherPet);
    details['body'] = bodyScore;
    totalScore += bodyScore;

    // ===== 2. 성격 궁합 (20%) =====
    final traitScore = _calculateTraitScore(myPet, otherPet);
    details['traits'] = traitScore;
    totalScore += traitScore;

    // ===== 3. 거리 (15%) =====
    final distanceScore = _calculateDistanceScore(distanceMeters);
    details['distance'] = distanceScore;
    totalScore += distanceScore;

    // ===== 4. 보호자 신뢰도 (15% = 인증 9% + 꼬순내 6%) =====
    final trustScore = _calculateTrustScore(otherUser);
    details['trust'] = trustScore;
    totalScore += trustScore;

    // ===== 5. 인기도 (10%) =====
    final popularityScore = _calculatePopularityScore(otherPet);
    details['popularity'] = popularityScore;
    totalScore += popularityScore;

    // ===== 6. 앱 활성도 (10%) =====
    final activeScore = _calculateActiveScore(otherUser);
    details['active'] = activeScore;
    totalScore += activeScore;

    // ===== 7. 나이 궁합 (5%) =====
    final ageScore = _calculateAgeScore(myPet, otherPet);
    details['age'] = ageScore;
    totalScore += ageScore;

    // ===== 8. 품종 궁합 (5%) =====
    final breedScore = _calculateBreedScore(myPet, otherPet);
    details['breed'] = breedScore;
    totalScore += breedScore;

    return MatchResult(
      score: min(100, totalScore.round()),
      details: details,
      distanceMeters: distanceMeters,
    );
  }

  // ===== 1. 체형 궁합 (20%) =====
  static double _calculateBodyScore(PetModel myPet, PetModel otherPet) {
    double score = 0;

    // A. 크기 매칭 (12%)
    final mySize = myPet.size;
    final otherSize = otherPet.size;
    
    if (mySize != null && otherSize != null) {
      if (mySize == otherSize) {
        score += 12;
      } else {
        final sizeDiff = (mySize.index - otherSize.index).abs();
        if (sizeDiff == 1) score += 8;
        else if (sizeDiff == 2) score += 4;
        else score += 2;
      }
    } else {
      score += 6; // 정보 없으면 중간 점수
    }

    // B. 체중 차이 (8%)
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

  // ===== 7. 나이 궁합 (5%) =====
  static double _calculateAgeScore(PetModel myPet, PetModel otherPet) {
    double score = 0;
    final myAge = myPet.ageYears;
    final otherAge = otherPet.ageYears;

    // A. 나이 차이 (3%)
    if (myAge != null && otherAge != null) {
      final ageDiff = (myAge - otherAge).abs();
      if (ageDiff == 0) score += 3;
      else if (ageDiff == 1) score += 2.5;
      else if (ageDiff == 2) score += 2;
      else if (ageDiff == 3) score += 1;
      else score += 0.5;

      // B. 생애 단계 매칭 (2%)
      final myStage = _getLifeStage(myAge);
      final otherStage = _getLifeStage(otherAge);
      final stageDiff = (myStage - otherStage).abs();
      
      if (stageDiff == 0) score += 2;
      else if (stageDiff == 1) score += 1;
      else score += 0.5;
    } else {
      score += 2.5; // 정보 없으면 중간 점수
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

  // ===== 2. 성격 궁합 (20%) =====
  static double _calculateTraitScore(PetModel myPet, PetModel otherPet) {
    if (myPet.traits.isEmpty || otherPet.traits.isEmpty) {
      return 10; // 정보 없으면 중간 점수
    }

    double score = 0;

    // A. 상호 보완 특성 (8%)
    final synergyPairs = [
      (PetTrait.active, PetTrait.calm, 4.0),
      (PetTrait.curious, PetTrait.gentle, 2.5),
      (PetTrait.playful, PetTrait.gentle, 2.5),
      (PetTrait.independent, PetTrait.affectionate, 2.0),
      (PetTrait.brave, PetTrait.shy, 2.0),
    ];

    for (final (trait1, trait2, points) in synergyPairs) {
      if ((myPet.traits.contains(trait1) && otherPet.traits.contains(trait2)) ||
          (myPet.traits.contains(trait2) && otherPet.traits.contains(trait1))) {
        score += points;
        if (score >= 8) break;
      }
    }
    score = min(8, score);

    // B. 같은 특성 매칭 (7%)
    final commonCount = myPet.traits.where((t) => otherPet.traits.contains(t)).length;
    score += min(7, commonCount * 1.4);

    // C. 에너지 레벨 매칭 (5%)
    final myEnergy = _getEnergyLevel(myPet.traits);
    final otherEnergy = _getEnergyLevel(otherPet.traits);
    if (myEnergy == otherEnergy) {
      score += 5;
    } else if ((myEnergy - otherEnergy).abs() == 1) {
      score += 2.5;
    }

    // D. 충돌 특성 감점
    final conflictPairs = [
      (PetTrait.dominant, PetTrait.dominant, -3.0),
      (PetTrait.territorial, PetTrait.territorial, -3.0),
      (PetTrait.fearfulOfPets, PetTrait.dominant, -2.0),
    ];

    for (final (trait1, trait2, penalty) in conflictPairs) {
      if (myPet.traits.contains(trait1) && otherPet.traits.contains(trait2)) {
        score += penalty;
      }
    }

    return max(0, min(20, score));
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

  // ===== 4. 거리 (15%) =====
  static double _calculateDistanceScore(double? distanceMeters) {
    if (distanceMeters == null) return 7.5;

    if (distanceMeters <= 300) return 15;
    if (distanceMeters <= 500) return 13;
    if (distanceMeters <= 1000) return 11;
    if (distanceMeters <= 2000) return 9;
    if (distanceMeters <= 3000) return 7;
    if (distanceMeters <= 5000) return 5;
    if (distanceMeters <= 10000) return 3;
    return 1;
  }

  // ===== 5. 보호자 신뢰도 (15% = 인증 9% + 꼬순내 6%) =====
  static double _calculateTrustScore(UserModel? user) {
    if (user == null) return 0;

    double score = 0;
    
    // A. 인증 점수 (9%)
    if (user.isIdentityVerified) score += 4;  // 본인인증
    if (user.isLocationVerified) score += 3;  // 위치인증
    if (user.isVerified) score += 2;          // 동물등록 인증
    
    // B. 꼬순내 지수 (6%) - 실제 점수 직접 사용
    final kkosunnaeScore = user.kkosunnaeScore ?? 50;
    score += (kkosunnaeScore / 100) * 6;
    
    return min(15, score);
  }

  // ===== 8. 품종 궁합 (5%) =====
  static double _calculateBreedScore(PetModel myPet, PetModel otherPet) {
    double score = 0;

    // A. 품종 매칭 (3%)
    if (myPet.breed == null || otherPet.breed == null) {
      score += 1.5;
    } else if (myPet.breed == otherPet.breed) {
      score += 3;
    } else if (_isSameBreedGroup(myPet.breed!, otherPet.breed!)) {
      score += 2;
    } else {
      score += 1;
    }

    // B. 털 타입 매칭 (2%) - 품종으로 추정
    if (myPet.breed == otherPet.breed) {
      score += 2;
    } else if (_isSameBreedGroup(myPet.breed ?? '', otherPet.breed ?? '')) {
      score += 1.5;
    } else {
      score += 0.5;
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

  // ===== 7. 인기도 (10%) - 부익부 방지 + 신규 부스트 =====
  static double _calculatePopularityScore(PetModel pet) {
    double score = 0;
    final likes = pet.likeCount;
    
    // A. 상대적 인기도 (7%) - 일평균 좋아요 기준
    final daysActive = DateTime.now().difference(pet.createdAt).inDays + 1;
    final likesPerDay = likes / daysActive;
    
    if (likesPerDay >= 3) score += 7;
    else if (likesPerDay >= 2) score += 6;
    else if (likesPerDay >= 1) score += 5;
    else if (likesPerDay >= 0.5) score += 4;
    else if (likesPerDay >= 0.2) score += 3;
    else if (likes >= 1) score += 2;
    else score += 1;
    
    // B. 신규 가입자 부스트 (3%) - 가입 30일 이내
    if (daysActive <= 30) {
      score += 3;
    } else if (daysActive <= 60) {
      score += 1.5;
    }
    
    return min(10, score);
  }

  // ===== 6. 앱 활성도 (10%) =====
  static double _calculateActiveScore(UserModel? user) {
    if (user == null) return 0;

    final minutesAgo = DateTime.now().difference(user.lastActiveAt).inMinutes;

    if (minutesAgo <= 5) return 10;      // 현재 온라인
    if (minutesAgo <= 30) return 8;      // 30분 내
    if (minutesAgo <= 60) return 7;      // 1시간 내
    if (minutesAgo <= 360) return 6;     // 6시간 내
    if (minutesAgo <= 1440) return 4;    // 24시간 내
    if (minutesAgo <= 4320) return 2;    // 3일 내
    if (minutesAgo <= 10080) return 1;   // 7일 내
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
