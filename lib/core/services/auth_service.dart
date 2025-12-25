import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseAuth get _auth => _firebase.auth;
  
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        throw Exception('Google 로그인이 취소되었습니다.');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e) {
      rethrow;
    }
  }
}
