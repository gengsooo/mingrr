/// ============================================================
/// MINGRR 앱 문자열 상수
/// 모든 UI 텍스트를 중앙에서 관리하여 다국어 지원 및 유지보수 용이
/// ============================================================
class AppStrings {
  AppStrings._();

  // ===== 앱 정보 =====
  static const String appName = '밍그르르';
  static const String appSlogan = '반려동물과 함께하는 특별한 만남';

  // ===== 인증 관련 =====
  static const String login = '로그인';
  static const String logout = '로그아웃';
  static const String signUp = '회원가입';
  static const String phoneLogin = '전화번호로 시작하기';
  static const String kakaoLogin = '카카오로 시작하기';
  static const String naverLogin = '네이버로 시작하기';
  static const String googleLogin = '구글로 시작하기';
  static const String enterPhoneNumber = '전화번호를 입력해주세요';
  static const String enterVerificationCode = '인증번호를 입력해주세요';
  static const String sendVerificationCode = '인증번호 전송';
  static const String verify = '인증하기';
  static const String resendCode = '인증번호 재전송';

  // ===== 프로필 관련 =====
  static const String profile = '프로필';
  static const String editProfile = '프로필 수정';
  static const String guardianInfo = '보호자 정보';
  static const String petInfo = '반려동물 정보';
  static const String addPet = '반려동물 추가';
  static const String petName = '이름';
  static const String petSpecies = '종류';
  static const String petBreed = '품종';
  static const String petAge = '나이';
  static const String petWeight = '몸무게';
  static const String petGender = '성별';
  static const String petPersonality = '성격';
  static const String petPhotos = '사진';
  static const String male = '수컷';
  static const String female = '암컷';
  static const String neutered = '중성화 완료';
  static const String notNeutered = '중성화 안함';

  // ===== 네비게이션 =====
  static const String home = '홈';
  static const String dating = '데이팅';
  static const String walk = '산책';
  static const String market = '마켓';
  static const String health = '건강수첩';
  static const String community = '커뮤니티';
  static const String chat = '채팅';
  static const String settings = '설정';

  // ===== 데이팅 관련 =====
  static const String aiRecommend = 'AI 추천';
  static const String nearbyPets = '근처 친구들';
  static const String sendLike = '좋아요 보내기';
  static const String matchSuccess = '매칭 성공!';
  static const String startChat = '채팅 시작하기';
  static const String compatibility = '궁합';

  // ===== 산책 관련 =====
  static const String startWalk = '산책 시작';
  static const String endWalk = '산책 종료';
  static const String walkingNow = '산책 중';
  static const String walkHistory = '산책 기록';
  static const String walkDistance = '거리';
  static const String walkDuration = '시간';
  static const String walkCalories = '칼로리';
  static const String nearbyWalkers = '근처 산책 중인 친구';
  static const String leaveFootprint = '발자국 남기기';

  // ===== 마켓 관련 =====
  static const String sell = '판매하기';
  static const String share = '나눔하기';
  static const String forSale = '판매중';
  static const String forShare = '나눔중';
  static const String sold = '판매완료';
  static const String shared = '나눔완료';
  static const String price = '가격';
  static const String free = '무료나눔';
  static const String category = '카테고리';

  // ===== 건강수첩 관련 =====
  static const String vaccination = '예방접종';
  static const String weightRecord = '체중 기록';
  static const String poopRecord = '배변 기록';
  static const String walkRecord = '산책 기록';
  static const String addRecord = '기록 추가';
  static const String reminder = '알림 설정';
  static const String nextVaccination = '다음 접종일';

  // ===== 교배 관련 =====
  static const String breeding = '교배';
  static const String pedigree = '혈통';
  static const String verified = '인증됨';
  static const String breedingRequest = '교배 신청';
  static const String healthCertificate = '건강 인증서';

  // ===== 커뮤니티 관련 =====
  static const String groups = '소모임';
  static const String classes = '클래스';
  static const String createGroup = '모임 만들기';
  static const String joinGroup = '참여하기';
  static const String members = '멤버';
  static const String schedule = '일정';

  // ===== 인증 배지 =====
  static const String verifiedOwner = '인증된 보호자';
  static const String petRegistration = '동물등록 인증';
  static const String identityVerified = '본인 인증 완료';

  // ===== 공통 =====
  static const String save = '저장';
  static const String cancel = '취소';
  static const String confirm = '확인';
  static const String delete = '삭제';
  static const String edit = '수정';
  static const String next = '다음';
  static const String prev = '이전';
  static const String done = '완료';
  static const String loading = '로딩 중...';
  static const String error = '오류가 발생했습니다';
  static const String retry = '다시 시도';
  static const String noData = '데이터가 없습니다';
  static const String search = '검색';
  static const String filter = '필터';
  static const String sort = '정렬';
  static const String all = '전체';
  static const String more = '더보기';

  // ===== 에러 메시지 =====
  static const String networkError = '네트워크 연결을 확인해주세요';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';
  static const String loginRequired = '로그인이 필요합니다';
  static const String permissionDenied = '권한이 필요합니다';
  static const String locationPermission = '위치 권한을 허용해주세요';
}
