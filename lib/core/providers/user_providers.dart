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

final userDogsProvider = StreamProvider<List<DogModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUserDogs(userId);
});

final primaryDogProvider = Provider<DogModel?>((ref) {
  final dogs = ref.watch(userDogsProvider);
  return dogs.value?.firstWhere(
    (dog) => dog.isPrimary,
    orElse: () => dogs.value!.isNotEmpty ? dogs.value!.first : null as DogModel,
  );
});
