import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 반려동물 모델
/// 반려동물의 모든 정보를 담는 데이터 구조
/// ============================================================

/// 반려동물 종류 열거형
enum PetType {
  dog,    // 강아지
  cat,    // 고양이
  bird,   // 새
  fish,   // 물고기
  rabbit, // 토끼
  hamster,// 햄스터
  other,  // 기타
}

/// 반려동물 성별 열거형
enum PetGender {
  male,   // 수컷
  female, // 암컷
}

/// 반려동물 성격 유형
enum PetPersonality {
  active,     // 활발한
  calm,       // 차분한
  friendly,   // 친화적인
  shy,        // 수줍은
  playful,    // 장난스러운
  protective, // 보호적인
  independent,// 독립적인
  affectionate,// 애정적인
}

class PetModel extends Equatable {
  /// 고유 ID
  final String id;
  
  /// 보호자(사용자) ID
  final String ownerId;
  
  /// 반려동물 이름
  final String name;
  
  /// 종류 (강아지, 고양이 등)
  final PetType type;
  
  /// 품종 (예: 골든 리트리버, 페르시안 등)
  final String? breed;
  
  /// 성별
  final PetGender gender;
  
  /// 생년월일
  final DateTime? birthDate;
  
  /// 몸무게 (kg)
  final double? weight;
  
  /// 중성화 여부
  final bool isNeutered;
  
  /// 성격 목록
  final List<PetPersonality> personalities;
  
  /// 자기소개/특징
  final String? bio;
  
  /// 프로필 이미지 URL
  final String? profileImageUrl;
  
  /// 추가 사진 URL 목록
  final List<String> photoUrls;
  
  /// 동물등록번호
  final String? registrationNumber;
  
  /// 동물등록 인증 여부
  final bool isRegistrationVerified;
  
  /// 혈통서 보유 여부
  final bool hasPedigree;
  
  /// 혈통서 이미지 URL
  final String? pedigreeImageUrl;
  
  /// 건강 인증서 보유 여부
  final bool hasHealthCertificate;
  
  /// 마지막 건강검진일
  final DateTime? lastHealthCheckDate;
  
  /// 예방접종 완료 여부
  final bool isVaccinationComplete;
  
  /// 교배 가능 여부
  final bool isBreedingAvailable;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 수정일
  final DateTime updatedAt;

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.breed,
    required this.gender,
    this.birthDate,
    this.weight,
    this.isNeutered = false,
    this.personalities = const [],
    this.bio,
    this.profileImageUrl,
    this.photoUrls = const [],
    this.registrationNumber,
    this.isRegistrationVerified = false,
    this.hasPedigree = false,
    this.pedigreeImageUrl,
    this.hasHealthCertificate = false,
    this.lastHealthCheckDate,
    this.isVaccinationComplete = false,
    this.isBreedingAvailable = false,
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

  /// 종류 한글 표시
  String get typeString {
    switch (type) {
      case PetType.dog:
        return '강아지';
      case PetType.cat:
        return '고양이';
      case PetType.bird:
        return '새';
      case PetType.fish:
        return '물고기';
      case PetType.rabbit:
        return '토끼';
      case PetType.hamster:
        return '햄스터';
      case PetType.other:
        return '기타';
    }
  }

  /// 성별 한글 표시
  String get genderString {
    return gender == PetGender.male ? '수컷' : '암컷';
  }

  /// 성격 한글 목록
  List<String> get personalityStrings {
    return personalities.map((p) {
      switch (p) {
        case PetPersonality.active:
          return '활발한';
        case PetPersonality.calm:
          return '차분한';
        case PetPersonality.friendly:
          return '친화적인';
        case PetPersonality.shy:
          return '수줍은';
        case PetPersonality.playful:
          return '장난스러운';
        case PetPersonality.protective:
          return '보호적인';
        case PetPersonality.independent:
          return '독립적인';
        case PetPersonality.affectionate:
          return '애정적인';
      }
    }).toList();
  }

  /// Firestore 문서에서 PetModel 생성
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      type: PetType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PetType.dog,
      ),
      breed: data['breed'],
      gender: data['gender'] == 'female' ? PetGender.female : PetGender.male,
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      weight: data['weight']?.toDouble(),
      isNeutered: data['isNeutered'] ?? false,
      personalities: (data['personalities'] as List<dynamic>?)
              ?.map((p) => PetPersonality.values.firstWhere(
                    (e) => e.name == p,
                    orElse: () => PetPersonality.friendly,
                  ))
              .toList() ??
          [],
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      registrationNumber: data['registrationNumber'],
      isRegistrationVerified: data['isRegistrationVerified'] ?? false,
      hasPedigree: data['hasPedigree'] ?? false,
      pedigreeImageUrl: data['pedigreeImageUrl'],
      hasHealthCertificate: data['hasHealthCertificate'] ?? false,
      lastHealthCheckDate: data['lastHealthCheckDate'] != null
          ? (data['lastHealthCheckDate'] as Timestamp).toDate()
          : null,
      isVaccinationComplete: data['isVaccinationComplete'] ?? false,
      isBreedingAvailable: data['isBreedingAvailable'] ?? false,
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
      'name': name,
      'type': type.name,
      'breed': breed,
      'gender': gender.name,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'weight': weight,
      'isNeutered': isNeutered,
      'personalities': personalities.map((p) => p.name).toList(),
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'photoUrls': photoUrls,
      'registrationNumber': registrationNumber,
      'isRegistrationVerified': isRegistrationVerified,
      'hasPedigree': hasPedigree,
      'pedigreeImageUrl': pedigreeImageUrl,
      'hasHealthCertificate': hasHealthCertificate,
      'lastHealthCheckDate': lastHealthCheckDate != null
          ? Timestamp.fromDate(lastHealthCheckDate!)
          : null,
      'isVaccinationComplete': isVaccinationComplete,
      'isBreedingAvailable': isBreedingAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 복사본 생성
  PetModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    PetType? type,
    String? breed,
    PetGender? gender,
    DateTime? birthDate,
    double? weight,
    bool? isNeutered,
    List<PetPersonality>? personalities,
    String? bio,
    String? profileImageUrl,
    List<String>? photoUrls,
    String? registrationNumber,
    bool? isRegistrationVerified,
    bool? hasPedigree,
    String? pedigreeImageUrl,
    bool? hasHealthCertificate,
    DateTime? lastHealthCheckDate,
    bool? isVaccinationComplete,
    bool? isBreedingAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      isNeutered: isNeutered ?? this.isNeutered,
      personalities: personalities ?? this.personalities,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      isRegistrationVerified:
          isRegistrationVerified ?? this.isRegistrationVerified,
      hasPedigree: hasPedigree ?? this.hasPedigree,
      pedigreeImageUrl: pedigreeImageUrl ?? this.pedigreeImageUrl,
      hasHealthCertificate:
          hasHealthCertificate ?? this.hasHealthCertificate,
      lastHealthCheckDate: lastHealthCheckDate ?? this.lastHealthCheckDate,
      isVaccinationComplete:
          isVaccinationComplete ?? this.isVaccinationComplete,
      isBreedingAvailable: isBreedingAvailable ?? this.isBreedingAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        type,
        breed,
        gender,
        birthDate,
        weight,
        isNeutered,
        personalities,
        bio,
        profileImageUrl,
        photoUrls,
        registrationNumber,
        isRegistrationVerified,
        hasPedigree,
        pedigreeImageUrl,
        hasHealthCertificate,
        lastHealthCheckDate,
        isVaccinationComplete,
        isBreedingAvailable,
        createdAt,
        updatedAt,
      ];
}
