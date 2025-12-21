import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 건강 수첩 관련 모델
/// 예방접종, 체중, 배변, 산책 기록 등 데이터 구조
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

/// 배변 상태
enum PoopCondition {
  normal,     // 정상
  soft,       // 무른 변
  hard,       // 딱딱한 변
  diarrhea,   // 설사
  bloody,     // 혈변
  mucus,      // 점액변
}

/// 배변 기록 모델
class PoopRecordModel extends Equatable {
  final String id;
  final String petId;
  final DateTime recordTime;
  final PoopCondition condition;
  final String? color;
  final String? notes;
  final DateTime createdAt;

  const PoopRecordModel({
    required this.id,
    required this.petId,
    required this.recordTime,
    required this.condition,
    this.color,
    this.notes,
    required this.createdAt,
  });

  /// 상태 한글 표시
  String get conditionString {
    switch (condition) {
      case PoopCondition.normal:
        return '정상';
      case PoopCondition.soft:
        return '무른 변';
      case PoopCondition.hard:
        return '딱딱한 변';
      case PoopCondition.diarrhea:
        return '설사';
      case PoopCondition.bloody:
        return '혈변';
      case PoopCondition.mucus:
        return '점액변';
    }
  }

  factory PoopRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoopRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordTime: (data['recordTime'] as Timestamp).toDate(),
      condition: PoopCondition.values.firstWhere(
        (e) => e.name == data['condition'],
        orElse: () => PoopCondition.normal,
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
  List<Object?> get props => [
        id,
        petId,
        recordTime,
        condition,
        color,
        notes,
        createdAt,
      ];
}

/// 산책 기록 모델
class WalkRecordModel extends Equatable {
  final String id;
  final String petId;
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
