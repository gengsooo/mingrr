/// ============================================================
/// MINGRR 폼 문자열 상수
/// 
/// 등록/수정 화면에서 사용되는 문자열 상수 모음
/// 일관된 UX를 위해 중앙 집중 관리
/// ============================================================

class FormStrings {
  FormStrings._();

  // ===== 공통 =====
  static const String required = '필수';
  static const String optional = '선택';
  
  // ===== 버튼 =====
  static const String submit = '등록';
  static const String edit = '수정';
  static const String save = '저장';
  static const String cancel = '취소';
  static const String confirm = '확인';
  static const String delete = '삭제';
  static const String add = '추가';
  static const String done = '완료';
  static const String next = '다음';
  static const String prev = '이전';
  static const String close = '닫기';
  
  // ===== 라벨 =====
  static const String labelTitle = '제목';
  static const String labelContent = '내용';
  static const String labelDescription = '상세 내용';
  static const String labelCategory = '카테고리';
  static const String labelType = '종류';
  static const String labelPhoto = '사진';
  static const String labelVideo = '동영상';
  static const String labelTag = '태그';
  static const String labelLocation = '지역';
  static const String labelAddress = '주소';
  static const String labelDate = '날짜';
  static const String labelTime = '시간';
  static const String labelPrice = '가격';
  static const String labelSettings = '설정';
  static const String labelName = '이름';
  static const String labelNickname = '닉네임';
  static const String labelIntroduction = '소개';
  static const String labelMaxMembers = '최대 인원';
  
  // ===== 힌트 텍스트 =====
  static const String hintTitle = '제목을 입력해주세요';
  static const String hintContent = '내용을 입력해주세요';
  static const String hintDescription = '상세 내용을 입력해주세요';
  static const String hintTag = '태그 입력 후 엔터';
  static const String hintLocation = '지역을 선택해주세요';
  static const String hintCategory = '카테고리를 선택해주세요';
  static const String hintPrice = '가격을 입력해주세요';
  static const String hintName = '이름을 입력해주세요';
  static const String hintNickname = '닉네임을 입력해주세요';
  static const String hintIntroduction = '소개를 입력해주세요';
  static const String hintMaxMembers = '0 = 무제한';
  static const String hintSearch = '검색어를 입력해주세요';
  
  // ===== 유효성 검사 메시지 =====
  static const String errorRequired = '필수 입력 항목입니다';
  static const String errorTitleRequired = '제목을 입력해주세요';
  static const String errorContentRequired = '내용을 입력해주세요';
  static const String errorCategoryRequired = '카테고리를 선택해주세요';
  static const String errorLocationRequired = '지역을 선택해주세요';
  static const String errorImageRequired = '이미지를 추가해주세요';
  static const String errorPriceRequired = '가격을 입력해주세요';
  static const String errorInvalidPrice = '올바른 가격을 입력해주세요';
  static const String errorMinLength = '최소 {0}자 이상 입력해주세요';
  static const String errorMaxLength = '최대 {0}자까지 입력 가능합니다';
  
  // ===== 성공 메시지 =====
  static const String successCreated = '등록되었습니다';
  static const String successUpdated = '수정되었습니다';
  static const String successDeleted = '삭제되었습니다';
  static const String successSaved = '저장되었습니다';
  
  // ===== 확인 메시지 =====
  static const String confirmDelete = '정말 삭제하시겠습니까?';
  static const String confirmCancel = '작성을 취소하시겠습니까?\n입력한 내용이 저장되지 않습니다.';
  static const String confirmExit = '나가시겠습니까?\n입력한 내용이 저장되지 않습니다.';
  
  // ===== 빈 상태 =====
  static const String emptyList = '아직 데이터가 없어요';
  static const String emptySearch = '검색 결과가 없어요';
  static const String emptyPost = '아직 게시글이 없어요';
  static const String emptyGroup = '아직 모임이 없어요';
  static const String emptyProduct = '아직 상품이 없어요';
  
  // ===== 이미지 =====
  static const String imageAdd = '이미지 추가';
  static const String imageMaxReached = '최대 {0}장까지 추가 가능합니다';
  static const String imageUploading = '이미지 업로드 중...';
  
  // ===== 태그 =====
  static const String tagMaxReached = '최대 {0}개까지 추가 가능합니다';
  static const String tagDuplicate = '이미 추가된 태그입니다';
  
  // ===== 로딩 =====
  static const String loading = '로딩 중...';
  static const String loadingData = '데이터를 불러오는 중...';
  static const String loadingImage = '이미지를 불러오는 중...';
  
  // ===== 에러 =====
  static const String errorGeneral = '오류가 발생했습니다';
  static const String errorNetwork = '네트워크 연결을 확인해주세요';
  static const String errorServer = '서버 오류가 발생했습니다';
  static const String errorRetry = '다시 시도해주세요';
  static const String errorLoadFailed = '데이터를 불러올 수 없습니다';
}

/// 화면별 타이틀 상수
class ScreenTitles {
  ScreenTitles._();
  
  // ===== 커뮤니티 =====
  static const String communityWrite = '글 작성';
  static const String communityEdit = '글 수정';
  static const String communityDetail = '게시글';
  
  // ===== 소모임 =====
  static const String groupWrite = '소모임 만들기';
  static const String groupEdit = '소모임 수정';
  static const String groupDetail = '소모임';
  static const String groupList = '소모임';
  
  // ===== 마켓 =====
  static const String productWrite = '마켓 등록';
  static const String productEdit = '마켓 수정';
  static const String productDetail = '상품';
  static const String marketplace = '마켓';
  
  // ===== 교배 =====
  static const String breedingWrite = '교배 글쓰기';
  static const String breedingEdit = '교배 글 수정';
  static const String breedingDetail = '교배';
  
  // ===== 펫 =====
  static const String petRegister = '반려동물 등록';
  static const String petEdit = '반려동물 수정';
  static const String petDetail = '반려동물';
  
  // ===== 프로필 =====
  static const String profileEdit = '프로필 수정';
  static const String profile = '프로필';
  
  // ===== 건강 =====
  static const String healthRecordAdd = '건강기록 추가';
  static const String healthRecordEdit = '건강기록 수정';
}

/// 스위치/토글 설정 문자열
class SwitchStrings {
  SwitchStrings._();
  
  // ===== 소모임 =====
  static const String publicGroup = '공개 모임';
  static const String publicGroupDesc = '누구나 모임을 볼 수 있습니다';
  static const String requireApproval = '가입 승인 필요';
  static const String requireApprovalDesc = '관리자가 가입을 승인해야 합니다';
  static const String petAccompanied = '반려동물 동반';
  static const String petAccompaniedDesc = '모임 활동 시 반려동물과 함께합니다';
  
  // ===== 커뮤니티 =====
  static const String anonymous = '익명으로 작성';
  static const String anonymousDesc = '닉네임이 "익명"으로 표시됩니다';
  
  // ===== 교배 =====
  static const String sameBreedOnly = '같은 품종만';
  static const String sameBreedOnlyDesc = '같은 품종의 강아지만 매칭됩니다';
}
