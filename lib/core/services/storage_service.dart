import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_service.dart';
import '../utils/app_logger.dart';

class StorageService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseStorage get _storage => _firebase.storage;
  
  Future<String> uploadUserProfileImage(String userId, File imageFile) async {
    try {
      final ref = _firebase.userProfileImageRef(userId);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '프로필 이미지 업로드 실패 (userId: $userId)', e);
      rethrow;
    }
  }
  
  Future<String> uploadDogImage(String dogId, String fileName, File imageFile) async {
    try {
      final ref = _firebase.petImageRef(dogId, fileName);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '반려동물 이미지 업로드 실패 (petId: $dogId, fileName: $fileName)', e);
      rethrow;
    }
  }
  
  /// 반려동물 이미지 병렬 업로드
  /// 여러 이미지를 동시에 업로드하여 성능 향상
  Future<List<String>> uploadDogImages(String dogId, List<File> imageFiles) async {
    try {
      if (imageFiles.isEmpty) return [];
      
      // 병렬 업로드 실행
      final uploadFutures = imageFiles.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        final fileName = 'photo_$index.jpg';
        return uploadDogImage(dogId, fileName, file);
      }).toList();
      
      final urls = await Future.wait(uploadFutures);
      AppLogger.info('StorageService', '반려동물 이미지 ${urls.length}개 병렬 업로드 완료 (petId: $dogId)');
      return urls;
    } catch (e) {
      AppLogger.error('StorageService', '반려동물 이미지 병렬 업로드 실패 (petId: $dogId)', e);
      rethrow;
    }
  }
  
  /// 웹용 - bytes로 강아지 이미지 업로드
  Future<String> uploadDogImageBytes(String dogId, String fileName, Uint8List bytes) async {
    try {
      final ref = _firebase.petImageRef(dogId, fileName);
      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '반려동물 이미지(bytes) 업로드 실패 (petId: $dogId)', e);
      rethrow;
    }
  }
  
  /// 웹용 - bytes로 사용자 프로필 이미지 업로드
  Future<String> uploadUserProfileImageBytes(String userId, Uint8List bytes) async {
    try {
      final ref = _firebase.userProfileImageRef(userId);
      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '프로필 이미지(bytes) 업로드 실패 (userId: $userId)', e);
      rethrow;
    }
  }
  
  Future<String> uploadProductImage(String productId, String fileName, File imageFile) async {
    try {
      final ref = _firebase.productImageRef(productId, fileName);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '상품 이미지 업로드 실패 (productId: $productId)', e);
      rethrow;
    }
  }
  
  /// 상품 이미지 병렬 업로드
  /// 여러 이미지를 동시에 업로드하여 성능 향상
  Future<List<String>> uploadProductImages(String productId, List<File> imageFiles) async {
    try {
      if (imageFiles.isEmpty) return [];
      
      // 병렬 업로드 실행
      final uploadFutures = imageFiles.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        final fileName = 'image_$index.jpg';
        return uploadProductImage(productId, fileName, file);
      }).toList();
      
      final urls = await Future.wait(uploadFutures);
      AppLogger.info('StorageService', '상품 이미지 ${urls.length}개 병렬 업로드 완료 (productId: $productId)');
      return urls;
    } catch (e) {
      AppLogger.error('StorageService', '상품 이미지 병렬 업로드 실패 (productId: $productId)', e);
      rethrow;
    }
  }
  
  Future<String> uploadChatImage(String chatRoomId, String fileName, File imageFile) async {
    try {
      final ref = _firebase.chatImageRef(chatRoomId, fileName);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '채팅 이미지 업로드 실패 (chatRoomId: $chatRoomId)', e);
      rethrow;
    }
  }
  
  Future<String> uploadGroupImage(String groupId, File imageFile) async {
    try {
      final ref = _firebase.groupImageRef(groupId);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService', '소모임 이미지 업로드 실패 (groupId: $groupId)', e);
      rethrow;
    }
  }
  
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      AppLogger.error('StorageService', '파일 삭제 실패 (url: $downloadUrl)', e);
      rethrow;
    }
  }
  
  /// 여러 파일 병렬 삭제
  Future<void> deleteFiles(List<String> downloadUrls) async {
    try {
      if (downloadUrls.isEmpty) return;
      
      // 병렬 삭제 실행
      await Future.wait(
        downloadUrls.map((url) => deleteFile(url)),
      );
      AppLogger.info('StorageService', '파일 ${downloadUrls.length}개 병렬 삭제 완료');
    } catch (e) {
      AppLogger.error('StorageService', '파일 병렬 삭제 실패', e);
      rethrow;
    }
  }
  
  Future<void> deleteUserProfileImage(String userId) async {
    try {
      final ref = _firebase.userProfileImageRef(userId);
      await ref.delete();
    } catch (e) {
      AppLogger.error('StorageService', '프로필 이미지 삭제 실패 (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 반려동물 이미지 전체 병렬 삭제
  Future<void> deletePetImages(String petId) async {
    try {
      final ref = _storage.ref().child('pets/$petId');
      final listResult = await ref.listAll();
      
      if (listResult.items.isEmpty) return;
      
      // 병렬 삭제 실행
      await Future.wait(
        listResult.items.map((item) => item.delete()),
      );
      AppLogger.info('StorageService', '반려동물 이미지 ${listResult.items.length}개 삭제 완료 (petId: $petId)');
    } catch (e) {
      AppLogger.error('StorageService', '반려동물 이미지 삭제 실패 (petId: $petId)', e);
      rethrow;
    }
  }
  
  /// 상품 이미지 전체 병렬 삭제
  Future<void> deleteProductImages(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final listResult = await ref.listAll();
      
      if (listResult.items.isEmpty) return;
      
      // 병렬 삭제 실행
      await Future.wait(
        listResult.items.map((item) => item.delete()),
      );
      AppLogger.info('StorageService', '상품 이미지 ${listResult.items.length}개 삭제 완료 (productId: $productId)');
    } catch (e) {
      AppLogger.error('StorageService', '상품 이미지 삭제 실패 (productId: $productId)', e);
      rethrow;
    }
  }
}
