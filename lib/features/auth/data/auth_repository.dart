import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/user_model.dart';

/// ============================================================
/// 인증 레포지토리
/// 모든 인증 관련 로직을 처리하는 레포지토리
/// 전화번호, 카카오, 네이버, 구글 로그인 지원
/// ============================================================
class AuthRepository {
  final FirebaseService _firebase = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ===== 전화번호 인증 =====
  
  /// 전화번호로 인증 코드 전송
  /// [phoneNumber] : 전화번호 (예: +821012345678)
  /// [onCodeSent] : 인증 코드 전송 완료 시 콜백
  /// [onVerificationFailed] : 인증 실패 시 콜백
  /// [onAutoVerified] : 자동 인증 완료 시 콜백 (Android)
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    int? resendToken,
  }) async {
    await _firebase.auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: onAutoVerified,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        // 자동 인증 시간 초과 - 수동 입력 필요
      },
    );
  }

  /// 인증 코드로 로그인
  /// [verificationId] : 인증 ID
  /// [smsCode] : 사용자가 입력한 인증 코드
  Future<UserCredential> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebase.auth.signInWithCredential(credential);
  }

  // ===== 구글 로그인 =====
  
  /// 구글 계정으로 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 구글 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      return await _firebase.auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // ===== 카카오 로그인 (추후 구현) =====
  
  /// 카카오 계정으로 로그인
  /// 네이티브 SDK 설정 후 활성화 필요
  Future<UserCredential?> signInWithKakao() async {
    // TODO: 카카오 SDK 설정 후 구현
    // 1. kakao_flutter_sdk 패키지 활성화
    // 2. 카카오 개발자 콘솔에서 앱 등록
    // 3. 네이티브 키 설정
    throw UnimplementedError('카카오 로그인은 네이티브 설정 후 사용 가능합니다.');
  }

  // ===== 네이버 로그인 (추후 구현) =====
  
  /// 네이버 계정으로 로그인
  /// 네이티브 SDK 설정 후 활성화 필요
  Future<UserCredential?> signInWithNaver() async {
    // TODO: 네이버 SDK 설정 후 구현
    // 1. flutter_naver_login 패키지 활성화
    // 2. 네이버 개발자 센터에서 앱 등록
    // 3. 네이티브 키 설정
    throw UnimplementedError('네이버 로그인은 네이티브 설정 후 사용 가능합니다.');
  }

  // ===== 이메일/비밀번호 로그인 =====
  
  /// 이메일로 로그인
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebase.auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 이메일로 회원가입
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebase.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ===== 로그아웃 =====
  
  /// 로그아웃
  Future<void> signOut() async {
    // 구글 로그아웃 시도 (실패해도 Firebase 로그아웃은 진행)
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Google Sign-In이 설정되지 않은 경우 무시
    }
    
    // Firebase 로그아웃
    await _firebase.auth.signOut();
  }

  // ===== 사용자 데이터 관리 =====
  
  /// 사용자 문서 존재 여부 확인
  Future<bool> checkUserExists(String userId) async {
    final doc = await _firebase.usersCollection.doc(userId).get();
    return doc.exists;
  }

  /// 새 사용자 생성
  Future<void> createUser(UserModel user) async {
    await _firebase.usersCollection.doc(user.id).set(user.toFirestore());
  }

  /// 사용자 정보 가져오기
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firebase.usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// 사용자 정보 업데이트
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firebase.usersCollection.doc(userId).update(data);
  }

  /// 마지막 활동 시간 업데이트
  Future<void> updateLastActive(String userId) async {
    await _firebase.usersCollection.doc(userId).update({
      'lastActiveAt': DateTime.now(),
    });
  }

  /// FCM 토큰 업데이트
  Future<void> updateFcmToken(String userId, String token) async {
    await _firebase.usersCollection.doc(userId).update({
      'fcmToken': token,
    });
  }

  // ===== 상태 스트림 =====
  
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _firebase.authStateChanges;

  /// 현재 사용자
  User? get currentUser => _firebase.currentUser;

  /// 현재 사용자 ID
  String? get currentUserId => _firebase.currentUserId;
}
