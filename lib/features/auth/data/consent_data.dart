/// ============================================================
/// 약관 동의 데이터 모델
/// 
/// 회원가입 시 사용자의 약관 동의 정보를 저장
/// ============================================================
class ConsentData {
  final bool termsAgreed;
  final bool privacyAgreed;
  final bool ageConfirmed;
  final bool locationAgreed;
  final bool marketingAgreed;
  final DateTime agreedAt;
  
  const ConsentData({
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.ageConfirmed,
    required this.locationAgreed,
    required this.marketingAgreed,
    required this.agreedAt,
  });
  
  Map<String, dynamic> toMap() => {
    'termsAgreed': termsAgreed,
    'privacyAgreed': privacyAgreed,
    'ageConfirmed': ageConfirmed,
    'locationAgreed': locationAgreed,
    'marketingAgreed': marketingAgreed,
    'agreedAt': agreedAt.toIso8601String(),
  };
}
