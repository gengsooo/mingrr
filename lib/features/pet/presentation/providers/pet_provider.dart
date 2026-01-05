import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/pet_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/pet_repository.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository();
});

final userPetsProvider = StreamProvider.autoDispose<List<PetModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  // Firebase Auth 상태를 직접 사용하여 더 빠르게 펫 데이터 로드
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<PetModel>[]);
      }
      final repository = ref.watch(petRepositoryProvider);
      return repository.getUserPets(user.uid);
    },
    loading: () => const Stream<List<PetModel>>.empty(),
    error: (_, __) => Stream.value(<PetModel>[]),
  );
});

final allPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  return repository.getAllPets();
});

/// 내 반려동물을 제외한 다른 사람의 반려동물 목록 (추천친구용)
final otherPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  final repository = ref.watch(petRepositoryProvider);
  final allPets = await repository.getAllPets();
  
  // 내 반려동물 제외
  if (userId == null) return allPets;
  return allPets.where((pet) => pet.ownerId != userId).toList();
});

final selectedPetIndexProvider = StateProvider<int>((ref) => 0);

final selectedPetProvider = Provider.autoDispose<PetModel?>((ref) {
  final pets = ref.watch(userPetsProvider).valueOrNull ?? [];
  final selectedIndex = ref.watch(selectedPetIndexProvider);
  
  if (pets.isEmpty || selectedIndex >= pets.length) {
    return null;
  }
  
  return pets[selectedIndex];
});

/// 특정 ID로 반려동물 조회
final petByIdProvider = FutureProvider.autoDispose.family<PetModel?, String>((ref, petId) async {
  final repository = ref.watch(petRepositoryProvider);
  return repository.getPetById(petId);
});
