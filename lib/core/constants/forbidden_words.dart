/// ============================================================
/// 금지어 목록
/// 
/// 닉네임, 채팅, 게시글 등에서 사용 금지되는 단어 목록
/// 카테고리별로 분류하여 유지보수 용이하게 관리
/// ============================================================

class ForbiddenWords {
  ForbiddenWords._();

  /// 모든 금지어 목록 (정규화된 형태)
  static Set<String> get all => {
    ..._profanity,
    ..._sexualContent,
    ..._hateExpression,
    ..._impersonation,
    ..._advertising,
    ..._personalInfo,
  };

  /// 금지어 포함 여부 확인 (정규화 후 체크)
  static bool contains(String text) {
    final normalized = normalize(text);
    
    // 1. 완전 일치 체크
    if (all.contains(normalized)) return true;
    
    // 2. 부분 일치 체크 (금지어가 포함되어 있는지)
    for (final word in all) {
      if (word.length >= 2 && normalized.contains(word)) {
        return true;
      }
    }
    
    return false;
  }

  /// 텍스트 정규화 (우회 방지)
  /// - 공백, 특수문자 제거
  /// - 소문자 변환
  /// - 유사 문자 치환
  /// - 자모 분리 조합
  static String normalize(String text) {
    String result = text.toLowerCase();
    
    // 1. 공백 및 특수문자 제거
    result = result.replaceAll(RegExp(r'[^가-힣a-zA-Z0-9ㄱ-ㅎㅏ-ㅣ]'), '');
    
    // 2. 유사 문자 치환 (영문 → 한글 발음, 숫자 → 문자)
    result = _replaceSimilarChars(result);
    
    // 3. 반복 문자 제거 (ㅋㅋㅋ → ㅋ, ㅎㅎㅎ → ㅎ)
    result = _removeRepeatedChars(result);
    
    // 4. 자모 분리된 텍스트 조합 시도
    result = _combineJamo(result);
    
    return result;
  }

  /// 유사 문자 치환
  static String _replaceSimilarChars(String text) {
    const Map<String, String> similarChars = {
      // 숫자 → 한글/영문
      '0': '오', '1': '일', '2': '이', '3': '삼',
      '4': '사', '5': '오', '6': '육', '7': '칠',
      '8': '팔', '9': '구',
      // 영문 → 한글 발음 (일부)
      'ㅇ': '', 'ㅎ': '',
      // 특수 유니코드
      'ℓ': 'l', '１': '1', '２': '2', '３': '3',
    };
    
    String result = text;
    similarChars.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }

  /// 반복 문자 제거 (3회 이상 반복 → 1회)
  static String _removeRepeatedChars(String text) {
    return text.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
      (match) => match.group(1)!,
    );
  }

  /// 자모 분리된 텍스트 조합
  /// 예: ㅅㅣㅂㅏㄹ → 시발
  static String _combineJamo(String text) {
    // 한글 자모 상수
    const List<String> chosung = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
      'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    const List<String> jungsung = [
      'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
      'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'
    ];
    const List<String> jongsung = [
      '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ',
      'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ',
      'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];

    StringBuffer result = StringBuffer();
    int i = 0;
    
    while (i < text.length) {
      final char = text[i];
      
      // 초성인지 확인
      final choIndex = chosung.indexOf(char);
      if (choIndex != -1 && i + 1 < text.length) {
        // 다음 문자가 중성인지 확인
        final jungIndex = jungsung.indexOf(text[i + 1]);
        if (jungIndex != -1) {
          // 종성 확인
          int jongIndex = 0;
          if (i + 2 < text.length) {
            final possibleJong = jongsung.indexOf(text[i + 2]);
            // 다음 문자가 종성이고, 그 다음이 중성이 아닌 경우에만 종성으로 처리
            if (possibleJong > 0) {
              if (i + 3 >= text.length || !jungsung.contains(text[i + 3])) {
                jongIndex = possibleJong;
                i++;
              }
            }
          }
          
          // 한글 조합
          final unicode = 0xAC00 + (choIndex * 21 * 28) + (jungIndex * 28) + jongIndex;
          result.write(String.fromCharCode(unicode));
          i += 2;
          continue;
        }
      }
      
      result.write(char);
      i++;
    }
    
    return result.toString();
  }

  // ============================================================
  // 금지어 카테고리별 목록
  // ============================================================

  /// 비속어/욕설
  static const Set<String> _profanity = {
    // 기본 욕설 및 변형
    '시발', '씨발', '씨빨', '씨팔', '씨바', '시바', '시빨', '시팔',
    'ㅅㅂ', 'ㅆㅂ', 'ㅅㅃ', 'ㅆㅃ', 'sibbal', 'sibal',
    '병신', '븅신', '빙신', '병싄', 'ㅂㅅ', 'ㅄ', 'byungsin',
    '지랄', '지럴', 'ㅈㄹ', 'jiral',
    '개새끼', '개새기', '개색기', '개색끼', '개쉐끼', '개쉑',
    '개년', '개놈', '개자식', '개같은',
    '좆', '좃', '조까', '졸라', 'ㅈㄲ',
    '니미', '니애미', '느금마', '느금', 'ㄴㄱㅁ',
    '엠창', 'ㅇㅊ',
    '썅', '쌍', '썅년', '썅놈',
    '애미', '애비', '에미', '에비',
    '미친', '미친놈', '미친년', '미놈', '미년',
    '또라이', '돌아이', '또라리',
    '찐따', '찐다', 'ㅉㄷ',
    '한남', '한녀', '김치녀', '김치남',
    '보지', '자지', '잦', 'ㅂㅈ', 'ㅈㅈ',
    '섹스', '섹쓰', '쎅스', 'sex',
    '꺼져', '닥쳐', '뒤져', '뒈져', '디져',
    '죽어', '죽을', '뒤질',
    '멍청', '바보', '등신', '얼간이',
    '쓰레기', '쓰래기', '찌질이', '찌질',
    '걸레', '창녀', '창년', '화냥년',
    '호구', '봉', '호갱',
    '빠가', '빠구리', '빠큐',
    '염병', '엿먹어', '엿이나',
    '후장', '똥꼬', '항문',
    '꼴통', '정신병자',
    '애자', '병자',
    '노답', '답없',
    '느개비', '느개미',
    '씹', '씹새', '씹년', '씹놈', 'ㅆ',
    '존나', '존내', 'ㅈㄴ', 'jonna',
    '개소리', '개드립', '개헛소리',
    '미친개', '또라이개',
  };

  /// 성적 표현
  static const Set<String> _sexualContent = {
    '야동', '야사', '야설', '야한',
    '포르노', 'porno', 'porn',
    '섹파', '원나잇', '원나잇스탠드',
    '자위', '딸딸이', '딸치',
    '성관계', '성행위', '검열삭제',
    '강간', '성폭행', '성추행', '성희롱',
    '음란', '음경', '음핵', '클리',
    '가슴', '젖', '유두', '유방', '슴가',
    '엉덩이', '엉짝', '힙',
    '페니스', 'penis', '팰러스',
    '바기나', 'vagina',
    '오르가즘', 'orgasm',
    '사까시', '빨아', '빨어',
    '박아', '박어', '박히',
    '삽입', '애널', 'anal',
    '정액', '사정', '질내',
    '콘돔', '피임',
    '매춘', '성매매', '원조교제',
    '조건만남', '조건녀', '조건남',
    'av', '에이브이',
    '야겜', '야게임', '에로게',
    '후방주의', '후방',
    '노출', '누드', 'nude',
    '비키니', '속옷',
    '란제리', 'lingerie',
    '페티쉬', 'fetish',
    'bdsm', 'sm',
    '노브라', '노팬티',
  };

  /// 혐오 표현
  static const Set<String> _hateExpression = {
    // 인종 차별
    '깜둥이', '흑형', '쪽바리', '짱깨', '짱개', '양키',
    '니그로', 'nigger', 'negro',
    '조센징', '반도인',
    
    // 성차별
    '페미나치', '꼴페미', '메갈', '워마드',
    '인셀', 'incel', '맘충', '애비충',
    '보빨러', '자댕이',
    
    // 장애 비하
    '장애인', '애자', '병신', '불구',
    '정박아', '지체', '정신지체',
    '자폐', '다운',
    
    // 지역 비하
    '홍어', '전라디언', '경상디언',
    '충청도놈', '서울촌놈',
    
    // 종교 비하
    '개독', '틀딱', '꼰대',
    
    // 외모 비하
    '뚱땡이', '돼지', '뚱보',
    '대머리', '빡빡이',
    '못난이', '추녀', '추남',
    
    // 기타 혐오
    '자살', '자해', '죽어라',
    '테러', '폭탄', '살인',
    '히틀러', 'hitler', '나치', 'nazi',
  };

  /// 사칭 방지
  static const Set<String> _impersonation = {
    // 관리자/운영자 사칭
    '관리자', '운영자', '운영진', '매니저',
    'admin', 'administrator', 'manager', 'moderator',
    '시스템', 'system', 'official', '공식',
    '밍그르', 'mingrr', '밍글', 'mingr',
    
    // 고객센터 사칭
    '고객센터', '고객지원', 'support', 'help',
    '문의', 'contact',
    
    // 직원 사칭
    '직원', 'staff', 'employee',
    'ceo', 'cto', 'coo', '대표',
    
    // 인증 사칭
    '인증', '공인', '검증', 'verified',
    '프리미엄', 'premium', 'vip',
    
    // 봇 사칭
    '봇', 'bot', '자동', 'auto',
  };

  /// 광고성 표현
  static const Set<String> _advertising = {
    // 메신저 유도
    '카톡', '카카오톡', 'kakaotalk', 'kakao',
    '텔레그램', 'telegram', 'tele',
    '라인', 'line',
    '위챗', 'wechat',
    '디스코드', 'discord',
    
    // 연락처 유도
    '연락처', '전화번호', '폰번호',
    '문자', 'sms', '톡주세요', '톡주삼',
    'dm', '디엠',
    
    // URL 패턴
    'http', 'https', 'www', '.com', '.net', '.kr', '.co',
    '링크', 'link', 'url',
    
    // 홍보성
    '홍보', '광고', '이벤트', '할인',
    '무료', 'free', '공짜',
    '돈벌기', '부업', '알바', '재택',
    '투자', '코인', '비트코인', 'bitcoin',
    '대출', '급전',
  };

  /// 개인정보 패턴 (정규식으로 별도 체크 필요)
  static const Set<String> _personalInfo = {
    // 주민번호 관련
    '주민번호', '주민등록',
    
    // 계좌 관련
    '계좌번호', '통장번호',
    
    // 카드 관련
    '카드번호', '신용카드',
  };
}
