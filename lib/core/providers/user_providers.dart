import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import 'firebase_providers.dart';

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUser(userId);
});

final userPetsProvider = StreamProvider<List<PetModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUserPets(userId);
});

final primaryPetProvider = Provider<PetModel?>((ref) {
  final pets = ref.watch(userPetsProvider);
  final petList = pets.valueOrNull;
  if (petList == null || petList.isEmpty) return null;
  return petList.firstWhere(
    (pet) => pet.isPrimary,
    orElse: () => petList.first,
  );
});
