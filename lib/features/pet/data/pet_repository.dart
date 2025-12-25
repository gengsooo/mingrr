import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/pet_model.dart';

class PetRepository {
  final FirebaseService _firebase = FirebaseService();

  Stream<List<PetModel>> getUserPets(String userId) {
    return _firebase.dogsCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('isPrimary', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromFirestore(doc))
            .toList());
  }

  Future<PetModel?> getPetById(String petId) async {
    final doc = await _firebase.dogsCollection.doc(petId).get();
    if (!doc.exists) return null;
    return PetModel.fromFirestore(doc);
  }

  Future<List<PetModel>> getAllPets() async {
    final snapshot = await _firebase.dogsCollection.get();
    return snapshot.docs
        .map((doc) => PetModel.fromFirestore(doc))
        .toList();
  }

  Future<void> createPet(PetModel pet) async {
    await _firebase.dogsCollection.doc(pet.id).set(pet.toFirestore());
  }

  Future<void> updatePet(PetModel pet) async {
    await _firebase.dogsCollection.doc(pet.id).update(pet.toFirestore());
  }

  Future<void> deletePet(String petId) async {
    await _firebase.dogsCollection.doc(petId).delete();
  }
}
