import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 사용자(보호자) 모델
/// Firebase Firestore와 연동되는 사용자 데이터 구조
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
  
  /// 성별 (male, female, other)
  final String? gender;
  
  /// 생년월일
  final DateTime? birthDate;
  
  /// 자기소개
  final String? bio;
  
  /// 현재 위치 (GeoPoint)
  final GeoPoint? location;
  
  /// 주소 (표시용)
  final String? address;
  
  /// 로그인 제공자 (phone, kakao, naver, google)
  final String loginProvider;
  
  /// 동물등록 인증 여부
  final bool isVerified;
  
  /// 본인 인증 여부
  final bool isIdentityVerified;
  
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
    required this.loginProvider,
    this.isVerified = false,
    this.isIdentityVerified = false,
    this.isWalking = false,
    this.walkStartedAt,
    this.petIds = const [],
    this.fcmToken,
    required this.createdAt,
    required this.lastActiveAt,
    this.isPremium = false,
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
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      nickname: data['nickname'] ?? '사용자',
      profileImageUrl: data['profileImageUrl'],
      gender: data['gender'],
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      bio: data['bio'],
      location: data['location'],
      address: data['address'],
      loginProvider: data['loginProvider'] ?? 'phone',
      isVerified: data['isVerified'] ?? false,
      isIdentityVerified: data['isIdentityVerified'] ?? false,
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
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'bio': bio,
      'location': location,
      'address': address,
      'loginProvider': loginProvider,
      'isVerified': isVerified,
      'isIdentityVerified': isIdentityVerified,
      'isWalking': isWalking,
      'walkStartedAt': walkStartedAt != null
          ? Timestamp.fromDate(walkStartedAt!)
          : null,
      'petIds': petIds,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'isPremium': isPremium,
    };
  }

  /// 복사본 생성 (일부 필드 수정)
  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? nickname,
    String? profileImageUrl,
    String? gender,
    DateTime? birthDate,
    String? bio,
    GeoPoint? location,
    String? address,
    String? loginProvider,
    bool? isVerified,
    bool? isIdentityVerified,
    bool? isWalking,
    DateTime? walkStartedAt,
    List<String>? petIds,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isPremium,
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
      loginProvider: loginProvider ?? this.loginProvider,
      isVerified: isVerified ?? this.isVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      isWalking: isWalking ?? this.isWalking,
      walkStartedAt: walkStartedAt ?? this.walkStartedAt,
      petIds: petIds ?? this.petIds,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isPremium: isPremium ?? this.isPremium,
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
        loginProvider,
        isVerified,
        isIdentityVerified,
        isWalking,
        walkStartedAt,
        petIds,
        fcmToken,
        createdAt,
        lastActiveAt,
        isPremium,
      ];
}
