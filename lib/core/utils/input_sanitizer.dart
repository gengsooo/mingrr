/// ============================================================
/// 입력 정화 유틸리티
/// 
/// XSS, HTML Injection, 악성 스크립트 방지를 위한 입력 검증
/// 모든 사용자 입력에 적용하여 보안 강화
/// ============================================================

class InputSanitizer {
  InputSanitizer._();

  // ===== HTML/스크립트 제거 =====

  /// HTML 태그 제거
  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 스크립트 태그 제거
  static String removeScripts(String input) {
    return input.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      '',
    );
  }

  /// 위험한 HTML 속성 제거 (onclick, onerror 등)
  static String removeEventHandlers(String input) {
    // on으로 시작하는 이벤트 핸들러 속성 제거
    return input.replaceAll(RegExp(r'on\w+='), '');
  }

  // ===== 특수 문자 이스케이프 =====

  /// HTML 특수 문자 이스케이프 (표시용)
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  // ===== 종합 정화 함수 =====

  /// 일반 텍스트 정화 (채팅, 댓글 등)
  /// - 스크립트/HTML 태그 제거
  /// - 앞뒤 공백 제거
  /// - 연속 공백 정리
  static String sanitizeText(String input) {
    String result = input;
    result = removeScripts(result);
    result = removeEventHandlers(result);
    result = stripHtml(result);
    result = _normalizeWhitespace(result);
    return result.trim();
  }

  /// 닉네임/이름 정화
  /// - HTML 제거
  /// - 특수문자 제한
  /// - 공백 정리
  static String sanitizeName(String input) {
    String result = stripHtml(input);
    result = result.replaceAll(RegExp(r'[<>"/\\]'), '');
    result = result.replaceAll("'", '');
    result = _normalizeWhitespace(result);
    return result.trim();
  }

  /// URL 정화 및 검증
  /// - 위험한 프로토콜 차단
  /// - 유효한 URL만 허용
  static String? sanitizeUrl(String input) {
    final trimmed = input.trim();
    
    // 위험한 프로토콜 차단
    if (isDangerousUrl(trimmed)) {
      return null;
    }
    
    // URL 유효성 검사
    if (!isValidUrl(trimmed)) {
      return null;
    }
    
    return trimmed;
  }

  // ===== URL 검증 =====

  /// URL 유효성 검사
  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// 위험한 URL 패턴 체크
  static bool isDangerousUrl(String url) {
    final dangerous = [
      'javascript:',
      'data:',
      'vbscript:',
      'file:',
      'about:',
    ];
    final lower = url.toLowerCase().trim();
    return dangerous.any((pattern) => lower.startsWith(pattern));
  }

  // ===== 길이 제한 =====

  /// 최대 길이 제한
  static String truncate(String input, int maxLength) {
    if (input.length <= maxLength) return input;
    return input.substring(0, maxLength);
  }

  /// 최대 길이 검증
  static bool isWithinLength(String input, int maxLength) {
    return input.length <= maxLength;
  }

  // ===== 내부 유틸리티 =====

  /// 연속 공백을 단일 공백으로 정리
  static String _normalizeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ');
  }

  // ===== 컬렉션별 정화 함수 =====

  /// 채팅 메시지 정화
  static String sanitizeMessage(String input, {int maxLength = 1000}) {
    final sanitized = sanitizeText(input);
    return truncate(sanitized, maxLength);
  }

  /// 게시글 내용 정화
  static String sanitizePostContent(String input, {int maxLength = 5000}) {
    final sanitized = sanitizeText(input);
    return truncate(sanitized, maxLength);
  }

  /// 게시글 제목 정화
  static String sanitizePostTitle(String input, {int maxLength = 100}) {
    final sanitized = sanitizeName(input);
    return truncate(sanitized, maxLength);
  }

  /// 자기소개 정화
  static String sanitizeBio(String input, {int maxLength = 500}) {
    final sanitized = sanitizeText(input);
    return truncate(sanitized, maxLength);
  }

  /// 상품 설명 정화
  static String sanitizeProductDescription(String input, {int maxLength = 3000}) {
    final sanitized = sanitizeText(input);
    return truncate(sanitized, maxLength);
  }
}

/// 입력 길이 상수
class InputLimits {
  InputLimits._();

  // 사용자 관련
  static const int nickname = 12;
  static const int bio = 500;
  
  // 채팅 관련
  static const int message = 1000;
  
  // 게시글 관련
  static const int postTitle = 100;
  static const int postContent = 5000;
  static const int comment = 1000;
  
  // 상품 관련
  static const int productTitle = 50;
  static const int productDescription = 3000;
  
  // 반려동물 관련
  static const int petName = 20;
  static const int petDescription = 1000;
  
  // 소모임 관련
  static const int groupName = 30;
  static const int groupDescription = 2000;
}
