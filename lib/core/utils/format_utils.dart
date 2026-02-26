/// ============================================================
/// 포맷팅 유틸리티
/// 금액, 날짜, 숫자 등 공통 포맷팅 함수
/// ============================================================

/// 금액 포맷팅 (3자리마다 콤마)
String formatPrice(int price) {
  return price.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

/// 금액 문자열 (원 단위 포함)
String formatPriceWithUnit(int price) {
  return '${formatPrice(price)}원';
}

/// 금액 입력 포맷팅 (입력 중 콤마 추가)
String formatPriceInput(String value) {
  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (numericValue.isEmpty) return '';
  final intValue = int.tryParse(numericValue) ?? 0;
  return formatPrice(intValue);
}

/// 금액 문자열에서 숫자만 추출
int parsePriceString(String value) {
  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(numericValue) ?? 0;
}

/// 시간 포맷팅 (상대 시간)
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  
  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
  return '${diff.inDays ~/ 365}년 전';
}

/// 날짜 포맷팅 (yyyy.MM.dd)
String formatDate(DateTime dateTime) {
  return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
}

/// 날짜 포맷팅 (MM/dd)
String formatShortDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}';
}

/// 숫자 축약 (1000 -> 1K, 1000000 -> 1M)
String formatCompactNumber(int number) {
  if (number < 1000) return number.toString();
  if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
  return '${(number / 1000000).toStringAsFixed(1)}M';
}

/// 날짜/시간 포맷팅 (yyyy.MM.dd HH:mm)
String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}.${dateTime.month}.${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// 날짜/시간 포맷팅 (yyyy년 MM월 dd일)
String formatDateKorean(DateTime dateTime) {
  return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
}

/// 시간만 포맷팅 (HH:mm)
String formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// 날짜/시간 포맷팅 (상대 시간 또는 절대 시간)
/// 24시간 이내면 상대 시간, 그 이후면 절대 시간
String formatSmartDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  
  if (diff.inHours < 24) {
    return formatRelativeTime(dateTime);
  }
  return formatDateTime(dateTime);
}

/// 상대 날짜 포맷팅 (오늘, 어제, N일 전, MM/dd)
/// 
/// 사용 예시:
/// ```dart
/// final label = formatRelativeDate(DateTime.now()); // '오늘'
/// ```
String formatRelativeDate(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  
  if (diff.inDays == 0) return '오늘';
  if (diff.inDays == 1) return '어제';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${dateTime.month}월 ${dateTime.day}일';
}

/// 짧은 날짜+시간 포맷팅 (M/d HH:mm)
/// 
/// 사용 예시:
/// ```dart
/// final label = formatShortDateTime(DateTime.now()); // '2/10 14:30'
/// ```
String formatShortDateTime(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// 시간 범위 포맷팅 (HH:mm ~ HH:mm)
/// 
/// 사용 예시:
/// ```dart
/// final label = formatTimeRange(start, end); // '14:30 ~ 15:30'
/// final label = formatTimeRange(start, null); // '14:30 (진행 중)'
/// ```
String formatTimeRange(DateTime start, DateTime? end) {
  final startStr = formatTime(start);
  if (end == null) return '$startStr (진행 중)';
  return '$startStr ~ ${formatTime(end)}';
}

/// 날짜+요일 포맷팅 (yyyy년 M월 d일 (요일))
/// 
/// 사용 예시:
/// ```dart
/// final label = formatDateWithWeekday(DateTime.now()); // '2026년 2월 10일 (월)'
/// ```
String formatDateWithWeekday(DateTime dateTime) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 (${weekdays[dateTime.weekday - 1]})';
}
