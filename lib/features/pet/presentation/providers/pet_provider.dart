import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/pet_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/pet_repository.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository();
});

final userPetsProvider = StreamProvider.autoDispose<List<PetModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final repository = ref.watch(petRepositoryProvider);
  return repository.getUserPets(currentUser.id);
});

final allPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  return repository.getAllPets();
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
