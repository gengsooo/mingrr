import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/constants/pet_constants.dart';

/// ============================================================
/// 건강 수첩 관련 모델 (V1 리팩토링)
/// 체중, 산책, 배변, 놀이, 예방접종, 정기검진, 약, 샤워, 
/// 손톱깎기, 털 자르기, 귀 청소, 특이사항 등
/// ============================================================

/// 예방접종 기록 모델
class VaccinationModel extends Equatable {
  /// 기록 ID
  final String id;
  
  /// 반려동물 ID
  final String petId;
  
  /// 백신 이름
  final String vaccineName;
  
  /// 접종일
  final DateTime vaccinationDate;
  
  /// 다음 접종 예정일
  final DateTime? nextDueDate;
  
  /// 병원 이름
  final String? hospitalName;
  
  /// 수의사 이름
  final String? vetName;
  
  /// 메모
  final String? notes;
  
  /// 알림 설정 여부
  final bool reminderEnabled;
  
  /// 알림 시간 (다음 접종일 며칠 전)
  final int reminderDaysBefore;
  
  /// 생성일
  final DateTime createdAt;

  const VaccinationModel({
    required this.id,
    required this.petId,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDueDate,
    this.hospitalName,
    this.vetName,
    this.notes,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 7,
    required this.createdAt,
  });

  factory VaccinationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VaccinationModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      vaccineName: data['vaccineName'] ?? '',
      vaccinationDate: (data['vaccinationDate'] as Timestamp).toDate(),
      nextDueDate: data['nextDueDate'] != null
          ? (data['nextDueDate'] as Timestamp).toDate()
          : null,
      hospitalName: data['hospitalName'],
      vetName: data['vetName'],
      notes: data['notes'],
      reminderEnabled: data['reminderEnabled'] ?? true,
      reminderDaysBefore: data['reminderDaysBefore'] ?? 7,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'vaccineName': vaccineName,
      'vaccinationDate': Timestamp.fromDate(vaccinationDate),
      'nextDueDate': nextDueDate != null
          ? Timestamp.fromDate(nextDueDate!)
          : null,
      'hospitalName': hospitalName,
      'vetName': vetName,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        petId,
        vaccineName,
        vaccinationDate,
        nextDueDate,
        hospitalName,
        vetName,
        notes,
        reminderEnabled,
        reminderDaysBefore,
        createdAt,
      ];
}

/// 체중 기록 모델
class WeightRecordModel extends Equatable {
  final String id;
  final String petId;
  final double weight; // kg
  final DateTime recordDate;
  final String? notes;
  final DateTime createdAt;

  const WeightRecordModel({
    required this.id,
    required this.petId,
    required this.weight,
    required this.recordDate,
    this.notes,
    required this.createdAt,
  });

  factory WeightRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeightRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      recordDate: (data['recordDate'] as Timestamp).toDate(),
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'weight': weight,
      'recordDate': Timestamp.fromDate(recordDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, petId, weight, recordDate, notes, createdAt];
}

/// ============================================================
/// 대변 상태 (StoolCondition)
/// ============================================================
enum StoolCondition {
  normal('정상', '🟢'),
  soft('무른 변', '🟡'),
  hard('딱딱한 변', '🟤'),
  diarrhea('설사', '🟠'),
  bloody('혈변', '🔴'),
  mucus('점액변', '🟣');

  final String label;
  final String emoji;
  
  const StoolCondition(this.label, this.emoji);
}

/// 대변 기록 모델
class StoolRecordModel extends Equatable {
  final String id;
  final String petId;
  final DateTime recordTime;
  final StoolCondition condition;
  final String? color;
  final String? notes;
  final DateTime createdAt;

  const StoolRecordModel({
    required this.id,
    required this.petId,
    required this.recordTime,
    required this.condition,
    this.color,
    this.notes,
    required this.createdAt,
  });

  factory StoolRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoolRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordTime: (data['recordTime'] as Timestamp).toDate(),
      condition: StoolCondition.values.firstWhere(
        (e) => e.name == data['condition'],
        orElse: () => StoolCondition.normal,
      ),
      color: data['color'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'recordTime': Timestamp.fromDate(recordTime),
      'condition': condition.name,
      'color': color,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, petId, recordTime, condition, color, notes, createdAt];
}

/// ============================================================
/// 소변 상태 (UrineCondition)
/// ============================================================
enum UrineCondition {
  normal('정상', '🟢'),
  dark('진한 색', '🟤'),
  light('연한 색', '🟡'),
  cloudy('탁함', '⚪'),
  bloody('혈뜨', '🔴'),
  frequent('빈뉘', '🟠');

  final String label;
  final String emoji;
  
  const UrineCondition(this.label, this.emoji);
}

/// 소변 기록 모델
class UrineRecordModel extends Equatable {
  final String id;
  final String petId;
  final DateTime recordTime;
  final UrineCondition condition;
  final String? notes;
  final DateTime createdAt;

  const UrineRecordModel({
    required this.id,
    required this.petId,
    required this.recordTime,
    required this.condition,
    this.notes,
    required this.createdAt,
  });

  factory UrineRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UrineRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordTime: (data['recordTime'] as Timestamp).toDate(),
      condition: UrineCondition.values.firstWhere(
        (e) => e.name == data['condition'],
        orElse: () => UrineCondition.normal,
      ),
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'recordTime': Timestamp.fromDate(recordTime),
      'condition': condition.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, petId, recordTime, condition, notes, createdAt];
}

/// ============================================================
/// 음수 기록 모델 (식물: 물주기)
/// ============================================================
class WaterRecordModel extends Equatable {
  final String id;
  final String petId;
  final DateTime recordTime;
  final double? amountMl;  // 음수량 (ml), null이면 기록만
  final String? notes;
  final DateTime createdAt;

  const WaterRecordModel({
    required this.id,
    required this.petId,
    required this.recordTime,
    this.amountMl,
    this.notes,
    required this.createdAt,
  });

  /// 음수량 표시 문자열
  String get amountString {
    if (amountMl == null) return '기록됨';
    if (amountMl! >= 1000) return '${(amountMl! / 1000).toStringAsFixed(1)}L';
    return '${amountMl!.toInt()}ml';
  }

  factory WaterRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaterRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordTime: (data['recordTime'] as Timestamp).toDate(),
      amountMl: data['amountMl']?.toDouble(),
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'recordTime': Timestamp.fromDate(recordTime),
      'amountMl': amountMl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, petId, recordTime, amountMl, notes, createdAt];
}

/// ============================================================
/// 산책 기록 모델
/// - 다중 반려동물 동시 산책 지원 (petIds)
/// - 이동 경로 저장 (routePoints)
/// - 본인만 확인 가능 (개인정보 보호)
/// ============================================================
class WalkRecordModel extends Equatable {
  final String id;
  
  /// 단일 반려동물 ID (하위 호환성)
  final String petId;
  
  /// 다중 반려동물 ID 목록 (동시 산책 지원)
  final List<String> petIds;
  
  final String userId;
  
  /// 시작 시간
  final DateTime startTime;
  
  /// 종료 시간
  final DateTime? endTime;
  
  /// 거리 (미터)
  final double distance;
  
  /// 소모 칼로리
  final double? calories;
  
  /// 경로 좌표 목록
  final List<GeoPoint> routePoints;
  
  /// 발자국 남긴 위치들
  final List<GeoPoint> footprints;
  
  /// 메모
  final String? notes;
  
  /// 사진 URL 목록
  final List<String> photoUrls;
  
  /// 생성일
  final DateTime createdAt;

  const WalkRecordModel({
    required this.id,
    required this.petId,
    this.petIds = const [],
    required this.userId,
    required this.startTime,
    this.endTime,
    this.distance = 0,
    this.calories,
    this.routePoints = const [],
    this.footprints = const [],
    this.notes,
    this.photoUrls = const [],
    required this.createdAt,
  });
  
  /// 산책중인 반려동물 ID 목록 (단일 + 다중 통합)
  List<String> get allPetIds {
    final ids = <String>{petId};
    ids.addAll(petIds);
    return ids.toList();
  }
  
  /// 산책 진행 중 여부
  bool get isOngoing => endTime == null;

  /// 산책 시간 (분)
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  /// 거리 표시 문자열
  String get distanceString {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
    return '${distance.toInt()}m';
  }

  /// 시간 표시 문자열
  String get durationString {
    final minutes = durationMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours시간 $mins분';
    }
    return '$minutes분';
  }

  factory WalkRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalkRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      petIds: List<String>.from(data['petIds'] ?? []),
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      distance: (data['distance'] ?? 0).toDouble(),
      calories: data['calories']?.toDouble(),
      routePoints: (data['routePoints'] as List<dynamic>?)
              ?.map((p) => p as GeoPoint)
              .toList() ??
          [],
      footprints: (data['footprints'] as List<dynamic>?)
              ?.map((p) => p as GeoPoint)
              .toList() ??
          [],
      notes: data['notes'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'petIds': petIds,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'distance': distance,
      'calories': calories,
      'routePoints': routePoints,
      'footprints': footprints,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WalkRecordModel copyWith({
    String? id,
    String? petId,
    List<String>? petIds,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    double? calories,
    List<GeoPoint>? routePoints,
    List<GeoPoint>? footprints,
    String? notes,
    List<String>? photoUrls,
    DateTime? createdAt,
  }) {
    return WalkRecordModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petIds: petIds ?? this.petIds,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      routePoints: routePoints ?? this.routePoints,
      footprints: footprints ?? this.footprints,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        petId,
        petIds,
        userId,
        startTime,
        endTime,
        distance,
        calories,
        routePoints,
        footprints,
        notes,
        photoUrls,
        createdAt,
      ];
}

/// ============================================================
/// 놀이 기록 모델 (고양이 등 산책 안하는 동물용)
/// ============================================================
class PlayRecordModel extends Equatable {
  final String id;
  final String petId;
  final DateTime recordTime;
  final int durationMinutes;
  final String? playType;
  final String? notes;
  final DateTime createdAt;

  const PlayRecordModel({
    required this.id,
    required this.petId,
    required this.recordTime,
    required this.durationMinutes,
    this.playType,
    this.notes,
    required this.createdAt,
  });

  String get durationString {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      return '$hours시간 $mins분';
    }
    return '$durationMinutes분';
  }

  factory PlayRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordTime: (data['recordTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
      playType: data['playType'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'recordTime': Timestamp.fromDate(recordTime),
      'durationMinutes': durationMinutes,
      'playType': playType,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, petId, recordTime, durationMinutes, playType, notes, createdAt];
}

/// ============================================================
/// 정기검진 기록 모델
/// ============================================================
class CheckupRecordModel extends Equatable {
  final String id;
  final String petId;
  final DateTime checkupDate;
  final DateTime? nextCheckupDate;
  final String? hospitalName;
  final String? vetName;
  final String? diagnosis;
  final String? notes;
  final List<String> attachmentUrls;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final DateTime createdAt;

  const CheckupRecordModel({
    required this.id,
    required this.petId,
    required this.checkupDate,
    this.nextCheckupDate,
    this.hospitalName,
    this.vetName,
    this.diagnosis,
    this.notes,
    this.attachmentUrls = const [],
    this.reminderEnabled = true,
    this.reminderDaysBefore = 7,
    required this.createdAt,
  });

  factory CheckupRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckupRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      checkupDate: (data['checkupDate'] as Timestamp).toDate(),
      nextCheckupDate: data['nextCheckupDate'] != null
          ? (data['nextCheckupDate'] as Timestamp).toDate()
          : null,
      hospitalName: data['hospitalName'],
      vetName: data['vetName'],
      diagnosis: data['diagnosis'],
      notes: data['notes'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      reminderEnabled: data['reminderEnabled'] ?? true,
      reminderDaysBefore: data['reminderDaysBefore'] ?? 7,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'checkupDate': Timestamp.fromDate(checkupDate),
      'nextCheckupDate': nextCheckupDate != null
          ? Timestamp.fromDate(nextCheckupDate!)
          : null,
      'hospitalName': hospitalName,
      'vetName': vetName,
      'diagnosis': diagnosis,
      'notes': notes,
      'attachmentUrls': attachmentUrls,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id, petId, checkupDate, nextCheckupDate, hospitalName,
        vetName, diagnosis, notes, attachmentUrls, reminderEnabled,
        reminderDaysBefore, createdAt,
      ];
}

/// ============================================================
/// 약 복용 기록 모델
/// ============================================================
class MedicationRecordModel extends Equatable {
  final String id;
  final String petId;
  final String medicationName;
  final String? dosage;
  final MedicationInterval interval;
  final int? intervalValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool reminderEnabled;
  final List<String> reminderTimes;
  final DateTime createdAt;

  const MedicationRecordModel({
    required this.id,
    required this.petId,
    required this.medicationName,
    this.dosage,
    required this.interval,
    this.intervalValue,
    required this.startDate,
    this.endDate,
    this.notes,
    this.reminderEnabled = true,
    this.reminderTimes = const [],
    required this.createdAt,
  });

  String get intervalString {
    if (interval == MedicationInterval.asNeeded) {
      return '필요시';
    }
    if (intervalValue == null) return interval.label;
    
    switch (interval) {
      case MedicationInterval.everyHours:
        return '$intervalValue시간마다';
      case MedicationInterval.daily:
        return intervalValue == 1 ? '매일' : '$intervalValue일마다';
      case MedicationInterval.weekly:
        return intervalValue == 1 ? '매주' : '$intervalValue주마다';
      case MedicationInterval.monthly:
        return intervalValue == 1 ? '매월' : '$intervalValue개월마다';
      default:
        return interval.label;
    }
  }

  factory MedicationRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      dosage: data['dosage'],
      interval: MedicationInterval.values.firstWhere(
        (e) => e.name == data['interval'],
        orElse: () => MedicationInterval.daily,
      ),
      intervalValue: data['intervalValue'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      reminderEnabled: data['reminderEnabled'] ?? true,
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'medicationName': medicationName,
      'dosage': dosage,
      'interval': interval.name,
      'intervalValue': intervalValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderTimes': reminderTimes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id, petId, medicationName, dosage, interval, intervalValue,
        startDate, endDate, notes, reminderEnabled, reminderTimes, createdAt,
      ];
}

/// ============================================================
/// 그루밍 기록 모델 (샤워, 손톱깎기, 털 자르기, 귀 청소 등)
/// ============================================================
class GroomingRecordModel extends Equatable {
  final String id;
  final String petId;
  final HealthCategory groomingType;
  final DateTime recordDate;
  final String? location;
  final int? cost;
  final String? notes;
  final List<String> photoUrls;
  final DateTime createdAt;

  const GroomingRecordModel({
    required this.id,
    required this.petId,
    required this.groomingType,
    required this.recordDate,
    this.location,
    this.cost,
    this.notes,
    this.photoUrls = const [],
    required this.createdAt,
  });

  factory GroomingRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroomingRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      groomingType: HealthCategory.values.firstWhere(
        (e) => e.name == data['groomingType'],
        orElse: () => HealthCategory.shower,
      ),
      recordDate: (data['recordDate'] as Timestamp).toDate(),
      location: data['location'],
      cost: data['cost'],
      notes: data['notes'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'groomingType': groomingType.name,
      'recordDate': Timestamp.fromDate(recordDate),
      'location': location,
      'cost': cost,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id, petId, groomingType, recordDate, location, cost, notes, photoUrls, createdAt,
      ];
}

/// ============================================================
/// 특이사항 기록 모델
/// ============================================================
class SpecialNoteModel extends Equatable {
  final String id;
  final String petId;
  final DateTime recordDate;
  final String title;
  final String content;
  final List<String> photoUrls;
  final DateTime createdAt;

  const SpecialNoteModel({
    required this.id,
    required this.petId,
    required this.recordDate,
    required this.title,
    required this.content,
    this.photoUrls = const [],
    required this.createdAt,
  });

  factory SpecialNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialNoteModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordDate: (data['recordDate'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'recordDate': Timestamp.fromDate(recordDate),
      'title': title,
      'content': content,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, petId, recordDate, title, content, photoUrls, createdAt];
}

/// ============================================================
/// 교배 기록 모델
/// ============================================================
class BreedingRecordModel extends Equatable {
  final String id;
  final String petId;
  final String partnerPetId;
  final String partnerOwnerId;
  final DateTime breedingDate;
  final String? location;
  final String? notes;
  final bool isSuccessful;
  final DateTime createdAt;

  const BreedingRecordModel({
    required this.id,
    required this.petId,
    required this.partnerPetId,
    required this.partnerOwnerId,
    required this.breedingDate,
    this.location,
    this.notes,
    this.isSuccessful = false,
    required this.createdAt,
  });

  factory BreedingRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BreedingRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      partnerPetId: data['partnerPetId'] ?? '',
      partnerOwnerId: data['partnerOwnerId'] ?? '',
      breedingDate: (data['breedingDate'] as Timestamp).toDate(),
      location: data['location'],
      notes: data['notes'],
      isSuccessful: data['isSuccessful'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'partnerPetId': partnerPetId,
      'partnerOwnerId': partnerOwnerId,
      'breedingDate': Timestamp.fromDate(breedingDate),
      'location': location,
      'notes': notes,
      'isSuccessful': isSuccessful,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id, petId, partnerPetId, partnerOwnerId, breedingDate,
        location, notes, isSuccessful, createdAt,
      ];
}
