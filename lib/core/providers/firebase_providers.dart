import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});
