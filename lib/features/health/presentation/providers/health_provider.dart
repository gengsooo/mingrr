import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../models/health_model.dart';
import '../../../../models/pet_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// ============================================================
/// 건강수첩 Provider (Firebase 연동)
/// ============================================================

final _firebaseService = FirebaseService();

/// 선택된 반려동물 ID
final selectedPetIdProvider = StateProvider<String?>((ref) {
  final petsAsync = ref.watch(userPetsProvider);
  return petsAsync.whenOrNull(
    data: (pets) => pets.isNotEmpty ? pets.first.id : null,
  );
});

/// 선택된 탭 인덱스
final selectedHealthTabProvider = StateProvider<int>((ref) => 0);

/// 체중 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final weightRecordsProvider = StreamProvider.family<List<WeightRecordModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('weight_records')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => WeightRecordModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
        return records.take(20).toList();
      });
});

/// 산책 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final walkRecordsProvider = StreamProvider.family<List<WalkRecordModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('walk_records')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => WalkRecordModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.startTime.compareTo(a.startTime));
        return records.take(20).toList();
      });
});

/// 그루밍 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final groomingRecordsProvider = StreamProvider.family<List<GroomingRecordModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('grooming_records')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => GroomingRecordModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
        return records.take(20).toList();
      });
});

/// 예방접종 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final vaccinationRecordsProvider = StreamProvider.family<List<VaccinationModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('vaccination_records')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => VaccinationModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.vaccinationDate.compareTo(a.vaccinationDate));
        return records.take(20).toList();
      });
});

/// 검진 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final checkupRecordsProvider = StreamProvider.family<List<CheckupRecordModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('checkup_records')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => CheckupRecordModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.checkupDate.compareTo(a.checkupDate));
        return records.take(20).toList();
      });
});

/// 약 복용 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final medicationRecordsProvider = StreamProvider.family<List<MedicationRecordModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('medication_records')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => MedicationRecordModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.startDate.compareTo(a.startDate));
        return records.take(20).toList();
      });
});

/// 특이사항 기록 Provider (인덱스 없이 클라이언트에서 정렬)
final specialNotesProvider = StreamProvider.family<List<SpecialNoteModel>, String>((ref, petId) {
  return _firebaseService.firestore
      .collection('special_notes')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map((doc) => SpecialNoteModel.fromFirestore(doc))
            .toList();
        records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
        return records.take(20).toList();
      });
});

/// ============================================================
/// 건강수첩 서비스 (CRUD)
/// ============================================================
class HealthService {
  final FirebaseService _firebase = FirebaseService();

  // ===== 체중 =====
  Future<void> addWeightRecord({
    required String petId,
    required double weight,
    required DateTime recordDate,
    String? notes,
  }) async {
    final docRef = _firebase.firestore.collection('weight_records').doc();
    await docRef.set({
      'petId': petId,
      'weight': weight,
      'recordDate': Timestamp.fromDate(recordDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteWeightRecord(String recordId) async {
    await _firebase.firestore.collection('weight_records').doc(recordId).delete();
  }

  // ===== 그루밍 =====
  Future<void> addGroomingRecord({
    required String petId,
    required String groomingType,
    required DateTime recordDate,
    String? location,
    int? cost,
    String? notes,
  }) async {
    final docRef = _firebase.firestore.collection('grooming_records').doc();
    await docRef.set({
      'petId': petId,
      'groomingType': groomingType,
      'recordDate': Timestamp.fromDate(recordDate),
      'location': location,
      'cost': cost,
      'notes': notes,
      'photoUrls': [],
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteGroomingRecord(String recordId) async {
    await _firebase.firestore.collection('grooming_records').doc(recordId).delete();
  }

  // ===== 예방접종 =====
  Future<void> addVaccinationRecord({
    required String petId,
    required String vaccineName,
    required DateTime vaccinationDate,
    DateTime? nextDueDate,
    String? hospitalName,
    String? vetName,
    String? notes,
    bool reminderEnabled = true,
  }) async {
    final docRef = _firebase.firestore.collection('vaccination_records').doc();
    await docRef.set({
      'petId': petId,
      'vaccineName': vaccineName,
      'vaccinationDate': Timestamp.fromDate(vaccinationDate),
      'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate) : null,
      'hospitalName': hospitalName,
      'vetName': vetName,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': 7,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteVaccinationRecord(String recordId) async {
    await _firebase.firestore.collection('vaccination_records').doc(recordId).delete();
  }

  // ===== 검진 =====
  Future<void> addCheckupRecord({
    required String petId,
    required DateTime checkupDate,
    DateTime? nextCheckupDate,
    String? hospitalName,
    String? vetName,
    String? diagnosis,
    String? notes,
    bool reminderEnabled = true,
  }) async {
    final docRef = _firebase.firestore.collection('checkup_records').doc();
    await docRef.set({
      'petId': petId,
      'checkupDate': Timestamp.fromDate(checkupDate),
      'nextCheckupDate': nextCheckupDate != null ? Timestamp.fromDate(nextCheckupDate) : null,
      'hospitalName': hospitalName,
      'vetName': vetName,
      'diagnosis': diagnosis,
      'notes': notes,
      'attachmentUrls': [],
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': 7,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteCheckupRecord(String recordId) async {
    await _firebase.firestore.collection('checkup_records').doc(recordId).delete();
  }

  // ===== 약 복용 =====
  Future<void> addMedicationRecord({
    required String petId,
    required String medicationName,
    String? dosage,
    String? interval,
    int? intervalValue,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    bool reminderEnabled = false,
    List<String> reminderTimes = const [],
  }) async {
    final docRef = _firebase.firestore.collection('medication_records').doc();
    await docRef.set({
      'petId': petId,
      'medicationName': medicationName,
      'dosage': dosage,
      'interval': interval ?? 'asNeeded',
      'intervalValue': intervalValue ?? 1,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderTimes': reminderTimes,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteMedicationRecord(String recordId) async {
    await _firebase.firestore.collection('medication_records').doc(recordId).delete();
  }

  // ===== 특이사항 =====
  Future<void> addSpecialNote({
    required String petId,
    required DateTime recordDate,
    required String title,
    required String content,
    String? category,
    String? severity,
  }) async {
    final docRef = _firebase.firestore.collection('special_notes').doc();
    await docRef.set({
      'petId': petId,
      'recordDate': Timestamp.fromDate(recordDate),
      'title': title,
      'content': content,
      'category': category,
      'severity': severity,
      'photoUrls': [],
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteSpecialNote(String recordId) async {
    await _firebase.firestore.collection('special_notes').doc(recordId).delete();
  }

  // ===== 산책 기록 =====
  /// 산책 시작 (진행 중인 기록 생성)
  Future<String> startWalkRecord({
    required String userId,
    required String petId,
    required List<String> petIds,
    required GeoPoint startLocation,
  }) async {
    final docRef = _firebase.firestore.collection('walk_records').doc();
    await docRef.set({
      'petId': petId,
      'petIds': petIds,
      'userId': userId,
      'startTime': Timestamp.fromDate(DateTime.now()),
      'endTime': null,
      'distance': 0,
      'calories': null,
      'routePoints': [startLocation],
      'footprints': [],
      'notes': null,
      'photoUrls': [],
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    return docRef.id;
  }

  /// 산책 경로 업데이트 (위치 추가)
  Future<void> updateWalkRoute({
    required String recordId,
    required GeoPoint newLocation,
    required double totalDistance,
  }) async {
    await _firebase.firestore.collection('walk_records').doc(recordId).update({
      'routePoints': FieldValue.arrayUnion([newLocation]),
      'distance': totalDistance,
    });
  }

  /// 발자국 추가
  Future<void> addFootprint({
    required String recordId,
    required GeoPoint location,
  }) async {
    await _firebase.firestore.collection('walk_records').doc(recordId).update({
      'footprints': FieldValue.arrayUnion([location]),
    });
  }

  /// 산책 종료
  Future<void> endWalkRecord({
    required String recordId,
    required double totalDistance,
    double? calories,
    String? notes,
  }) async {
    await _firebase.firestore.collection('walk_records').doc(recordId).update({
      'endTime': Timestamp.fromDate(DateTime.now()),
      'distance': totalDistance,
      'calories': calories,
      'notes': notes,
    });
  }

  /// 산책 기록 삭제
  Future<void> deleteWalkRecord(String recordId) async {
    await _firebase.firestore.collection('walk_records').doc(recordId).delete();
  }
}

/// 건강수첩 서비스 Provider
final healthServiceProvider = Provider<HealthService>((ref) => HealthService());
