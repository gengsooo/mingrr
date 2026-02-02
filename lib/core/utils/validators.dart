/// ============================================================
/// Validators - 공통 입력 유효성 검사 유틸리티
/// 
/// 이메일, 전화번호, 비밀번호 등 공통 검증 로직 제공
/// ============================================================

class Validators {
  /// 이메일 유효성 검사
  static ValidationResult email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('이메일을 입력해주세요');
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return ValidationResult.invalid('올바른 이메일 형식이 아닙니다');
    }
    
    return ValidationResult.valid();
  }
  
  /// 전화번호 유효성 검사 (한국)
  static ValidationResult phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('전화번호를 입력해주세요');
    }
    
    // 숫자만 추출
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 한국 휴대폰 번호: 010, 011, 016, 017, 018, 019로 시작, 10-11자리
    final phoneRegex = RegExp(r'^01[0-9]{8,9}$');
    
    if (!phoneRegex.hasMatch(digitsOnly)) {
      return ValidationResult.invalid('올바른 전화번호 형식이 아닙니다');
    }
    
    return ValidationResult.valid();
  }
  
  /// 비밀번호 유효성 검사 (8~16자, 영문+숫자+특수문자 조합)
  /// 개인정보보호법 안전성 확보조치 기준 준수
  static ValidationResult password(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.invalid('비밀번호를 입력해주세요');
    }
    
    if (value.length < 8) {
      return ValidationResult.invalid('8~16자 영문, 숫자, 특수문자를 사용해주세요');
    }
    
    if (value.length > 16) {
      return ValidationResult.invalid('비밀번호는 16자 이하여야 합니다');
    }
    
    // 영문, 숫자, 특수문자 모두 포함 검사
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?:{}|<>\[\]\-_=+;~`]'));
    
    if (!hasLetter || !hasDigit || !hasSpecial) {
      return ValidationResult.invalid('영문, 숫자, 특수문자를 모두 포함해주세요');
    }
    
    return ValidationResult.valid();
  }
  
  /// 비밀번호 강도 표시 (UI용)
  static PasswordStrength getPasswordStrength(String? value) {
    if (value == null || value.isEmpty) return PasswordStrength.none;
    if (value.length < 8 || value.length > 16) return PasswordStrength.weak;
    
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?:{}|<>\[\]\-_=+;~`]'));
    
    final typeCount = [hasLetter, hasDigit, hasSpecial].where((e) => e).length;
    
    if (typeCount < 3) return PasswordStrength.weak;
    if (value.length < 12) return PasswordStrength.medium;
    
    return PasswordStrength.strong;
  }
  
  /// 비밀번호 확인 일치 검사
  static ValidationResult confirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return ValidationResult.invalid('비밀번호 확인을 입력해주세요');
    }
    
    if (password != confirm) {
      return ValidationResult.invalid('비밀번호가 일치하지 않습니다');
    }
    
    return ValidationResult.valid();
  }
  
  /// 필수 입력 검사
  static ValidationResult required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('${fieldName ?? '필수 항목'}을(를) 입력해주세요');
    }
    return ValidationResult.valid();
  }
  
  /// 최소 길이 검사
  static ValidationResult minLength(String? value, int length, {String? fieldName}) {
    if (value == null || value.length < length) {
      return ValidationResult.invalid('${fieldName ?? '입력값'}은(는) $length자 이상이어야 합니다');
    }
    return ValidationResult.valid();
  }
  
  /// 최대 길이 검사
  static ValidationResult maxLength(String? value, int length, {String? fieldName}) {
    if (value != null && value.length > length) {
      return ValidationResult.invalid('${fieldName ?? '입력값'}은(는) $length자 이하여야 합니다');
    }
    return ValidationResult.valid();
  }
  
  /// 숫자만 검사
  static ValidationResult numericOnly(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return ValidationResult.invalid('${fieldName ?? '값'}을(를) 입력해주세요');
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return ValidationResult.invalid('숫자만 입력해주세요');
    }
    
    return ValidationResult.valid();
  }
  
  /// 가격 검사 (0 이상)
  static ValidationResult price(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.invalid('가격을 입력해주세요');
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(digitsOnly);
    
    if (price == null || price < 0) {
      return ValidationResult.invalid('올바른 가격을 입력해주세요');
    }
    
    return ValidationResult.valid();
  }
  
  /// 닉네임 검사 (2-10자, 특수문자 제한)
  static ValidationResult nickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('닉네임을 입력해주세요');
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 2) {
      return ValidationResult.invalid('닉네임은 2자 이상이어야 합니다');
    }
    
    if (trimmed.length > 10) {
      return ValidationResult.invalid('닉네임은 10자 이하여야 합니다');
    }
    
    // 허용: 한글, 영문, 숫자, 밑줄
    if (!RegExp(r'^[가-힣a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return ValidationResult.invalid('닉네임은 한글, 영문, 숫자, 밑줄만 사용 가능합니다');
    }
    
    return ValidationResult.valid();
  }
}

/// 유효성 검사 결과
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult._({required this.isValid, this.errorMessage});
  
  factory ValidationResult.valid() => const ValidationResult._(isValid: true);
  
  factory ValidationResult.invalid(String message) => 
      ValidationResult._(isValid: false, errorMessage: message);
  
  /// Flutter Form 필드용 validator 함수로 변환
  String? get formError => isValid ? null : errorMessage;
}

/// 비밀번호 강도 enum
enum PasswordStrength {
  none('', null),
  weak('약함', 0xFF_E57373),
  medium('보통', 0xFF_FFB74D),
  strong('강함', 0xFF_81C784);
  
  final String label;
  final int? colorValue;
  
  const PasswordStrength(this.label, this.colorValue);
}

/// Form 필드용 validator 헬퍼
/// 
/// MingrrTextField와 함께 사용하여 실시간 검증 가능
/// 
/// 사용 예시:
/// ```dart
/// MingrrTextField(
///   labelText: '이메일',
///   validator: FormValidators.email(),
///   validateOnChange: true,
/// )
/// ```
class FormValidators {
  static String? Function(String?) email() {
    return (value) => Validators.email(value).formError;
  }
  
  static String? Function(String?) phone() {
    return (value) => Validators.phone(value).formError;
  }
  
  static String? Function(String?) password() {
    return (value) => Validators.password(value).formError;
  }
  
  static String? Function(String?) required({String? fieldName}) {
    return (value) => Validators.required(value, fieldName: fieldName).formError;
  }
  
  static String? Function(String?) nickname() {
    return (value) => Validators.nickname(value).formError;
  }

  static String? Function(String?) price() {
    return (value) => Validators.price(value).formError;
  }

  static String? Function(String?) minLength(int length, {String? fieldName}) {
    return (value) => Validators.minLength(value, length, fieldName: fieldName).formError;
  }

  static String? Function(String?) maxLength(int length, {String? fieldName}) {
    return (value) => Validators.maxLength(value, length, fieldName: fieldName).formError;
  }

  static String? Function(String?) numericOnly({String? fieldName}) {
    return (value) => Validators.numericOnly(value, fieldName: fieldName).formError;
  }

  /// 복합 검증 (여러 validator를 순차적으로 실행)
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
