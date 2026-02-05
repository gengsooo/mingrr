import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// Firebase 서비스
/// Firebase 인스턴스들을 중앙에서 관리하는 싱글톤 서비스
/// 
/// Firestore 설정:
/// - 오프라인 지속성 활성화 (모바일)
/// - 캐시 크기 제한 (100MB)
/// - 네트워크 타임아웃 설정
/// ============================================================
class FirebaseService {
  // 싱글톤 패턴
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  // 초기화 상태
  static bool _isInitialized = false;

  // ===== Firebase 인스턴스들 =====
  
  /// Firebase Auth 인스턴스
  FirebaseAuth get auth => FirebaseAuth.instance;
  
  /// Firestore 인스턴스
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  /// Firebase Storage 인스턴스
  FirebaseStorage get storage => FirebaseStorage.instance;
  
  // ===== Firestore 초기화 =====
  
  /// Firestore 설정 초기화
  /// main.dart에서 Firebase.initializeApp() 후 호출
  static Future<void> initializeFirestore() async {
    if (_isInitialized) return;
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Firestore 설정
      firestore.settings = Settings(
        // 오프라인 지속성 (모바일에서만, 웹은 기본 비활성화)
        persistenceEnabled: !kIsWeb,
        // 캐시 크기 제한 (100MB, 기본값은 무제한)
        cacheSizeBytes: 100 * 1024 * 1024,
      );
      
      _isInitialized = true;
      AppLogger.info('FirebaseService', 'Firestore 설정 완료 (persistenceEnabled: ${!kIsWeb})');
    } catch (e) {
      AppLogger.error('FirebaseService', 'Firestore 설정 실패', e);
    }
  }

  // ===== Firestore 컬렉션 참조 =====
  
  /// 사용자 컬렉션
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');
  
  /// 반려동물 컬렉션
  CollectionReference<Map<String, dynamic>> get petsCollection =>
      firestore.collection('pets');
  
  /// 채팅방 컬렉션
  CollectionReference<Map<String, dynamic>> get chatRoomsCollection =>
      firestore.collection('chatRooms');
  
  /// 데이팅 신청 컬렉션
  CollectionReference<Map<String, dynamic>> get datingRequestsCollection =>
      firestore.collection('dating_requests');
  
  /// 매칭 컬렉션
  CollectionReference<Map<String, dynamic>> get matchesCollection =>
      firestore.collection('matches');
  
  /// 상품 컬렉션
  CollectionReference<Map<String, dynamic>> get productsCollection =>
      firestore.collection('products');
  
  /// 상품 찜 컬렉션
  CollectionReference<Map<String, dynamic>> get productLikesCollection =>
      firestore.collection('productLikes');
  
  /// 가입 신청 컬렉션
  CollectionReference<Map<String, dynamic>> get joinRequestsCollection =>
      firestore.collection('joinRequests');
  
  /// 모임 컬렉션
  CollectionReference<Map<String, dynamic>> get groupsCollection =>
      firestore.collection('groups');
  
  /// 일정 컬렉션
  CollectionReference<Map<String, dynamic>> get schedulesCollection =>
      firestore.collection('schedules');
  
  /// 알바 컬렉션
  CollectionReference<Map<String, dynamic>> get jobsCollection =>
      firestore.collection('jobs');
  
  /// 교배 글 컬렉션
  CollectionReference<Map<String, dynamic>> get breedingPostsCollection =>
      firestore.collection('breedingPosts');
  
  /// 산책 기록 컬렉션
  CollectionReference<Map<String, dynamic>> get walksCollection =>
      firestore.collection('walks');
  
  /// 소모임 좋아요 컬렉션
  CollectionReference<Map<String, dynamic>> get groupLikesCollection =>
      firestore.collection('groupLikes');
  
  /// 소모임 가입 신청 컬렉션
  CollectionReference<Map<String, dynamic>> get groupJoinRequestsCollection =>
      firestore.collection('groupJoinRequests');
  
  /// 신고 컬렉션
  CollectionReference<Map<String, dynamic>> get reportsCollection =>
      firestore.collection('reports');
  
  /// 차단 컬렉션
  CollectionReference<Map<String, dynamic>> get blocksCollection =>
      firestore.collection('blocks');
  
  /// 평가(꼬순내지수) 컬렉션
  CollectionReference<Map<String, dynamic>> get ratingsCollection =>
      firestore.collection('ratings');
  
  /// 커뮤니티 게시판 게시글 컨렉션 (Firestore: feedPosts)
  CollectionReference<Map<String, dynamic>> get feedPostsCollection =>
      firestore.collection('feedPosts');
  
  /// 커뮤니티 게시판 댓글 컨렉션 (Firestore: feedComments)
  CollectionReference<Map<String, dynamic>> get feedCommentsCollection =>
      firestore.collection('feedComments');
  
  /// 커뮤니티 게시판 좋아요 컨렉션 (Firestore: feedLikes)
  CollectionReference<Map<String, dynamic>> get feedLikesCollection =>
      firestore.collection('feedLikes');

  // ===== 메시지 서브컬렉션 접근 =====
  
  /// 특정 채팅방의 메시지 컬렉션
  CollectionReference<Map<String, dynamic>> messagesCollection(String chatRoomId) =>
      chatRoomsCollection.doc(chatRoomId).collection('messages');
  
  /// 특정 반려동물의 건강 기록 컬렉션
  CollectionReference<Map<String, dynamic>> healthRecordsCollection(String petId) =>
      petsCollection.doc(petId).collection('healthRecords');

  // ===== Storage 참조 =====
  
  /// 사용자 프로필 이미지 저장 경로
  Reference userProfileImageRef(String userId) =>
      storage.ref().child('users/$userId/profile');
  
  /// 반려동물 이미지 저장 경로
  Reference petImageRef(String petId, String fileName) =>
      storage.ref().child('pets/$petId/$fileName');
  
  /// 상품 이미지 저장 경로
  Reference productImageRef(String productId, String fileName) =>
      storage.ref().child('products/$productId/$fileName');
  
  /// 채팅 이미지 저장 경로
  Reference chatImageRef(String chatRoomId, String fileName) =>
      storage.ref().child('chats/$chatRoomId/$fileName');
  
  /// 모임 이미지 저장 경로
  Reference groupImageRef(String groupId) =>
      storage.ref().child('groups/$groupId/cover');

  // ===== 현재 사용자 =====
  
  /// 현재 로그인된 사용자
  User? get currentUser => auth.currentUser;
  
  /// 현재 사용자 ID
  String? get currentUserId => auth.currentUser?.uid;
  
  /// 로그인 상태 스트림
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // ===== 이미지 업로드 =====
  
  /// 이미지 파일 업로드 및 URL 반환
  Future<String> uploadImage(dynamic file, String path) async {
    try {
      final ref = storage.ref().child(path);
      
      // File 타입인 경우
      if (file is File) {
        final snapshot = await ref.putFile(file);
        return await snapshot.ref.getDownloadURL();
      }
      
      throw Exception('Invalid file type: ${file.runtimeType}');
    } catch (e) {
      AppLogger.error('FirebaseService', '이미지 업로드 오류', e);
      rethrow;
    }
  }

  // ===== 비디오 업로드 =====
  
  /// 비디오 파일 업로드 및 URL 반환
  Future<String> uploadVideo(File file, String path) async {
    try {
      final ref = storage.ref().child(path);
      final metadata = SettableMetadata(contentType: 'video/mp4');
      final snapshot = await ref.putFile(file, metadata);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('FirebaseService', '비디오 업로드 오류', e);
      rethrow;
    }
  }

  /// 비디오와 썸네일을 함께 업로드하고 URL 반환
  /// Returns: {'videoUrl': String, 'thumbnailUrl': String?}
  Future<Map<String, String?>> uploadVideoWithThumbnail(
    File videoFile,
    String videoPath, {
    File? thumbnailFile,
    String? thumbnailPath,
  }) async {
    try {
      // 비디오 업로드
      final videoUrl = await uploadVideo(videoFile, videoPath);
      
      // 썸네일 업로드 (제공된 경우)
      String? thumbnailUrl;
      if (thumbnailFile != null && thumbnailPath != null) {
        thumbnailUrl = await uploadImage(thumbnailFile, thumbnailPath);
      }
      
      return {
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
      };
    } catch (e) {
      AppLogger.error('FirebaseService', '비디오/썸네일 업로드 오류', e);
      rethrow;
    }
  }
}
