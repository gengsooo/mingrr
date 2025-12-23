import 'dart:math';
import '../constants/pet_constants.dart';
import '../../models/pet_model.dart';

/// ============================================================
/// AI 매칭 알고리즘 서비스 (V2 - 강아지 전용)
/// 
/// 우선순위: 품종 > 체중 > 특성 > 성별 > 나이
/// 산책중인 강아지 우선 추천
/// ============================================================

class MatchingService {
  MatchingService._();

  /// 궁합 점수 계산 (0~100)
  /// [myDog] 내 강아지
  /// [otherDog] 상대 강아지
  /// [isWalking] 상대가 현재 산책중인지
  /// [lastWalkMinutesAgo] 마지막 산책이 몇 분 전인지 (null이면 산책 기록 없음)
  static MatchResult calculateCompatibility({
    required DogModel myDog,
    required DogModel otherDog,
    bool isWalking = false,
    int? lastWalkMinutesAgo,
  }) {
    double totalScore = 0;
    final details = <String, double>{};

    // ===== 1. 품종 일치 (최우선, 40점) =====
    final breedScore = _calculateBreedScore(myDog, otherDog);
    details['breed'] = breedScore;
    totalScore += breedScore;

    // ===== 2. 체중/크기 유사도 (2순위, 25점) =====
    final weightScore = _calculateWeightScore(myDog, otherDog);
    details['weight'] = weightScore;
    totalScore += weightScore;

    // ===== 3. 특성 궁합 (15점) =====
    final traitScore = _calculateTraitScore(myDog, otherDog);
    details['traits'] = traitScore;
    totalScore += traitScore;

    // ===== 4. 성별 (10점) =====
    final genderScore = _calculateGenderScore(myDog, otherDog);
    details['gender'] = genderScore;
    totalScore += genderScore;

    // ===== 5. 나이 유사도 (10점) =====
    final ageScore = _calculateAgeScore(myDog, otherDog);
    details['age'] = ageScore;
    totalScore += ageScore;

    // ===== 산책 보너스 (추가 점수, 최대 +10) =====
    double walkBonus = 0;
    if (isWalking) {
      walkBonus = 10; // 현재 산책중이면 +10
    } else if (lastWalkMinutesAgo != null) {
      if (lastWalkMinutesAgo <= 30) {
        walkBonus = 8; // 30분 이내 산책
      } else if (lastWalkMinutesAgo <= 60) {
        walkBonus = 5; // 1시간 이내 산책
      } else if (lastWalkMinutesAgo <= 180) {
        walkBonus = 2; // 3시간 이내 산책
      }
    }
    details['walkBonus'] = walkBonus;

    // 최종 점수 (100점 만점으로 정규화)
    final finalScore = min(100, totalScore + walkBonus);

    return MatchResult(
      score: finalScore.round(),
      details: details,
      isWalking: isWalking,
      lastWalkMinutesAgo: lastWalkMinutesAgo,
    );
  }

  /// 품종 일치 점수 (40점 만점)
  static double _calculateBreedScore(DogModel myDog, DogModel otherDog) {
    // 품종 정보가 없으면 기본 점수
    if (myDog.breed == null || otherDog.breed == null) {
      return 20;
    }
    
    // 같은 품종이면 만점
    if (myDog.breed == otherDog.breed) {
      return 40;
    }
    
    // 비슷한 크기의 품종이면 부분 점수
    if (myDog.size == otherDog.size) {
      return 25;
    }
    
    return 15; // 다른 품종
  }

  /// 체중/크기 유사도 점수 (25점 만점)
  static double _calculateWeightScore(DogModel myDog, DogModel otherDog) {
    // 체중 정보가 없으면 기본 점수
    if (myDog.weight == null || otherDog.weight == null) {
      return 12.5;
    }

    final mySize = myDog.size;
    final otherSize = otherDog.size;

    // 같은 크기 분류면 만점
    if (mySize == otherSize) {
      return 25;
    }

    // 크기 차이에 따른 점수
    final sizeDiff = (mySize!.index - otherSize!.index).abs();
    switch (sizeDiff) {
      case 1:
        return 18; // 한 단계 차이
      case 2:
        return 10; // 두 단계 차이
      case 3:
        return 5;  // 세 단계 차이
      default:
        return 2;  // 그 이상
    }
  }

  /// 특성 궁합 점수 (15점 만점)
  static double _calculateTraitScore(DogModel myDog, DogModel otherDog) {
    if (myDog.traits.isEmpty || otherDog.traits.isEmpty) {
      return 7.5; // 특성 정보 없으면 기본 점수
    }

    double score = 0;

    // 1. 공통 특성 점수 (최대 8점)
    final commonTraits = myDog.traits
        .where((t) => otherDog.traits.contains(t))
        .length;
    score += min(8, commonTraits * 2);

    // 2. 상호 보완 특성 점수 (최대 7점)
    final complementaryScore = _calculateComplementaryTraits(myDog, otherDog);
    score += complementaryScore;

    return min(15, score);
  }

  /// 상호 보완 특성 점수
  static double _calculateComplementaryTraits(DogModel myDog, DogModel otherDog) {
    double score = 0;

    // 상호 보완되는 특성 쌍
    final complementaryPairs = [
      {DogTrait.active, DogTrait.playful},
      {DogTrait.calm, DogTrait.gentle},
      {DogTrait.friendly, DogTrait.lovesPeople},
      {DogTrait.affectionate, DogTrait.cuddler},
      {DogTrait.brave, DogTrait.protective},
      {DogTrait.shy, DogTrait.gentle},
      {DogTrait.independent, DogTrait.calm},
    ];

    for (final pair in complementaryPairs) {
      final pairList = pair.toList();
      if ((myDog.traits.contains(pairList[0]) && otherDog.traits.contains(pairList[1])) ||
          (myDog.traits.contains(pairList[1]) && otherDog.traits.contains(pairList[0]))) {
        score += 1.5;
      }
    }

    // 상충되는 특성 (감점) - 둘 다 같은 특성을 가진 경우 충돌
    final conflictingSameTraits = [
      DogTrait.dominant,      // 둘 다 지배적이면 충돌
      DogTrait.territorial,   // 둘 다 영역의식 강하면 충돌
    ];
    
    for (final trait in conflictingSameTraits) {
      if (myDog.traits.contains(trait) && otherDog.traits.contains(trait)) {
        score -= 1;
      }
    }
    
    // 상충되는 특성 쌍 (서로 다른 특성)
    final conflictingPairs = [
      [DogTrait.anxious, DogTrait.barksALot],
      [DogTrait.fearfulOfDogs, DogTrait.dominant],
    ];

    for (final pair in conflictingPairs) {
      final pairList = pair.toList();
      if (myDog.traits.contains(pairList[0]) && otherDog.traits.contains(pairList[1])) {
        score -= 1;
      }
    }

    return max(0, min(7, score));
  }

  /// 성별 점수 (10점 만점)
  static double _calculateGenderScore(DogModel myDog, DogModel otherDog) {
    // 교배 목적이면 이성 선호
    if (myDog.isBreedingAvailable && otherDog.isBreedingAvailable) {
      return myDog.gender != otherDog.gender ? 10 : 3;
    }

    // 일반적인 경우 동성/이성 상관없이 기본 점수
    // 중성화 여부에 따라 조정
    if (myDog.isNeutered && otherDog.isNeutered) {
      return 8; // 둘 다 중성화면 성별 무관
    }

    return 6; // 기본 점수
  }

  /// 나이 유사도 점수 (10점 만점)
  static double _calculateAgeScore(DogModel myDog, DogModel otherDog) {
    final myAge = myDog.ageYears;
    final otherAge = otherDog.ageYears;

    if (myAge == null || otherAge == null) {
      return 5; // 나이 정보 없으면 기본 점수
    }

    final ageDiff = (myAge - otherAge).abs();

    if (ageDiff == 0) return 10;
    if (ageDiff == 1) return 8;
    if (ageDiff == 2) return 6;
    if (ageDiff <= 4) return 4;
    return 2;
  }

  /// 추천 목록 정렬 (궁합 점수 + 산책 상태 기준)
  static List<MatchedDog> sortByCompatibility({
    required DogModel myDog,
    required List<DogWithStatus> candidates,
  }) {
    final results = candidates.map((candidate) {
      final result = calculateCompatibility(
        myDog: myDog,
        otherDog: candidate.dog,
        isWalking: candidate.isWalking,
        lastWalkMinutesAgo: candidate.lastWalkMinutesAgo,
      );
      return MatchedDog(
        dog: candidate.dog,
        matchResult: result,
        distance: candidate.distance,
      );
    }).toList();

    // 정렬: 산책중 > 궁합점수 > 거리
    results.sort((a, b) {
      // 1. 산책중인 반려동물 우선
      if (a.matchResult.isWalking && !b.matchResult.isWalking) return -1;
      if (!a.matchResult.isWalking && b.matchResult.isWalking) return 1;

      // 2. 최근 산책한 반려동물 우선
      final aWalk = a.matchResult.lastWalkMinutesAgo ?? 9999;
      final bWalk = b.matchResult.lastWalkMinutesAgo ?? 9999;
      if (aWalk < 60 && bWalk >= 60) return -1;
      if (aWalk >= 60 && bWalk < 60) return 1;

      // 3. 궁합 점수 높은 순
      final scoreCompare = b.matchResult.score.compareTo(a.matchResult.score);
      if (scoreCompare != 0) return scoreCompare;

      // 4. 거리 가까운 순
      if (a.distance != null && b.distance != null) {
        return a.distance!.compareTo(b.distance!);
      }

      return 0;
    });

    return results;
  }
}

/// 매칭 결과
class MatchResult {
  final int score; // 0~100
  final Map<String, double> details;
  final bool isWalking;
  final int? lastWalkMinutesAgo;

  const MatchResult({
    required this.score,
    required this.details,
    this.isWalking = false,
    this.lastWalkMinutesAgo,
  });

  /// 궁합 등급
  String get grade {
    if (score >= 90) return '최고';
    if (score >= 75) return '좋음';
    if (score >= 60) return '보통';
    if (score >= 40) return '낮음';
    return '매우 낮음';
  }

  /// 궁합 설명
  String get description {
    if (score >= 90) return '환상의 궁합이에요! 🎉';
    if (score >= 75) return '잘 맞는 친구예요! 😊';
    if (score >= 60) return '괜찮은 친구가 될 수 있어요';
    if (score >= 40) return '조금 맞춰가야 할 수 있어요';
    return '서로 다른 점이 많아요';
  }
}

/// 상태 포함 강아지 (후보 목록용)
class DogWithStatus {
  final DogModel dog;
  final bool isWalking;
  final int? lastWalkMinutesAgo;
  final double? distance; // 미터 단위

  const DogWithStatus({
    required this.dog,
    this.isWalking = false,
    this.lastWalkMinutesAgo,
    this.distance,
  });
}

/// 매칭된 강아지 (결과용)
class MatchedDog {
  final DogModel dog;
  final MatchResult matchResult;
  final double? distance;

  const MatchedDog({
    required this.dog,
    required this.matchResult,
    this.distance,
  });
}
