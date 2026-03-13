import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/app_logger.dart';
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

  // ===== 카카오 로그인 =====
  
  /// 카카오 계정으로 로그인
  /// 
  /// 플로우:
  /// 1. 카카오 SDK로 로그인 (카카오톡 설치 시 앱, 미설치 시 웹)
  /// 2. 카카오 accessToken을 Cloud Functions에 전달
  /// 3. Cloud Functions에서 카카오 사용자 정보 조회 + Firebase Custom Token 생성
  /// 4. Custom Token으로 Firebase Auth 로그인
  Future<UserCredential?> signInWithKakao() async {
    try {
      // 1. 카카오 SDK 로그인
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 2. Cloud Functions 호출하여 Custom Token 발급
      final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
          .httpsCallable('createCustomTokenForKakao');
      final result = await callable.call({
        'accessToken': token.accessToken,
      });

      final customToken = result.data['customToken'] as String;

      // 3. Firebase Auth 로그인
      return await _firebase.auth.signInWithCustomToken(customToken);
    } catch (e) {
      AppLogger.error('AuthRepository', '카카오 로그인 실패', e);
      rethrow;
    }
  }

  // ===== 네이버 로그인 =====
  
  /// 네이버 계정으로 로그인
  /// 
  /// 플로우:
  /// 1. 네이버 SDK로 로그인
  /// 2. 네이버 accessToken을 Cloud Functions에 전달
  /// 3. Cloud Functions에서 네이버 사용자 정보 조회 + Firebase Custom Token 생성
  /// 4. Custom Token으로 Firebase Auth 로그인
  Future<UserCredential?> signInWithNaver() async {
    try {
      // 1. 네이버 SDK 로그인
      final result = await FlutterNaverLogin.logIn();
      
      if (result.status != NaverLoginStatus.loggedIn) {
        return null;
      }

      // 2. 액세스 토큰 가져오기
      final tokenResult = await FlutterNaverLogin.currentAccessToken;
      final accessToken = tokenResult.accessToken;

      // 3. Cloud Functions 호출하여 Custom Token 발급
      final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
          .httpsCallable('createCustomTokenForNaver');
      final cfResult = await callable.call({
        'accessToken': accessToken,
      });

      final customToken = cfResult.data['customToken'] as String;

      // 4. Firebase Auth 로그인
      return await _firebase.auth.signInWithCustomToken(customToken);
    } catch (e) {
      AppLogger.error('AuthRepository', '네이버 로그인 실패', e);
      rethrow;
    }
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

  /// 이메일 중복 검사
  /// Firestore users 컬렉션에서 이메일 존재 여부 확인
  /// (fetchSignInMethodsForEmail은 Email Enumeration Protection으로 인해 작동 안 함)
  /// [email] : 검사할 이메일
  /// 반환값: true = 이미 사용 중, false = 사용 가능
  Future<bool> checkEmailExists(String email) async {
    try {
      final normalizedEmail = email.trim();
      
      // Firestore는 대소문자를 구분하므로 원본과 소문자 모두 검색
      final querySnapshot = await _firebase.usersCollection
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return true;
      }
      
      // 소문자로도 검색 (기존 데이터 호환)
      if (normalizedEmail != normalizedEmail.toLowerCase()) {
        final lowerQuerySnapshot = await _firebase.usersCollection
            .where('email', isEqualTo: normalizedEmail.toLowerCase())
            .limit(1)
            .get();
        return lowerQuerySnapshot.docs.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      // 에러 발생 시 false 반환 (가입 시도 시 Firebase Auth에서 최종 검증)
      AppLogger.error('AuthRepository', 'checkEmailExists', e);
      return false;
    }
  }

  // ===== 로그아웃 =====
  
  /// 로그아웃
  Future<void> signOut() async {
    // 구글 로그아웃 시도 (실패해도 Firebase 로그아웃은 진행)
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    
    // 카카오 로그아웃 시도
    try {
      await kakao.UserApi.instance.logout();
    } catch (_) {}
    
    // 네이버 로그아웃 시도
    try {
      await FlutterNaverLogin.logOut();
    } catch (_) {}
    
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
    return UserModel.fromFirestore(doc.data()!, id: doc.id);
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

  // ===== 비밀번호 재설정 =====
  
  /// 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebase.auth.sendPasswordResetEmail(email: email);
  }

  // ===== 이메일 인증 =====
  
  /// 이메일 인증 메일 발송
  Future<void> sendEmailVerification() async {
    final user = _firebase.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');
    if (user.emailVerified) throw Exception('이미 인증된 이메일입니다');
    
    await user.sendEmailVerification();
  }

  /// 이메일 인증 여부 확인
  bool get isEmailVerified => _firebase.currentUser?.emailVerified ?? false;

  /// 이메일 인증 상태 새로고침 (인증 완료 여부 확인)
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _firebase.currentUser;
    if (user == null) return false;
    
    await user.reload();
    return _firebase.auth.currentUser?.emailVerified ?? false;
  }

  /// 이메일 로그인 사용자인지 확인
  bool get isEmailLoginUser {
    final user = _firebase.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  // ===== 회원 탈퇴 (논리 삭제) =====
  
  /// 회원 탈퇴 처리
  /// 물리 삭제가 아닌 논리 삭제를 수행합니다.
  /// - isDeleted: true로 설정
  /// - deletedAt: 현재 시간 저장
  /// - 30일 후 Cloud Functions에서 물리 삭제 처리
  Future<void> deleteAccount() async {
    final user = _firebase.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');
    
    // 1. Firestore에서 논리 삭제 처리
    await _firebase.usersCollection.doc(user.uid).update({
      'isDeleted': true,
      'deletedAt': DateTime.now(),
    });
    
    // 2. Firebase Auth 로그아웃 (계정은 유지)
    // 실제 계정 삭제는 30일 후 Cloud Functions에서 처리
    await signOut();
  }

  // ===== 상태 스트림 =====
  
  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _firebase.authStateChanges;

  /// 현재 사용자
  User? get currentUser => _firebase.currentUser;

  /// 현재 사용자 ID
  String? get currentUserId => _firebase.currentUserId;
}
