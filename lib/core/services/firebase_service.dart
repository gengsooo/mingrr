import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// ============================================================
/// Firebase 서비스
/// Firebase 인스턴스들을 중앙에서 관리하는 싱글톤 서비스
/// ============================================================
class FirebaseService {
  // 싱글톤 패턴
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ===== Firebase 인스턴스들 =====
  
  /// Firebase Auth 인스턴스
  FirebaseAuth get auth => FirebaseAuth.instance;
  
  /// Firestore 인스턴스
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  /// Firebase Storage 인스턴스
  FirebaseStorage get storage => FirebaseStorage.instance;

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
  
  /// 좋아요(데이팅 신청) 컬렉션
  CollectionReference<Map<String, dynamic>> get likesCollection =>
      firestore.collection('likes');
  
  /// 매칭 컬렉션
  CollectionReference<Map<String, dynamic>> get matchesCollection =>
      firestore.collection('matches');
  
  /// 상품 컬렉션
  CollectionReference<Map<String, dynamic>> get productsCollection =>
      firestore.collection('products');
  
  /// 예방접종 기록 컬렉션
  CollectionReference<Map<String, dynamic>> get vaccinationsCollection =>
      firestore.collection('vaccinations');
  
  /// 체중 기록 컬렉션
  CollectionReference<Map<String, dynamic>> get weightRecordsCollection =>
      firestore.collection('weightRecords');
  
  /// 배변 기록 컬렉션
  CollectionReference<Map<String, dynamic>> get poopRecordsCollection =>
      firestore.collection('poopRecords');
  
  /// 산책 기록 컬렉션
  CollectionReference<Map<String, dynamic>> get walkRecordsCollection =>
      firestore.collection('walkRecords');
  
  /// 모임 컬렉션
  CollectionReference<Map<String, dynamic>> get groupsCollection =>
      firestore.collection('groups');
  
  /// 일정 컬렉션
  CollectionReference<Map<String, dynamic>> get schedulesCollection =>
      firestore.collection('schedules');

  // ===== 메시지 서브컬렉션 접근 =====
  
  /// 특정 채팅방의 메시지 컬렉션
  CollectionReference<Map<String, dynamic>> messagesCollection(String chatRoomId) =>
      chatRoomsCollection.doc(chatRoomId).collection('messages');

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
}
