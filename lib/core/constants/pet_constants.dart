import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 반려동물 전용 앱 상수
/// 
/// 이 앱은 반려동물(강아지) 전용 서비스입니다.
/// - 반려동물 품종, 크기, 성별
/// - 특성 (50개)
/// - 건강수첩 카테고리
/// - 사용자(보호자) 성별
/// - 인증 배지
/// - 교배 관련 상수
/// ============================================================

// ============================================================
// 사용자(보호자) 관련 상수
// ============================================================

/// 사용자(보호자) 성별
/// - 안전한 만남을 위해 보호자 성별 정보 필수
enum UserGender {
  male('남성', Icons.male),
  female('여성', Icons.female);

  final String label;
  final IconData icon;

  const UserGender(this.label, this.icon);
}

// ============================================================
// 반려동물 관련 상수
// ============================================================

/// 반려동물 크기 (체중 기준)
/// - 교배 매칭 시 크기 호환성 체크에 사용
enum PetSize {
  tiny('초소형', 0, 4),      // ~4kg (치와와, 요크셔테리어 등)
  small('소형', 4, 10),      // 4~10kg (말티즈, 푸들 등)
  medium('중형', 10, 25),    // 10~25kg (코카스파니엘, 비글 등)
  large('대형', 25, 45),     // 25~45kg (골든리트리버, 래브라도 등)
  giant('초대형', 45, 100);  // 45kg~ (그레이트데인, 세인트버나드 등)

  final String label;
  final double minWeight;
  final double maxWeight;

  const PetSize(this.label, this.minWeight, this.maxWeight);

  /// 체중으로 크기 분류 자동 계산
  static PetSize fromWeight(double weight) {
    if (weight < 4) return PetSize.tiny;
    if (weight < 10) return PetSize.small;
    if (weight < 25) return PetSize.medium;
    if (weight < 45) return PetSize.large;
    return PetSize.giant;
  }
}

/// 반려동물 성별
/// - 교배 매칭 시 필수 정보
enum PetGender {
  male('남아', Icons.male),
  female('여아', Icons.female);

  final String label;
  final IconData icon;

  const PetGender(this.label, this.icon);
}

/// ============================================================
/// 반려동물 특성 (50개)
/// 프로필 등록 시 최소 5개 이상 선택 필요
/// - AI 궁합 매칭에 활용
/// - 교배 상대 필터링에 활용
/// ============================================================
enum PetTrait {
  // ===== 성격/기질 (15개) =====
  active('활발함', '에너지가 넘치고 활동적이에요', PetTraitCategory.personality),
  calm('차분함', '조용하고 안정적이에요', PetTraitCategory.personality),
  friendly('친화적', '다른 반려동물/사람과 잘 어울려요', PetTraitCategory.personality),
  shy('수줍음', '낯을 많이 가려요', PetTraitCategory.personality),
  playful('장난꾸러기', '놀기를 좋아해요', PetTraitCategory.personality),
  independent('독립적', '혼자서도 잘 지내요', PetTraitCategory.personality),
  affectionate('애교쟁이', '애정 표현을 많이 해요', PetTraitCategory.personality),
  protective('보호본능', '가족을 지키려 해요', PetTraitCategory.personality),
  curious('호기심 많음', '새로운 것에 관심이 많아요', PetTraitCategory.personality),
  stubborn('고집쟁이', '자기 주장이 강해요', PetTraitCategory.personality),
  gentle('온순함', '순하고 부드러워요', PetTraitCategory.personality),
  brave('용감함', '겁이 없고 대담해요', PetTraitCategory.personality),
  lazy('느긋함', '여유롭고 게으른 편이에요', PetTraitCategory.personality),
  loyal('충성스러움', '주인에게 충성스러워요', PetTraitCategory.personality),
  smart('똑똑함', '영리하고 학습이 빨라요', PetTraitCategory.personality),

  // ===== 사회성 (10개) =====
  lovesPeople('사람 좋아함', '사람을 좋아해요', PetTraitCategory.social),
  lovesKids('아이 좋아함', '어린이와 잘 지내요', PetTraitCategory.social),
  lovesPets('반려동물 좋아함', '다른 반려동물과 잘 어울려요', PetTraitCategory.social),
  goodWithSmallPets('소형견과 잘 지냄', '소형견과 잘 어울려요', PetTraitCategory.social),
  fearfulOfPeople('사람 무서워함', '낯선 사람을 무서워해요', PetTraitCategory.social),
  fearfulOfPets('반려동물 무서워함', '다른 반려동물을 무서워해요', PetTraitCategory.social),
  goodWithLargePets('대형견과 잘 지냄', '대형견과 잘 어울려요', PetTraitCategory.social),
  territorial('영역의식', '자기 영역을 지키려 해요', PetTraitCategory.social),
  dominant('지배적', '다른 반려동물 위에 서려 해요', PetTraitCategory.social),
  submissive('순종적', '다른 반려동물에게 양보해요', PetTraitCategory.social),

  // ===== 행동 특성 (15개) =====
  barksALot('짖음 많음', '자주 짖어요', PetTraitCategory.behavior),
  quietType('조용함', '거의 짖지 않아요', PetTraitCategory.behavior),
  chewer('씹기 좋아함', '물건을 씹는 걸 좋아해요', PetTraitCategory.behavior),
  digger('땅파기 좋아함', '땅 파는 걸 좋아해요', PetTraitCategory.behavior),
  jumper('점프 좋아함', '뛰어오르는 걸 좋아해요', PetTraitCategory.behavior),
  swimmer('수영 좋아함', '물놀이를 좋아해요', PetTraitCategory.behavior),
  fetcher('공놀이 좋아함', '물건 가져오기를 좋아해요', PetTraitCategory.behavior),
  cuddler('안기기 좋아함', '안기는 걸 좋아해요', PetTraitCategory.behavior),
  explorer('탐험가', '새로운 곳을 탐험해요', PetTraitCategory.behavior),
  homebody('집순이/집돌이', '집에 있는 걸 좋아해요', PetTraitCategory.behavior),
  foodLover('먹보', '먹는 걸 좋아해요', PetTraitCategory.behavior),
  pickyEater('입이 까다로움', '음식을 가려요', PetTraitCategory.behavior),
  sleepyHead('잠꾸러기', '잠을 많이 자요', PetTraitCategory.behavior),
  nightOwl('야행성', '밤에 활동적이에요', PetTraitCategory.behavior),
  earlyBird('아침형', '아침에 활동적이에요', PetTraitCategory.behavior),

  // ===== 민감성/건강 (10개) =====
  sensitive('예민함', '자극에 민감해요', PetTraitCategory.sensitivity),
  anxious('불안함', '불안해하는 경향이 있어요', PetTraitCategory.sensitivity),
  separationAnxiety('분리불안', '혼자 있으면 불안해해요', PetTraitCategory.sensitivity),
  noiseSensitive('소음 민감', '큰 소리에 민감해요', PetTraitCategory.sensitivity),
  weatherSensitive('날씨 민감', '날씨 변화에 민감해요', PetTraitCategory.sensitivity),
  allergic('알러지 있음', '알러지가 있어요', PetTraitCategory.sensitivity),
  strongStomach('위장 튼튼', '소화력이 좋아요', PetTraitCategory.sensitivity),
  weakStomach('위장 약함', '소화가 약해요', PetTraitCategory.sensitivity),
  highEnergy('에너지 높음', '운동량이 많이 필요해요', PetTraitCategory.sensitivity),
  lowEnergy('에너지 낮음', '운동량이 적어도 돼요', PetTraitCategory.sensitivity);

  final String label;
  final String description;
  final PetTraitCategory category;

  const PetTrait(this.label, this.description, this.category);
}

/// 특성 카테고리
enum PetTraitCategory {
  personality('성격/기질'),
  social('사회성'),
  behavior('행동 특성'),
  sensitivity('민감성/건강');

  final String label;

  const PetTraitCategory(this.label);
}

/// ============================================================
/// 건강수첩 카테고리
/// 
/// 변경사항 (리팩토링):
/// - 대변/소변/음수 제거 (사용자 요청)
/// - 산책은 메인화면에서 직접 접근 가능
/// - 메인화면 표시 가능 여부 (canShowOnHome)
/// ============================================================
enum HealthCategory {
  // ===== 건강수첩 카테고리 (건강수첩 화면과 동기화) =====
  weight('체중', Icons.monitor_weight_outlined, '체중 변화를 기록해요', true),
  walk('산책', Icons.directions_walk, '산책 시간과 거리를 기록해요', true),
  grooming('그루밍', Icons.content_cut, '미용/위생 관리를 기록해요', true),
  medication('약', Icons.medication_outlined, '복용 중인 약을 관리해요', true),
  vaccination('예방접종', Icons.vaccines_outlined, '예방접종 일정을 관리해요', true),
  checkup('정기검진', Icons.local_hospital_outlined, '정기검진 일정을 관리해요', true),
  special('특이사항', Icons.note_alt_outlined, '기타 특이사항을 기록해요', true);

  final String label;
  final IconData icon;
  final String description;
  final bool canShowOnHome;

  const HealthCategory(this.label, this.icon, this.description, this.canShowOnHome);
  
  /// 메인화면에 표시 가능한 카테고리 목록
  static List<HealthCategory> get homeDisplayable => 
      values.where((c) => c.canShowOnHome).toList();
}

/// 그루밍 세부 항목
/// - 샤워, 빗질, 발톱정리, 이발, 귀청소 등
enum GroomingType {
  shower('샤워', Icons.shower_outlined, '목욕/샤워'),
  brushing('빗질', Icons.brush_outlined, '털 빗질'),
  nailTrim('발톱정리', Icons.content_cut, '발톱 깎기'),
  haircut('이발', Icons.cut_outlined, '털 미용/커트'),
  earCleaning('귀청소', Icons.hearing_outlined, '귀 청소'),
  eyeCleaning('눈물자국', Icons.visibility_outlined, '눈물자국 닦기'),
  analGland('항문낭', Icons.circle_outlined, '항문낭 짜기'),
  pawCare('발바닥', Icons.pets, '발바닥 관리'),
  teethBrushing('양치', Icons.clean_hands_outlined, '양치질'),
  teethScaling('치석제거', Icons.auto_fix_high, '치석 제거/스케일링'),
  other('기타', Icons.more_horiz, '기타 그루밍');

  final String label;
  final IconData icon;
  final String description;

  const GroomingType(this.label, this.icon, this.description);
}

/// 약 복용 간격
enum MedicationInterval {
  asNeeded('필요시', null),
  everyHours('시간마다', 'hours'),
  daily('매일', 'days'),
  weekly('매주', 'weeks'),
  monthly('매월', 'months');

  final String label;
  final String? unit;

  const MedicationInterval(this.label, this.unit);
}

/// ============================================================
/// 약 아이콘 색상 타입
/// 
/// Material Icons의 medication 아이콘 + 색상으로 구분
/// 저장 시 id를 사용하여 저장
/// 색상은 구분이 명확한 5가지만 사용
/// ============================================================
enum MedicationIconType {
  blue('blue', 0xFF2196F3),
  pink('pink', 0xFFE91E63),
  orange('orange', 0xFFFF9800),
  green('green', 0xFF4CAF50),
  purple('purple', 0xFF7B1FA2);

  final String id;
  final int colorValue;

  const MedicationIconType(this.id, this.colorValue);

  /// ID로 MedicationIconType 찾기
  static MedicationIconType fromId(String id) {
    return MedicationIconType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => MedicationIconType.blue,
    );
  }

  /// 레거시 데이터 호환 (기존 pill_blue 등의 형식)
  static MedicationIconType fromLegacyId(String legacyId) {
    if (legacyId.contains('blue')) return MedicationIconType.blue;
    if (legacyId.contains('pink')) return MedicationIconType.pink;
    if (legacyId.contains('orange')) return MedicationIconType.orange;
    if (legacyId.contains('green')) return MedicationIconType.green;
    // 기타 색상은 보라로 매핑
    return MedicationIconType.purple;
  }
}

/// ============================================================
/// 인증 배지 종류
/// 
/// 변경사항 (리팩토링):
/// - 예방접종 인증 제거 (통합 API 없음)
/// - 위치 인증 추가 (당근마켓 스타일)
/// ============================================================
enum BadgeType {
  identity('본인인증', Icons.verified_user_outlined, '본인 인증을 완료했어요'),
  location('위치인증', Icons.location_on_outlined, '동네 인증을 완료했어요'),
  petRegistration('동물등록', Icons.pets, '동물등록 인증을 완료했어요');

  final String label;
  final IconData icon;
  final String description;

  const BadgeType(this.label, this.icon, this.description);
}

/// ============================================================
/// 소모임 카테고리
/// ============================================================
enum GroupCategory {
  walk('산책 모임', Icons.directions_walk_outlined, '함께 산책해요'),
  play('놀이 모임', Icons.sports_tennis_outlined, '함께 놀아요'),
  share('나눔 모임', Icons.card_giftcard_outlined, '물품을 나눠요'),
  coffee('커피 모임', Icons.coffee_outlined, '보호자끼리 모여요'),
  training('훈련 모임', Icons.school_outlined, '함께 훈련해요'),
  health('건강 모임', Icons.fitness_center_outlined, '건강 정보를 나눠요'),
  other('기타', Icons.more_horiz_outlined, '기타 모임이에요');

  final String label;
  final IconData icon;
  final String description;

  const GroupCategory(this.label, this.icon, this.description);
}

/// 하위 호환성을 위한 별칭
@Deprecated('GroupCategory를 사용하세요')
typedef CommunityCategory = GroupCategory;

/// 소모임 제한 타입
enum GroupRestriction {
  none('제한 없음'),
  petTypeOnly('종류 제한'),
  weightOnly('체중 제한'),
  petTypeAndWeight('종류+체중 제한');

  final String label;

  const GroupRestriction(this.label);
}

/// 하위 호환성을 위한 별칭
@Deprecated('GroupRestriction을 사용하세요')
typedef CommunityRestriction = GroupRestriction;

/// ============================================================
/// 채팅 타입
/// 
/// 변경사항 (리팩토링):
/// - 교배 채팅 타입 분리 (배지 표시용)
/// ============================================================
enum ChatType {
  dating('데이팅', Icons.favorite, '친구 만들기 채팅'),
  breeding('교배', Icons.pets, '교배 상대 채팅'),
  group('소모임', Icons.groups, '소모임 채팅'),
  market('마켓', Icons.storefront, '중고거래 채팅');

  final String label;
  final IconData icon;
  final String description;

  const ChatType(this.label, this.icon, this.description);
  
  /// 교배 채팅인지 확인
  bool get isBreeding => this == ChatType.breeding;
  
  /// 소모임 채팅인지 확인
  bool get isGroup => this == ChatType.group;
}

/// ============================================================
/// 위치 관련 상수
/// ============================================================
class LocationConstants {
  LocationConstants._();
  
  /// 집 반경 안전구역 (200m) - 산책 기능 비활성화
  static const double homeSafetyRadiusMeters = 200.0;
  
  /// 마켓 기본 거리 필터 (1.5km)
  static const double marketDefaultRadiusKm = 1.5;
  
  /// 마켓 최대 거리 필터 (10km)
  static const double marketMaxRadiusKm = 10.0;
  
  /// 소모임 기본 거리 필터 (5km)
  static const double communityDefaultRadiusKm = 5.0;
  
  /// 위치 인증 반경 (당근마켓 스타일)
  static const double locationVerificationRadiusKm = 6.0;
  
  // ===== 위치 인증 시스템 상수 =====
  
  /// 위치 불일치 알림 기준 (3km)
  /// - 저장된 위치와 현재 위치가 이 거리 이상 차이나면 알림 표시
  static const double mismatchThresholdMeters = 3000.0;
  
  /// 위치 인증 허용 거리 (500m)
  /// - 저장된 위치에서 이 거리 이내에서만 재인증 가능
  static const double verificationRadiusMeters = 500.0;
  
  /// 위치 인증 "조금 더 가까이" 안내 거리 (1km)
  /// - 500m~1km 사이면 "조금 더 가까이 이동해주세요" 안내
  static const double verificationNearbyMeters = 1000.0;
  
  /// 재알림 방지 시간 (24시간)
  /// - "무시" 클릭 후 이 시간 동안 알림 표시 안 함
  static const int reminderCooldownHours = 24;
  
  /// 위치 체크 캐시 유효 시간 (5분)
  /// - 앱 시작 시 위치 체크 결과 캐싱
  static const int locationCheckCacheMinutes = 5;
  
  /// 위치 인증 만료 기간 (90일)
  /// - 인증 후 이 기간이 지나면 재인증 필요
  static const int verificationExpirationDays = 90;
}

// ============================================================
// 교배 관련 상수
// ============================================================

/// 교배 신청 상태
enum BreedingRequestStatus {
  pending('대기중', '상대방의 수락을 기다리고 있어요'),
  accepted('수락됨', '교배 신청이 수락되었어요'),
  rejected('거절됨', '교배 신청이 거절되었어요'),
  cancelled('취소됨', '교배 신청이 취소되었어요');

  final String label;
  final String description;

  const BreedingRequestStatus(this.label, this.description);
}

/// 교배 필터 옵션
class BreedingFilterOptions {
  BreedingFilterOptions._();
  
  /// 거리 필터 옵션 (km)
  static const List<double> distanceOptions = [5, 10, 20, 50, 100];
  
  /// 나이 필터 옵션 (년)
  static const List<int> ageMinOptions = [1, 2, 3, 4, 5];
  static const List<int> ageMaxOptions = [3, 5, 7, 10, 15];
  
  /// 체중 필터 옵션 (kg)
  static const List<double> weightMinOptions = [0, 4, 10, 25, 45];
  static const List<double> weightMaxOptions = [4, 10, 25, 45, 100];
}

/// 인기 품종 목록 (한국 기준, 강아지)
class PetBreeds {
  PetBreeds._();
  
  static const List<String> popular = [
    '말티즈',
    '푸들',
    '포메라니안',
    '치와와',
    '시츄',
    '요크셔테리어',
    '비숑 프리제',
    '골든 리트리버',
    '래브라도 리트리버',
    '웰시코기',
    '프렌치 불독',
    '비글',
    '슈나우저',
    '코카스파니엘',
    '진돗개',
    '시바견',
    '사모예드',
    '허스키',
    '보더콜리',
    '닥스훈트',
    '믹스견',
    '기타',
  ];
}
