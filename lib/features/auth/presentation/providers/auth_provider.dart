import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/nickname_service.dart';
import '../../../../models/user_model.dart';
import '../../data/auth_repository.dart';
import '../screens/consent_screen.dart';

/// ============================================================
/// 인증 상태 관리 Provider
/// 앱 전체에서 사용되는 인증 상태를 관리
/// ============================================================

// ===== 레포지토리 Provider =====
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ===== 인증 상태 Provider =====
/// Firebase Auth 상태 변경을 감지하는 스트림 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// ===== 현재 사용자 Provider =====
/// 현재 로그인된 사용자 정보를 가져오는 StreamProvider
/// FutureProvider 대신 StreamProvider를 사용하여 깜빡임 방지
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  
  // Firebase Auth 상태 변경을 직접 구독하여 사용자 정보 스트림 생성
  return authRepo.authStateChanges.asyncMap((user) async {
    if (user == null) return null;
    return await authRepo.getUser(user.uid);
  });
});

// ===== 인증 상태 Notifier =====
/// 인증 관련 액션을 처리하는 StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(AuthState.initial());

  // ===== 전화번호 인증 =====
  
  /// 전화번호로 인증 코드 전송
  Future<void> sendPhoneCode(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 한국 전화번호 형식으로 변환 (+82)
      String formattedNumber = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedNumber = '+82${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('+')) {
        formattedNumber = '+82$phoneNumber';
      }

      await _authRepository.sendPhoneVerificationCode(
        phoneNumber: formattedNumber,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            isLoading: false,
            verificationId: verificationId,
            resendToken: resendToken,
            phoneNumber: formattedNumber,
          );
        },
        onVerificationFailed: (e) {
          state = state.copyWith(
            isLoading: false,
            error: _getErrorMessage(e),
          );
        },
        onAutoVerified: (credential) async {
          // Android에서 자동 인증 완료
          await _signInWithCredential(credential);
        },
        resendToken: state.resendToken,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '인증 코드 전송에 실패했습니다.',
      );
    }
  }

  /// 인증 코드로 로그인
  Future<bool> verifyPhoneCode(String code) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: '인증 세션이 만료되었습니다. 다시 시도해주세요.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.signInWithPhoneCode(
        verificationId: state.verificationId!,
        smsCode: code,
      );

      await _handleSignIn(userCredential, 'phone');
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '인증에 실패했습니다.',
      );
      return false;
    }
  }

  /// Firebase 자격 증명으로 로그인
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    state = state.copyWith(isLoading: true);
    try {
      final userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _handleSignIn(userCredential, 'phone');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '자동 인증에 실패했습니다.',
      );
    }
  }

  // ===== 구글 로그인 =====
  
  Future<bool> signInWithGoogle({ConsentData? consentData}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.signInWithGoogle();
      
      if (userCredential == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      await _handleSignIn(userCredential, 'google', consentData: consentData);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '구글 로그인에 실패했습니다.',
      );
      return false;
    }
  }

  // ===== 이메일/비밀번호 로그인 =====
  
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      
      await _handleSignIn(userCredential, 'email');
      
      // 이메일 미인증 사용자인 경우 인증 메일 재발송
      if (!_authRepository.isEmailVerified) {
        try {
          await _authRepository.sendEmailVerification();
        } catch (_) {
          // 인증 메일 발송 실패해도 로그인은 성공 처리
        }
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getEmailErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그인에 실패했습니다.',
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {ConsentData? consentData}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
      );
      
      // 회원가입 성공 시 이메일 인증 메일 자동 발송
      try {
        await _authRepository.sendEmailVerification();
      } catch (_) {
        // 인증 메일 발송 실패해도 회원가입은 성공 처리
      }
      
      await _handleSignIn(userCredential, 'email', consentData: consentData);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getEmailErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '회원가입에 실패했습니다.',
      );
      return false;
    }
  }

  // ===== 카카오 로그인 (추후 구현) =====
  
  Future<bool> signInWithKakao({ConsentData? consentData}) async {
    state = state.copyWith(
      error: '카카오 로그인은 준비 중입니다.',
    );
    return false;
  }

  // ===== 네이버 로그인 (추후 구현) =====
  
  Future<bool> signInWithNaver({ConsentData? consentData}) async {
    state = state.copyWith(
      error: '네이버 로그인은 준비 중입니다.',
    );
    return false;
  }

  // ===== 로그인 처리 공통 로직 =====
  
  Future<void> _handleSignIn(
    UserCredential userCredential,
    String provider, {
    ConsentData? consentData,
  }) async {
    final user = userCredential.user;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        error: '로그인에 실패했습니다.',
      );
      return;
    }

    // 기존 사용자인지 확인
    final exists = await _authRepository.checkUserExists(user.uid);
    
    if (!exists) {
      // 신규 사용자 - 고유 닉네임 자동 생성
      final uniqueNickname = await NicknameService.generateUnique();
      
      final newUser = UserModel.empty(user.uid, provider).copyWith(
        email: user.email,
        phoneNumber: user.phoneNumber,
        profileImageUrl: user.photoURL,
        nickname: uniqueNickname,
        // 동의 정보 저장
        termsAgreedAt: consentData?.agreedAt,
        privacyAgreedAt: consentData?.agreedAt,
        locationConsentAt: consentData?.locationAgreed == true ? consentData?.agreedAt : null,
        marketingConsentAt: consentData?.marketingAgreed == true ? consentData?.agreedAt : null,
      );
      await _authRepository.createUser(newUser);
      
      // nicknames 컬렉션에 등록
      await NicknameService.register(user.uid, uniqueNickname);
      state = state.copyWith(
        isLoading: false,
        isNewUser: true,
      );
    } else {
      // 기존 사용자 - 마지막 활동 시간 업데이트
      await _authRepository.updateLastActive(user.uid);
      state = state.copyWith(
        isLoading: false,
        isNewUser: false,
      );
    }

    // 상태 관리 새로고침
    _ref.invalidate(currentUserProvider);
  }

  // ===== 로그아웃 =====
  
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.signOut();
      // Firebase signOut이 완료되면 authStateChanges 스트림이 자동으로 null을 emit
      // 따라서 별도의 invalidate 불필요 (중복 처리 및 깜빡임 방지)
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그아웃에 실패했습니다.',
      );
    }
  }

  // ===== 비밀번호 재설정 이메일 =====
  
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '비밀번호 재설정 이메일 발송에 실패했습니다.',
      );
      rethrow;
    }
  }

  // ===== 이메일 인증 =====
  
  /// 이메일 인증 메일 발송
  Future<void> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.sendEmailVerification();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// 이메일 인증 여부 확인
  bool get isEmailVerified => _authRepository.isEmailVerified;

  /// 이메일 로그인 사용자인지 확인
  bool get isEmailLoginUser => _authRepository.isEmailLoginUser;

  /// 이메일 인증 상태 새로고침 (인증 완료 여부 확인)
  Future<bool> checkEmailVerified() async {
    state = state.copyWith(isLoading: true);
    try {
      final verified = await _authRepository.reloadAndCheckEmailVerified();
      state = state.copyWith(isLoading: false, isEmailVerified: verified);
      if (verified) {
        _ref.invalidate(currentUserProvider);
      }
      return verified;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // ===== 회원 탈퇴 (논리 삭제) =====
  /// 회원 탈퇴 시 물리 삭제가 아닌 논리 삭제를 수행합니다.
  /// - isDeleted: true로 설정
  /// - deletedAt: 현재 시간 저장
  /// - 30일 후 배치 작업으로 물리 삭제 (Cloud Functions에서 처리)
  /// 
  /// 논리 삭제 이유:
  /// 1. 사용자 실수로 인한 탈퇴 복구 가능 (30일 이내)
  /// 2. 법적 데이터 보관 의무 준수 (거래 기록 등)
  /// 3. 악용 방지 (탈퇴 후 즉시 재가입하여 평판 초기화 방지)
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.deleteAccount();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '회원 탈퇴에 실패했습니다.',
      );
      rethrow;
    }
  }

  // ===== 에러 메시지 처리 =====
  
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return '올바른 전화번호를 입력해주세요.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'invalid-verification-code':
        return '인증 코드가 올바르지 않습니다.';
      case 'session-expired':
        return '인증 세션이 만료되었습니다. 다시 시도해주세요.';
      default:
        return e.message ?? '인증에 실패했습니다.';
    }
  }

  String _getEmailErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 6자 이상 입력해주세요.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다. 관리자에게 문의해주세요.';
      case 'operation-not-allowed':
        return '이 로그인 방식은 현재 사용할 수 없습니다.';
      default:
        return '로그인에 실패했습니다. 다시 시도해주세요.';
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ===== 인증 상태 클래스 =====
class AuthState {
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final int? resendToken;
  final String? phoneNumber;
  final bool isNewUser;
  final bool isEmailVerified;

  AuthState({
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.resendToken,
    this.phoneNumber,
    this.isNewUser = false,
    this.isEmailVerified = false,
  });

  factory AuthState.initial() => AuthState();

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? verificationId,
    int? resendToken,
    String? phoneNumber,
    bool? isNewUser,
    bool? isEmailVerified,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isNewUser: isNewUser ?? this.isNewUser,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

// ===== Auth Notifier Provider =====
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository, ref);
});
