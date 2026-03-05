import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_base.dart';

/// 인증(Verification) 도메인 Firestore mixin
mixin VerificationFirestore on FirestoreBase {

  /// 사용자 인증 상태 조회
  Future<Map<String, bool>> getUserVerifications(String userId) async {
    try {
      final doc = await firebase.usersCollection.doc(userId).get();
      if (!doc.exists) {
        return {
          'identity': false,
          'location': false,
          'petRegistration': false,
        };
      }
      
      final data = doc.data()!;
      final verifications = data['verifications'] as Map<String, dynamic>?;
      
      return {
        'identity': verifications?['identity'] ?? false,
        'location': verifications?['location'] ?? false,
        'petRegistration': verifications?['petRegistration'] ?? false,
      };
    } catch (e) {
      return {
        'identity': false,
        'location': false,
        'petRegistration': false,
      };
    }
  }

  /// 인증 상태 업데이트
  Future<void> updateUserVerification(String userId, String verificationType, bool isVerified) async {
    try {
      await firebase.usersCollection.doc(userId).update({
        'verifications.$verificationType': isVerified,
        'verifications.${verificationType}At': isVerified ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 본인 인증 처리
  Future<void> verifyIdentity(String userId) async {
    await updateUserVerification(userId, 'identity', true);
  }

  /// 동물등록 인증 처리 (API 검증 결과 저장)
  /// 
  /// [userId]: 사용자 ID
  /// [registrationNumber]: 동물등록번호
  /// [animalData]: API에서 받은 동물 정보 (선택)
  /// [matchedPetId]: 매칭된 반려동물 ID (선택)
  Future<void> verifyPetRegistration(
    String userId, 
    String registrationNumber, {
    Map<String, dynamic>? animalData,
    String? matchedPetId,
  }) async {
    try {
      final updateData = {
        'verifications.petRegistration': true,
        'verifications.petRegistrationAt': FieldValue.serverTimestamp(),
        'verifications.petRegistrationNumber': registrationNumber,
      };
      
      // API 응답 데이터 저장
      if (animalData != null) {
        updateData['verifications.petRegistrationData'] = animalData;
      }
      
      // 매칭된 반려동물 ID 저장
      if (matchedPetId != null) {
        updateData['verifications.petRegistrationMatchedPetId'] = matchedPetId;
      }
      
      await firebase.usersCollection.doc(userId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  /// 인증 상태 스트림
  Stream<Map<String, bool>> watchUserVerifications(String userId) {
    return firebase.usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'identity': false,
          'location': false,
          'petRegistration': false,
        };
      }
      
      final data = doc.data()!;
      final verifications = data['verifications'] as Map<String, dynamic>?;
      
      return {
        'identity': verifications?['identity'] ?? false,
        'location': verifications?['location'] ?? false,
        'petRegistration': verifications?['petRegistration'] ?? false,
      };
    });
  }
}
