import 'package:flutter/material.dart';
import 'app_icons.dart';

/// ============================================================
/// MINGRR 반려동물 전용 앱 상수
/// 
/// 이 앱은 반려동물 전용 서비스입니다.
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
  male('남성', AppIcons.male),
  female('여성', AppIcons.female);

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

  /// enum name(영문)으로 한글 라벨 반환
  /// Firestore에 영문으로 저장된 크기 값을 UI에 표시할 때 사용
  static String labelFromName(String name) {
    final size = PetSize.values.where((e) => e.name == name).firstOrNull;
    return size?.label ?? name;
  }
}

/// 반려동물 성별
/// - 교배 매칭 시 필수 정보
enum PetGender {
  male('남아', AppIcons.male),
  female('여아', AppIcons.female);

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

  /// enum name(영문)으로 한글 라벨 반환
  /// Firestore에 영문으로 저장된 특성 값을 UI에 표시할 때 사용
  static String labelFromName(String name) {
    final trait = PetTrait.values.where((e) => e.name == name).firstOrNull;
    return trait?.label ?? name;
  }
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
  weight('체중', AppIcons.weight, '체중 변화를 기록해요', true),
  walk('산책', AppIcons.walk, '산책 시간과 거리를 기록해요', true),
  grooming('그루밍', AppIcons.grooming, '미용/위생 관리를 기록해요', true),
  medication('약', AppIcons.medication, '복용 중인 약을 관리해요', true),
  vaccination('예방접종', AppIcons.vaccination, '예방접종 일정을 관리해요', true),
  checkup('정기검진', AppIcons.checkup, '정기검진 일정을 관리해요', true),
  special('특이사항', AppIcons.special, '기타 특이사항을 기록해요', true);

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
  shower('샤워', AppIcons.shower, '목욕/샤워'),
  brushing('빗질', AppIcons.brushing, '털 빗질'),
  nailTrim('발톱정리', AppIcons.nailTrim, '발톱 깎기'),
  haircut('이발', AppIcons.haircut, '털 미용/커트'),
  earCleaning('귀청소', AppIcons.earCleaning, '귀 청소'),
  eyeCleaning('눈물자국', AppIcons.eyeCleaning, '눈물자국 닦기'),
  analGland('항문낭', AppIcons.analGland, '항문낭 짜기'),
  pawCare('발바닥', AppIcons.pawCare, '발바닥 관리'),
  teethBrushing('양치', AppIcons.teethBrushing, '양치질'),
  teethScaling('치석제거', AppIcons.teethScaling, '치석 제거/스케일링'),
  other('기타', AppIcons.more, '기타 그루밍');

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
  identity('본인인증', AppIcons.badgeIdentity, '본인 인증을 완료했어요'),
  location('위치인증', AppIcons.badgeLocation, '동네 인증을 완료했어요'),
  petRegistration('동물등록', AppIcons.badgePet, '동물등록 인증을 완료했어요');

  final String label;
  final IconData icon;
  final String description;

  const BadgeType(this.label, this.icon, this.description);
}

/// ============================================================
/// 소모임 카테고리
/// ============================================================
enum GroupCategory {
  walk('산책 모임', AppIcons.groupWalk, '함께 산책해요'),
  play('놀이 모임', AppIcons.groupPlay, '함께 놀아요'),
  share('나눔 모임', AppIcons.groupShare, '물품을 나눠요'),
  coffee('커피 모임', AppIcons.groupCoffee, '보호자끼리 모여요'),
  training('훈련 모임', AppIcons.groupTraining, '함께 훈련해요'),
  health('건강 모임', AppIcons.groupHealth, '건강 정보를 나눠요'),
  other('기타', AppIcons.more, '기타 모임이에요');

  final String label;
  final IconData icon;
  final String description;

  const GroupCategory(this.label, this.icon, this.description);
}

/// 소모임 제한 타입
enum GroupRestriction {
  none('제한 없음'),
  petTypeOnly('종류 제한'),
  weightOnly('체중 제한'),
  petTypeAndWeight('종류+체중 제한');

  final String label;

  const GroupRestriction(this.label);
}

/// ============================================================
/// 채팅 타입
/// 
/// 변경사항 (리팩토링):
/// - 교배 채팅 타입 분리 (배지 표시용)
/// ============================================================
enum ChatType {
  dating('데이팅', AppIcons.dating, '친구 만들기 채팅'),
  breeding('교배', AppIcons.breeding, '교배 상대 채팅'),
  group('소모임', AppIcons.group, '소모임 채팅'),
  market('마켓', AppIcons.market, '중고거래 채팅');

  final String label;
  final IconData icon;
  final String description;

  const ChatType(this.label, this.icon, this.description);
  
  /// 교배 채팅인지 확인
  bool get isBreeding => this == ChatType.breeding;
  
  /// 소모임 채팅인지 확인
  bool get isGroup => this == ChatType.group;
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

/// ============================================================
/// 반려동물 종류 (PetType)
/// 
/// 강아지, 고양이, 파충류, 소동물, 조류, 기타
/// ============================================================
enum PetType {
  dog('강아지', '🐕'),
  cat('고양이', '🐱'),
  reptile('파충류', '🦎'),
  smallPet('소동물', '🐹'),
  bird('조류', '🐦'),
  other('기타', '🐾');

  final String label;
  final String emoji;

  const PetType(this.label, this.emoji);
}

/// ============================================================
/// 품종 데이터 (PetBreeds)
/// 
/// - 대표 품종: 선택 칩에 표시 (한국에서 가장 많이 키우는 품종)
/// - 전체 품종: 자동완성용 데이터
/// ============================================================
class PetBreeds {
  PetBreeds._();

  // ===== 강아지 =====
  
  /// 강아지 대표 품종 TOP 10 (선택 칩용)
  static const List<String> dogPopular = [
    '말티즈',
    '푸들',
    '포메라니안',
    '비숑 프리제',
    '시츄',
    '골든 리트리버',
    '웰시코기',
    '진돗개',
    '치와와',
    '믹스견',
  ];

  /// 강아지 전체 품종 (자동완성용)
  static const List<String> dogAll = [
    // 대표 품종
    '말티즈', '푸들', '포메라니안', '비숑 프리제', '시츄',
    '골든 리트리버', '웰시코기', '진돗개', '치와와', '믹스견',
    // 소형견
    '요크셔 테리어', '파피용', '페키니즈', '미니어처 핀셔',
    '미니어처 슈나우저', '잭 러셀 테리어', '보스턴 테리어',
    '캐벌리어 킹 찰스 스패니얼', '미니어처 푸들', '토이 푸들',
    '말티푸', '폼스키', '슈눌', '코카푸',
    // 중형견
    '비글', '코카 스파니엘', '스탠다드 슈나우저', '불독',
    '프렌치 불독', '보더 콜리', '셰틀랜드 쉽독', '시바견',
    '바셋 하운드', '휘핏', '아메리칸 코카 스파니엘',
    // 대형견
    '래브라도 리트리버', '저먼 셰퍼드', '사모예드', '시베리안 허스키',
    '알래스칸 말라뮤트', '도베르만', '로트와일러', '복서',
    '그레이트 데인', '버니즈 마운틴 독', '뉴펀들랜드',
    '아이리시 세터', '달마시안', '아키타', '차우차우',
    '풍산개', '삽살개', '동경이',
    // 닥스훈트 종류
    '닥스훈트', '미니어처 닥스훈트',
    // 테리어 종류
    '에어데일 테리어', '웨스트 하이랜드 화이트 테리어',
    '스코티시 테리어', '불 테리어', '스태퍼드셔 불 테리어',
    // 기타
    '그레이하운드', '휘핏', '바센지', '샤페이',
  ];

  // ===== 고양이 =====
  
  /// 고양이 대표 품종 TOP 5 (선택 칩용)
  static const List<String> catPopular = [
    '코리안 숏헤어',
    '러시안 블루',
    '브리티시 숏헤어',
    '페르시안',
    '스코티시 폴드',
  ];

  /// 고양이 전체 품종 (자동완성용)
  static const List<String> catAll = [
    // 대표 품종
    '코리안 숏헤어', '러시안 블루', '브리티시 숏헤어', '페르시안', '스코티시 폴드',
    // 인기 품종
    '먼치킨', '랙돌', '샴', '아비시니안', '메인쿤',
    '노르웨이 숲', '터키시 앙고라', '벵갈', '버만', '아메리칸 숏헤어',
    '엑조틱 숏헤어', '히말라얀', '데본 렉스', '스핑크스', '소말리',
    '싱가푸라', '오리엔탈 숏헤어', '통키니즈', '버미즈', '샤트룩스',
    '재패니즈 밥테일', '아메리칸 컬', '셀커크 렉스', '라팜',
    // 기타
    '믹스묘', '길고양이',
  ];

  // ===== 파충류 =====
  
  /// 파충류 대표 품종 (선택 칩용)
  static const List<String> reptilePopular = [
    '레오파드 게코',
    '크레스티드 게코',
    '비어디 드래곤',
    '볼파이톤',
    '콘스네이크',
  ];

  /// 파충류 전체 품종 (자동완성용)
  static const List<String> reptileAll = [
    // 도마뱀
    '레오파드 게코', '크레스티드 게코', '비어디 드래곤', '블루텅 스킨크',
    '그린 이구아나', '카멜레온', '아콜로틀', '프릴드 리자드',
    '사바나 모니터', '테구', '우로마스틱스',
    // 뱀
    '볼파이톤', '콘스네이크', '킹스네이크', '밀크스네이크',
    '카펫파이톤', '그린트리파이톤', '보아 컨스트릭터',
    // 거북
    '육지거북', '레오파드 육지거북', '설카타 육지거북',
    '붉은귀 거북', '지도거북', '머스크 터틀',
    // 기타
    '기타 파충류',
  ];

  // ===== 소동물 =====
  
  /// 소동물 대표 품종 (선택 칩용)
  static const List<String> smallPetPopular = [
    '햄스터',
    '토끼',
    '기니피그',
    '고슴도치',
    '페럿',
  ];

  /// 소동물 전체 품종 (자동완성용)
  static const List<String> smallPetAll = [
    // 햄스터
    '골든 햄스터', '드워프 햄스터', '로보로브스키 햄스터',
    '캠벨 햄스터', '윈터화이트 햄스터', '햄스터',
    // 토끼
    '네덜란드 드워프', '홀랜드 롭', '미니 렉스', '라이온 헤드',
    '앙고라', '플레미시 자이언트', '토끼',
    // 기니피그
    '아메리칸 기니피그', '아비시니안 기니피그', '페루비안 기니피그',
    '텍셀 기니피그', '기니피그',
    // 기타 소동물
    '친칠라', '고슴도치', '페럿', '슈가글라이더', '다람쥐',
    '데구', '저빌', '마우스', '랫', '기타 소동물',
  ];

  // ===== 조류 =====
  
  /// 조류 대표 품종 (선택 칩용)
  static const List<String> birdPopular = [
    '사랑앵무',
    '코카틸',
    '모란앵무',
    '문조',
    '십자매',
  ];

  /// 조류 전체 품종 (자동완성용)
  static const List<String> birdAll = [
    // 앵무새
    '사랑앵무', '코카틸', '모란앵무', '왕관앵무', '유황앵무',
    '회색앵무', '아마존 앵무', '금강앵무', '마코앵무',
    '퀘이커 앵무', '세네갈 앵무', '카이크',
    // 핀치류
    '문조', '십자매', '금화조', '카나리아', '제브라 핀치',
    // 기타
    '비둘기', '닭', '오리', '거위', '메추리', '기타 조류',
  ];

  // ===== 유틸리티 메서드 =====

  /// 반려동물 종류별 대표 품종 가져오기
  static List<String> getPopularBreeds(PetType type) {
    switch (type) {
      case PetType.dog:
        return dogPopular;
      case PetType.cat:
        return catPopular;
      case PetType.reptile:
        return reptilePopular;
      case PetType.smallPet:
        return smallPetPopular;
      case PetType.bird:
        return birdPopular;
      case PetType.other:
        return [];
    }
  }

  /// 반려동물 종류별 전체 품종 가져오기 (자동완성용)
  static List<String> getAllBreeds(PetType type) {
    switch (type) {
      case PetType.dog:
        return dogAll;
      case PetType.cat:
        return catAll;
      case PetType.reptile:
        return reptileAll;
      case PetType.smallPet:
        return smallPetAll;
      case PetType.bird:
        return birdAll;
      case PetType.other:
        return [];
    }
  }

  /// 모든 품종 검색 (자동완성용)
  static List<String> searchBreeds(String query, {PetType? type}) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    List<String> breeds;
    
    if (type != null) {
      breeds = getAllBreeds(type);
    } else {
      breeds = [
        ...dogAll,
        ...catAll,
        ...reptileAll,
        ...smallPetAll,
        ...birdAll,
      ];
    }
    
    return breeds
        .where((breed) => breed.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// @deprecated [dogPopular]를 대신 사용하세요
  @Deprecated('dogPopular를 대신 사용하세요')
  static const List<String> popular = dogPopular;
}
