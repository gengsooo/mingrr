import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/constants/pet_constants.dart';

/// ============================================================
/// 사용자(보호자) 모델 (V2 리팩토링 - 반려동물 전용)
/// 
/// 변경사항:
/// - gender 필드를 UserGender enum으로 변경
/// - 위치 인증 필드 추가 (isLocationVerified)
/// - 기본 건강 카테고리 업데이트
/// ============================================================
class UserModel extends Equatable {
  /// 고유 ID (Firebase Auth UID)
  final String id;
  
  /// 이메일 (소셜 로그인 시 제공되는 경우)
  final String? email;
  
  /// 전화번호
  final String? phoneNumber;
  
  /// 닉네임
  final String nickname;
  
  /// 프로필 이미지 URL
  final String? profileImageUrl;
  
  /// 성별 (안전한 만남을 위해 필수)
  final UserGender? gender;
  
  /// 생년월일
  final DateTime? birthDate;
  
  /// 자기소개
  final String? bio;
  
  /// 현재 위치 (GeoPoint)
  final GeoPoint? location;
  
  /// 주소 (표시용)
  final String? address;
  
  /// 집 주소 (위치 기반 서비스의 기준점)
  final String? homeAddress;
  
  /// 집 위치 (GeoPoint) - 모든 위치 기능의 기준
  final GeoPoint? homeLocation;
  
  /// 메인화면에 표시할 건강기록 카테고리 (1~5개)
  final List<String> homeHealthCategories;
  
  /// 200m 안전구역 기능 활성화 여부 (기본값: true)
  /// - true: 집 반경 200m 내에서 산책 기능 비활성화
  /// - false: 안전구역 기능 사용 안 함
  final bool homeSafetyEnabled;
  
  /// 로그인 제공자 (phone, kakao, naver, google)
  final String loginProvider;
  
  /// 동물등록 인증 여부
  final bool isVerified;
  
  /// 본인 인증 여부
  final bool isIdentityVerified;
  
  /// 위치 인증 여부 (당근마켓 스타일)
  final bool isLocationVerified;
  
  /// 위치 인증 시간
  final DateTime? locationVerifiedAt;
  
  /// 마지막 위치 체크 시간 (불일치 감지용)
  final DateTime? lastLocationCheckAt;
  
  /// 위치 불일치 횟수 (3회 이상 시 재인증 요청)
  final int locationMismatchCount;
  
  /// 위치 알림 무시 시간 (24시간 재알림 방지)
  final DateTime? locationReminderDismissedAt;
  
  /// 산책 중 상태
  final bool isWalking;
  
  /// 마지막 산책 시작 시간
  final DateTime? walkStartedAt;
  
  /// 보유 반려동물 ID 목록
  final List<String> petIds;
  
  /// FCM 토큰 (푸시 알림용)
  final String? fcmToken;
  
  /// 계정 생성일
  final DateTime createdAt;
  
  /// 마지막 활동 시간
  final DateTime lastActiveAt;
  
  /// 프리미엄 회원 여부 (수익화 - 현재 숨김)
  final bool isPremium;
  
  /// 꼬순내지수 (보호자 평점, 기본값: 50%)
  final double kkosunnaeScore;
  
  /// 받은 평가 수
  final int ratingCount;
  
  /// 닉네임 마지막 수정일 (30일 제한용)
  final DateTime? nicknameChangedAt;
  
  /// 활동 통계 - 매칭 성사 횟수
  final int matchCount;
  
  /// 활동 통계 - 산책 완료 횟수
  final int walkCount;
  
  /// 활동 통계 - 거래 완료 횟수
  final int transactionCount;
  
  /// 활동 통계 - 소모임 활동 횟수
  final int groupCount;
  
  /// 활동 통계 - 커뮤니티 게시글 수
  final int postCount;
  
  /// 신고 받은 횟수
  final int reportCount;
  
  /// 노쇼 횟수
  final int noShowCount;
  
  /// 평균 평점 (1~5)
  final double averageRating;
  
  /// 채팅 응답률 (0.0 ~ 1.0)
  final double? chatResponseRate;
  
  /// 총 받은 채팅 수
  final int totalReceivedChats;
  
  /// 응답한 채팅 수
  final int respondedChats;
  
  // ===== 약관 동의 정보 (법적 요구사항) =====
  
  /// 이용약관 동의 시간
  final DateTime? termsAgreedAt;
  
  /// 개인정보처리방침 동의 시간
  final DateTime? privacyAgreedAt;
  
  /// 위치정보 이용 동의 시간 (선택)
  final DateTime? locationConsentAt;
  
  /// 마케팅 수신 동의 시간 (선택)
  final DateTime? marketingConsentAt;

  const UserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    required this.nickname,
    this.profileImageUrl,
    this.gender,
    this.birthDate,
    this.bio,
    this.location,
    this.address,
    this.homeAddress,
    this.homeLocation,
    this.homeHealthCategories = const ['weight', 'walk', 'play'], // 기본값: 체중, 산책, 놀이
    this.homeSafetyEnabled = true, // 기본값: 안전구역 기능 ON
    required this.loginProvider,
    this.isVerified = false,
    this.isIdentityVerified = false,
    this.isLocationVerified = false,
    this.locationVerifiedAt,
    this.lastLocationCheckAt,
    this.locationMismatchCount = 0,
    this.locationReminderDismissedAt,
    this.isWalking = false,
    this.walkStartedAt,
    this.petIds = const [],
    this.fcmToken,
    required this.createdAt,
    required this.lastActiveAt,
    this.isPremium = false,
    this.kkosunnaeScore = 50.0,
    this.ratingCount = 0,
    this.nicknameChangedAt,
    this.matchCount = 0,
    this.walkCount = 0,
    this.transactionCount = 0,
    this.groupCount = 0,
    this.postCount = 0,
    this.reportCount = 0,
    this.noShowCount = 0,
    this.averageRating = 0.0,
    this.chatResponseRate,
    this.totalReceivedChats = 0,
    this.respondedChats = 0,
    this.termsAgreedAt,
    this.privacyAgreedAt,
    this.locationConsentAt,
    this.marketingConsentAt,
  });

  /// 나이 계산 (생년월일 기준)
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Firestore 문서에서 UserModel 생성
  factory UserModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      id: id ?? data['id'] ?? '',
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      nickname: data['nickname'] ?? '사용자',
      profileImageUrl: data['profileImageUrl'],
      gender: data['gender'] != null
          ? UserGender.values.firstWhere(
              (e) => e.name == data['gender'],
              orElse: () => UserGender.male,
            )
          : null,
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      bio: data['bio'],
      location: data['location'],
      address: data['address'],
      homeAddress: data['homeAddress'],
      homeLocation: data['homeLocation'],
      homeHealthCategories: List<String>.from(
        data['homeHealthCategories'] ?? ['weight', 'walk', 'play'],
      ),
      homeSafetyEnabled: data['homeSafetyEnabled'] ?? true,
      loginProvider: data['loginProvider'] ?? 'phone',
      isVerified: data['isVerified'] ?? false,
      isIdentityVerified: data['isIdentityVerified'] ?? false,
      isLocationVerified: data['isLocationVerified'] ?? false,
      locationVerifiedAt: data['locationVerifiedAt'] != null
          ? (data['locationVerifiedAt'] as Timestamp).toDate()
          : null,
      lastLocationCheckAt: data['lastLocationCheckAt'] != null
          ? (data['lastLocationCheckAt'] as Timestamp).toDate()
          : null,
      locationMismatchCount: data['locationMismatchCount'] ?? 0,
      locationReminderDismissedAt: data['locationReminderDismissedAt'] != null
          ? (data['locationReminderDismissedAt'] as Timestamp).toDate()
          : null,
      isWalking: data['isWalking'] ?? false,
      walkStartedAt: data['walkStartedAt'] != null
          ? (data['walkStartedAt'] as Timestamp).toDate()
          : null,
      petIds: List<String>.from(data['petIds'] ?? []),
      fcmToken: data['fcmToken'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : DateTime.now(),
      isPremium: data['isPremium'] ?? false,
      kkosunnaeScore: (data['kkosunnaeScore'] ?? 50.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      nicknameChangedAt: data['nicknameChangedAt'] != null
          ? (data['nicknameChangedAt'] as Timestamp).toDate()
          : null,
      matchCount: data['matchCount'] ?? 0,
      walkCount: data['walkCount'] ?? 0,
      transactionCount: data['transactionCount'] ?? 0,
      groupCount: data['groupCount'] ?? 0,
      postCount: data['postCount'] ?? 0,
      reportCount: data['reportCount'] ?? 0,
      noShowCount: data['noShowCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      chatResponseRate: data['chatResponseRate']?.toDouble(),
      totalReceivedChats: data['totalReceivedChats'] ?? 0,
      respondedChats: data['respondedChats'] ?? 0,
      termsAgreedAt: data['termsAgreedAt'] != null
          ? (data['termsAgreedAt'] as Timestamp).toDate()
          : null,
      privacyAgreedAt: data['privacyAgreedAt'] != null
          ? (data['privacyAgreedAt'] as Timestamp).toDate()
          : null,
      locationConsentAt: data['locationConsentAt'] != null
          ? (data['locationConsentAt'] as Timestamp).toDate()
          : null,
      marketingConsentAt: data['marketingConsentAt'] != null
          ? (data['marketingConsentAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'gender': gender?.name,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'bio': bio,
      'location': location,
      'address': address,
      'homeAddress': homeAddress,
      'homeLocation': homeLocation,
      'homeHealthCategories': homeHealthCategories,
      'homeSafetyEnabled': homeSafetyEnabled,
      'loginProvider': loginProvider,
      'isVerified': isVerified,
      'isIdentityVerified': isIdentityVerified,
      'isLocationVerified': isLocationVerified,
      'locationVerifiedAt': locationVerifiedAt != null
          ? Timestamp.fromDate(locationVerifiedAt!)
          : null,
      'lastLocationCheckAt': lastLocationCheckAt != null
          ? Timestamp.fromDate(lastLocationCheckAt!)
          : null,
      'locationMismatchCount': locationMismatchCount,
      'locationReminderDismissedAt': locationReminderDismissedAt != null
          ? Timestamp.fromDate(locationReminderDismissedAt!)
          : null,
      'isWalking': isWalking,
      'walkStartedAt': walkStartedAt != null
          ? Timestamp.fromDate(walkStartedAt!)
          : null,
      'petIds': petIds,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'isPremium': isPremium,
      'kkosunnaeScore': kkosunnaeScore,
      'ratingCount': ratingCount,
      'nicknameChangedAt': nicknameChangedAt != null
          ? Timestamp.fromDate(nicknameChangedAt!)
          : null,
      'matchCount': matchCount,
      'walkCount': walkCount,
      'transactionCount': transactionCount,
      'groupCount': groupCount,
      'postCount': postCount,
      'reportCount': reportCount,
      'noShowCount': noShowCount,
      'averageRating': averageRating,
      'chatResponseRate': chatResponseRate,
      'totalReceivedChats': totalReceivedChats,
      'respondedChats': respondedChats,
      'termsAgreedAt': termsAgreedAt != null
          ? Timestamp.fromDate(termsAgreedAt!)
          : null,
      'privacyAgreedAt': privacyAgreedAt != null
          ? Timestamp.fromDate(privacyAgreedAt!)
          : null,
      'locationConsentAt': locationConsentAt != null
          ? Timestamp.fromDate(locationConsentAt!)
          : null,
      'marketingConsentAt': marketingConsentAt != null
          ? Timestamp.fromDate(marketingConsentAt!)
          : null,
    };
  }

  /// 복사본 생성 (일부 필드 수정)
  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? nickname,
    String? profileImageUrl,
    UserGender? gender,
    DateTime? birthDate,
    String? bio,
    GeoPoint? location,
    String? address,
    String? homeAddress,
    GeoPoint? homeLocation,
    List<String>? homeHealthCategories,
    bool? homeSafetyEnabled,
    String? loginProvider,
    bool? isVerified,
    bool? isIdentityVerified,
    bool? isLocationVerified,
    DateTime? locationVerifiedAt,
    DateTime? lastLocationCheckAt,
    int? locationMismatchCount,
    DateTime? locationReminderDismissedAt,
    bool? isWalking,
    DateTime? walkStartedAt,
    List<String>? petIds,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isPremium,
    double? kkosunnaeScore,
    int? ratingCount,
    DateTime? nicknameChangedAt,
    int? matchCount,
    int? walkCount,
    int? transactionCount,
    int? groupCount,
    int? postCount,
    int? reportCount,
    int? noShowCount,
    double? averageRating,
    double? chatResponseRate,
    int? totalReceivedChats,
    int? respondedChats,
    DateTime? termsAgreedAt,
    DateTime? privacyAgreedAt,
    DateTime? locationConsentAt,
    DateTime? marketingConsentAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      address: address ?? this.address,
      homeAddress: homeAddress ?? this.homeAddress,
      homeLocation: homeLocation ?? this.homeLocation,
      homeHealthCategories: homeHealthCategories ?? this.homeHealthCategories,
      homeSafetyEnabled: homeSafetyEnabled ?? this.homeSafetyEnabled,
      loginProvider: loginProvider ?? this.loginProvider,
      isVerified: isVerified ?? this.isVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      isLocationVerified: isLocationVerified ?? this.isLocationVerified,
      locationVerifiedAt: locationVerifiedAt ?? this.locationVerifiedAt,
      lastLocationCheckAt: lastLocationCheckAt ?? this.lastLocationCheckAt,
      locationMismatchCount: locationMismatchCount ?? this.locationMismatchCount,
      locationReminderDismissedAt: locationReminderDismissedAt ?? this.locationReminderDismissedAt,
      isWalking: isWalking ?? this.isWalking,
      walkStartedAt: walkStartedAt ?? this.walkStartedAt,
      petIds: petIds ?? this.petIds,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isPremium: isPremium ?? this.isPremium,
      kkosunnaeScore: kkosunnaeScore ?? this.kkosunnaeScore,
      ratingCount: ratingCount ?? this.ratingCount,
      nicknameChangedAt: nicknameChangedAt ?? this.nicknameChangedAt,
      matchCount: matchCount ?? this.matchCount,
      walkCount: walkCount ?? this.walkCount,
      transactionCount: transactionCount ?? this.transactionCount,
      groupCount: groupCount ?? this.groupCount,
      postCount: postCount ?? this.postCount,
      reportCount: reportCount ?? this.reportCount,
      noShowCount: noShowCount ?? this.noShowCount,
      averageRating: averageRating ?? this.averageRating,
      chatResponseRate: chatResponseRate ?? this.chatResponseRate,
      totalReceivedChats: totalReceivedChats ?? this.totalReceivedChats,
      respondedChats: respondedChats ?? this.respondedChats,
      termsAgreedAt: termsAgreedAt ?? this.termsAgreedAt,
      privacyAgreedAt: privacyAgreedAt ?? this.privacyAgreedAt,
      locationConsentAt: locationConsentAt ?? this.locationConsentAt,
      marketingConsentAt: marketingConsentAt ?? this.marketingConsentAt,
    );
  }

  /// 빈 사용자 모델 생성 (신규 가입 시)
  factory UserModel.empty(String id, String loginProvider) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      nickname: '새로운 친구',
      loginProvider: loginProvider,
      createdAt: now,
      lastActiveAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        phoneNumber,
        nickname,
        profileImageUrl,
        gender,
        birthDate,
        bio,
        location,
        address,
        homeAddress,
        homeLocation,
        homeHealthCategories,
        homeSafetyEnabled,
        loginProvider,
        isVerified,
        isIdentityVerified,
        isLocationVerified,
        locationVerifiedAt,
        lastLocationCheckAt,
        locationMismatchCount,
        locationReminderDismissedAt,
        isWalking,
        walkStartedAt,
        petIds,
        fcmToken,
        createdAt,
        lastActiveAt,
        isPremium,
        kkosunnaeScore,
        ratingCount,
      ];
}
