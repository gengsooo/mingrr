import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/constants/pet_constants.dart';

/// ============================================================
/// 반려동물 모델 (V2 리팩토링)
/// 
/// 변경사항:
/// - PetType 제거 (반려동물 통합)
/// - 통일된 Pet 명칭 사용 (PetSize, PetGender, PetTrait)
/// - 50개 특성 시스템, 건강수첩 연동
/// ============================================================

class PetModel extends Equatable {
  /// 고유 ID
  final String id;
  
  /// 보호자(사용자) ID
  final String ownerId;
  
  /// 대표 반려동물 여부 (여러 마리 중 대표로 표시될 반려동물)
  final bool isPrimary;
  
  /// 반려동물 이름
  final String name;
  
  /// 품종 (예: 골든 리트리버, 말티즈 등)
  final String? breed;
  
  /// 성별
  final PetGender gender;
  
  /// 생년월일
  final DateTime? birthDate;
  
  /// 몸무게 (kg)
  final double? weight;
  
  /// 중성화 여부
  final bool isNeutered;
  
  /// 특성 목록 (최소 5개 이상)
  final List<PetTrait> traits;
  
  /// 자기소개/특징
  final String? bio;
  
  /// 프로필 이미지 URL
  final String? profileImageUrl;
  
  /// 추가 사진 URL 목록 (첫 번째가 대표사진)
  final List<String> photoUrls;
  
  /// 동물등록번호
  final String? registrationNumber;
  
  /// 동물등록 인증 여부
  final bool isRegistrationVerified;
  
  /// 예방접종 인증 여부
  final bool isVaccinationVerified;
  
  /// 혈통서 보유 여부
  final bool hasPedigree;
  
  /// 혈통서 이미지 URL
  final String? pedigreeImageUrl;
  
  /// 마지막 건강검진일
  final DateTime? lastHealthCheckDate;
  
  /// 교배 가능 여부
  final bool isBreedingAvailable;
  
  /// 건강수첩 활성화 여부
  final bool healthBookEnabled;
  
  /// 활성화된 건강수첩 카테고리
  final List<HealthCategory> enabledHealthCategories;
  
  /// 산책 기능 활성화 여부
  final bool walkFeatureEnabled;
  
  /// 좋아요 수
  final int likeCount;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 수정일
  final DateTime updatedAt;

  const PetModel({
    required this.id,
    required this.ownerId,
    this.isPrimary = false,
    required this.name,
    this.breed,
    required this.gender,
    this.birthDate,
    this.weight,
    this.isNeutered = false,
    this.traits = const [],
    this.bio,
    this.profileImageUrl,
    this.photoUrls = const [],
    this.registrationNumber,
    this.isRegistrationVerified = false,
    this.isVaccinationVerified = false,
    this.hasPedigree = false,
    this.pedigreeImageUrl,
    this.lastHealthCheckDate,
    this.isBreedingAvailable = false,
    this.healthBookEnabled = false,
    this.enabledHealthCategories = const [],
    this.walkFeatureEnabled = true,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 나이 계산 (개월 단위도 표시)
  String get ageString {
    if (birthDate == null) return '나이 미상';
    
    final now = DateTime.now();
    final difference = now.difference(birthDate!);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    
    if (years > 0) {
      return months > 0 ? '$years살 $months개월' : '$years살';
    } else {
      return '$months개월';
    }
  }

  /// 나이 (년 단위)
  int? get ageYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.difference(birthDate!).inDays ~/ 365;
  }

  /// 성별 한글 표시
  String get genderString => gender.label;

  /// 성별 기호
  String get genderSymbol => gender.symbol;

  /// 체중 크기 분류
  PetSize? get size {
    if (weight == null) return null;
    return PetSize.fromWeight(weight!);
  }

  /// 체중 크기 한글 표시
  String get sizeString => size?.label ?? '미입력';

  /// 특성 한글 목록
  List<String> get traitLabels => traits.map((t) => t.label).toList();

  /// 산책 가능 여부
  bool get canWalk => walkFeatureEnabled;

  /// 특성 유효성 검사 (최소 5개)
  bool get hasValidTraits => traits.length >= 5;

  /// 표시용 이미지 URL (추가사진 대표 > null)
  /// 리스트, 카드, 상세화면 등에서 사각형 이미지로 사용
  /// 추가사진이 없으면 null 반환 (기본 아이콘 표시)
  String? get displayImageUrl {
    if (photoUrls.isNotEmpty) {
      return photoUrls.first;
    }
    return null;
  }
  
  /// 하위 호환성을 위한 alias
  @Deprecated('Use displayImageUrl instead')
  String? get primaryPhotoUrl => displayImageUrl;

  /// Firestore 문서에서 PetModel 생성
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
      name: data['name'] ?? '',
      breed: data['breed'],
      gender: PetGender.values.firstWhere(
        (e) => e.name == data['gender'],
        orElse: () => PetGender.male,
      ),
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      weight: data['weight']?.toDouble(),
      isNeutered: data['isNeutered'] ?? false,
      traits: (data['traits'] as List<dynamic>?)
              ?.map((t) => PetTrait.values.firstWhere(
                    (e) => e.name == t,
                    orElse: () => PetTrait.friendly,
                  ))
              .toList() ??
          [],
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      registrationNumber: data['registrationNumber'],
      isRegistrationVerified: data['isRegistrationVerified'] ?? false,
      isVaccinationVerified: data['isVaccinationVerified'] ?? false,
      hasPedigree: data['hasPedigree'] ?? false,
      pedigreeImageUrl: data['pedigreeImageUrl'],
      lastHealthCheckDate: data['lastHealthCheckDate'] != null
          ? (data['lastHealthCheckDate'] as Timestamp).toDate()
          : null,
      isBreedingAvailable: data['isBreedingAvailable'] ?? false,
      healthBookEnabled: data['healthBookEnabled'] ?? false,
      enabledHealthCategories: (data['enabledHealthCategories'] as List<dynamic>?)
              ?.map((c) => HealthCategory.values.firstWhere(
                    (e) => e.name == c,
                    orElse: () => HealthCategory.weight,
                  ))
              .toList() ??
          [],
      walkFeatureEnabled: data['walkFeatureEnabled'] ?? true,
      likeCount: data['likeCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'isPrimary': isPrimary,
      'name': name,
      'breed': breed,
      'gender': gender.name,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'weight': weight,
      'isNeutered': isNeutered,
      'traits': traits.map((t) => t.name).toList(),
      'type': 'dog', // 호환성을 위해 유지
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'photoUrls': photoUrls,
      'registrationNumber': registrationNumber,
      'isRegistrationVerified': isRegistrationVerified,
      'isVaccinationVerified': isVaccinationVerified,
      'hasPedigree': hasPedigree,
      'pedigreeImageUrl': pedigreeImageUrl,
      'lastHealthCheckDate': lastHealthCheckDate != null
          ? Timestamp.fromDate(lastHealthCheckDate!)
          : null,
      'isBreedingAvailable': isBreedingAvailable,
      'healthBookEnabled': healthBookEnabled,
      'enabledHealthCategories': enabledHealthCategories.map((c) => c.name).toList(),
      'walkFeatureEnabled': walkFeatureEnabled,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 복사본 생성
  PetModel copyWith({
    String? id,
    String? ownerId,
    bool? isPrimary,
    String? name,
    String? breed,
    PetGender? gender,
    DateTime? birthDate,
    double? weight,
    bool? isNeutered,
    List<PetTrait>? traits,
    String? bio,
    String? profileImageUrl,
    List<String>? photoUrls,
    String? registrationNumber,
    bool? isRegistrationVerified,
    bool? isVaccinationVerified,
    bool? hasPedigree,
    String? pedigreeImageUrl,
    DateTime? lastHealthCheckDate,
    bool? isBreedingAvailable,
    bool? healthBookEnabled,
    List<HealthCategory>? enabledHealthCategories,
    bool? walkFeatureEnabled,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      isPrimary: isPrimary ?? this.isPrimary,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      isNeutered: isNeutered ?? this.isNeutered,
      traits: traits ?? this.traits,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      isRegistrationVerified: isRegistrationVerified ?? this.isRegistrationVerified,
      isVaccinationVerified: isVaccinationVerified ?? this.isVaccinationVerified,
      hasPedigree: hasPedigree ?? this.hasPedigree,
      pedigreeImageUrl: pedigreeImageUrl ?? this.pedigreeImageUrl,
      lastHealthCheckDate: lastHealthCheckDate ?? this.lastHealthCheckDate,
      isBreedingAvailable: isBreedingAvailable ?? this.isBreedingAvailable,
      healthBookEnabled: healthBookEnabled ?? this.healthBookEnabled,
      enabledHealthCategories: enabledHealthCategories ?? this.enabledHealthCategories,
      walkFeatureEnabled: walkFeatureEnabled ?? this.walkFeatureEnabled,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 빈 모델 생성 (신규 등록 시)
  factory PetModel.empty(String ownerId) {
    final now = DateTime.now();
    return PetModel(
      id: '',
      ownerId: ownerId,
      name: '',
      gender: PetGender.male,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        isPrimary,
        name,
        breed,
        gender,
        birthDate,
        weight,
        isNeutered,
        traits,
        bio,
        profileImageUrl,
        photoUrls,
        registrationNumber,
        isRegistrationVerified,
        isVaccinationVerified,
        hasPedigree,
        pedigreeImageUrl,
        lastHealthCheckDate,
        isBreedingAvailable,
        healthBookEnabled,
        enabledHealthCategories,
        walkFeatureEnabled,
        likeCount,
        createdAt,
        updatedAt,
      ];
}
