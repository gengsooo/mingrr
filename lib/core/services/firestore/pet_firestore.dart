import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/pet_model.dart';
import '../../utils/app_logger.dart';
import 'firestore_base.dart';

/// 반려동물(Pet) 도메인 Firestore CRUD mixin
mixin PetFirestore on FirestoreBase {

  Future<void> createPet(PetModel pet) async {
    try {
      await firebase.petsCollection.doc(pet.id).set(pet.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createPet (petId: ${pet.id})', e);
      rethrow;
    }
  }
  
  Future<PetModel?> getPet(String petId) async {
    try {
      final doc = await firebase.petsCollection.doc(petId).get();
      if (!doc.exists) return null;
      return PetModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getPet (petId: $petId)', e);
      rethrow;
    }
  }
  
  Future<void> updatePet(PetModel pet) async {
    try {
      await firebase.petsCollection.doc(pet.id).update(pet.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updatePet (petId: ${pet.id})', e);
      rethrow;
    }
  }
  
  Future<void> deletePet(String petId) async {
    try {
      await firebase.petsCollection.doc(petId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deletePet (petId: $petId)', e);
      rethrow;
    }
  }
  
  Future<List<PetModel>> getUserPets(String userId) async {
    try {
      final snapshot = await firebase.petsCollection
          .where('ownerId', isEqualTo: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserPets (userId: $userId)', e);
      rethrow;
    }
  }
  
  Stream<List<PetModel>> watchUserPets(String userId) {
    return firebase.petsCollection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromFirestore(doc))
            .toList());
  }

  /// 반려동물에 동물등록 인증 정보 연결
  Future<void> linkPetRegistration(
    String petId,
    String registrationNumber,
    Map<String, dynamic> animalData,
  ) async {
    try {
      await firebase.petsCollection.doc(petId).update({
        'registrationNumber': registrationNumber,
        'isRegistrationVerified': true,
        'registrationVerifiedAt': FieldValue.serverTimestamp(),
        'registrationData': animalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// 동물등록번호로 반려동물 찾기
  Future<PetModel?> findPetByRegistrationNumber(String userId, String registrationNumber) async {
    try {
      final snapshot = await firebase.petsCollection
          .where('ownerId', isEqualTo: userId)
          .where('registrationNumber', isEqualTo: registrationNumber)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return PetModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      rethrow;
    }
  }

  /// 반려동물 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<PetModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getPetsPaginated({
    bool? isBreedingAvailable,
    String? species,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.petsCollection;
      
      if (isBreedingAvailable != null) {
        query = query.where('isBreedingAvailable', isEqualTo: isBreedingAvailable);
      }
      if (species != null) {
        query = query.where('species', isEqualTo: species);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => PetModel.fromFirestore(doc)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GeoHash 기반 반려동물 검색 (반경 내 - 주인 위치 기준)
  Future<List<PetModel>> getPetsByOwnerGeohash({
    required String centerGeohash,
    required double radiusKm,
    bool? isBreedingAvailable,
  }) async {
    try {
      final precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4);
      final prefix = centerGeohash.substring(0, precision.clamp(1, centerGeohash.length));
      
      // 먼저 해당 범위 내 사용자 조회
      final usersSnapshot = await firebase.usersCollection
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~')
          .get();
      
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
      if (userIds.isEmpty) return [];
      
      // 해당 사용자들의 반려동물 조회
      Query<Map<String, dynamic>> query = firebase.petsCollection
          .where('ownerId', whereIn: userIds.take(10).toList()); // Firestore whereIn 제한
      
      if (isBreedingAvailable != null) {
        query = query.where('isBreedingAvailable', isEqualTo: isBreedingAvailable);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
