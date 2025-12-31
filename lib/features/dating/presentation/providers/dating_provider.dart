import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/dating_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// ============================================================
/// 데이팅 관련 Provider
/// Firebase Firestore와 연동하여 데이팅 데이터 관리
/// ============================================================

final _firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// 모든 반려동물 목록 (데이팅용 - 내 반려동물 제외)
final datingPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  final petRepository = ref.watch(petRepositoryProvider);
  final allPets = await petRepository.getAllPets();
  
  // 내 반려동물 제외
  if (userId != null) {
    return allPets.where((pet) => pet.ownerId != userId).toList();
  }
  return allPets;
});

// 받은 좋아요 목록
final receivedLikesProvider = StreamProvider.autoDispose<List<LikeModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<LikeModel>[]);
      }
      final firestoreService = ref.watch(_firestoreServiceProvider);
      return firestoreService.watchReceivedLikes(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(<LikeModel>[]),
  );
});

// 매칭 목록
final userMatchesProvider = FutureProvider.autoDispose<List<MatchModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getUserMatches(userId);
});

// 받은 좋아요 개수
final receivedLikesCountProvider = Provider.autoDispose<int>((ref) {
  final likes = ref.watch(receivedLikesProvider).valueOrNull ?? [];
  return likes.length;
});

// 교배 가능한 반려동물 목록 (isBreedingAvailable = true)
final breedingPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  final petRepository = ref.watch(petRepositoryProvider);
  final allPets = await petRepository.getAllPets();
  
  // 내 반려동물 제외 + 교배 가능한 반려동물만
  return allPets.where((pet) {
    if (userId != null && pet.ownerId == userId) return false;
    return pet.isBreedingAvailable;
  }).toList();
});

// AI 추천 반려동물 목록 (추후 AI 알고리즘 적용)
final aiRecommendedPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  final petRepository = ref.watch(petRepositoryProvider);
  final allPets = await petRepository.getAllPets();
  
  // 내 반려동물 제외
  final otherPets = allPets.where((pet) {
    if (userId != null && pet.ownerId == userId) return false;
    return true;
  }).toList();
  
  // TODO: AI 알고리즘으로 궁합 점수 계산 후 정렬 구현 예정
  // 현재는 랜덤 셔플 후 상위 10개 반환
  otherPets.shuffle();
  return otherPets.take(10).toList();
});
