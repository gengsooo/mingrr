import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dating_model.dart';
import 'firebase_providers.dart';

final receivedLikesProvider = StreamProvider<List<LikeModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchReceivedLikes(userId);
});

final userMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUserMatches(userId);
});
