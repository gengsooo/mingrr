import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_service.dart';

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
      rethrow;
    }
  }
  
  Future<List<String>> uploadDogImages(String dogId, List<File> imageFiles) async {
    try {
      final urls = <String>[];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = 'photo_$i.jpg';
        final url = await uploadDogImage(dogId, fileName, imageFiles[i]);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
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
      rethrow;
    }
  }
  
  Future<List<String>> uploadProductImages(String productId, List<File> imageFiles) async {
    try {
      final urls = <String>[];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = 'image_$i.jpg';
        final url = await uploadProductImage(productId, fileName, imageFiles[i]);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
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
      rethrow;
    }
  }
  
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteFiles(List<String> downloadUrls) async {
    try {
      for (final url in downloadUrls) {
        await deleteFile(url);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteUserProfileImage(String userId) async {
    try {
      final ref = _firebase.userProfileImageRef(userId);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deletePetImages(String petId) async {
    try {
      final ref = _storage.ref().child('pets/$petId');
      final listResult = await ref.listAll();
      
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteProductImages(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final listResult = await ref.listAll();
      
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}
