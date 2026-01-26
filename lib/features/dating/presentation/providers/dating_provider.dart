import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/firebase_providers.dart' hide authStateProvider;
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/block_provider.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/matching_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/user_model.dart';
import '../../../../models/dating_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// ============================================================
/// 데이팅 관련 Provider
/// Firebase Firestore와 연동하여 데이팅 데이터 관리
/// ============================================================

final _firebase = FirebaseService();

/// 펫 + 거리 + 궁합 정보 (ItemWithDistance<PetModel> 확장)
class PetWithDistance extends ItemWithDistance<PetModel> {
  final String ownerAddress;
  final int matchScore;
  final String matchGrade;
  final String? breedingDescription; // 교배찾기 글 상세 내용
  
  PetWithDistance({
    required PetModel pet,
    required double distanceMeters,
    this.ownerAddress = '',
    this.matchScore = 0,
    this.matchGrade = '',
    this.breedingDescription,
  }) : super(item: pet, distanceMeters: distanceMeters);
  
  /// 기존 코드 호환성을 위한 접근자
  PetModel get pet => item;
}

// 모든 반려동물 목록 (데이팅용 - 내 반려동물 제외, 거리 및 궁합 정보 포함)
final datingPetsProvider = FutureProvider.autoDispose<List<PetWithDistance>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  final petRepository = ref.watch(petRepositoryProvider);
  final allPets = await petRepository.getAllPets();
  
  // 내 반려동물 제외 + 차단된 사용자 반려동물 제외
  final otherPets = userId != null
      ? allPets.where((pet) => pet.ownerId != userId && !blockedUserIds.contains(pet.ownerId)).toList()
      : allPets.where((pet) => !blockedUserIds.contains(pet.ownerId)).toList();
  
  // 내 대표 반려동물 가져오기 (궁합 계산용)
  PetModel? myPet;
  UserModel? myUser;
  if (userId != null) {
    final myPets = await petRepository.getUserPetsOnce(userId);
    if (myPets.isNotEmpty) {
      myPet = myPets.firstWhere((p) => p.isPrimary, orElse: () => myPets.first);
    }
    final myUserDoc = await _firebase.usersCollection.doc(userId).get();
    if (myUserDoc.exists) {
      myUser = UserModel.fromFirestore(myUserDoc.data()!, id: myUserDoc.id);
    }
  }
  
  // 각 펫의 주인 위치를 가져와서 거리 계산
  final result = <PetWithDistance>[];
  final ownerIds = otherPets.map((p) => p.ownerId).toSet();
  
  // 주인 정보 일괄 조회
  final ownerLocations = <String, GeoPoint?>{};
  final ownerAddresses = <String, String>{};
  final owners = <String, UserModel>{};
  
  for (final ownerId in ownerIds) {
    final ownerDoc = await _firebase.usersCollection.doc(ownerId).get();
    if (ownerDoc.exists) {
      final data = ownerDoc.data()!;
      ownerLocations[ownerId] = data['homeLocation'] != null
          ? data['homeLocation'] as GeoPoint
          : null;
      ownerAddresses[ownerId] = data['address'] ?? '';
      owners[ownerId] = UserModel.fromFirestore(data, id: ownerId);
    }
  }
  
  for (final pet in otherPets) {
    final ownerLocation = ownerLocations[pet.ownerId];
    double distance = double.infinity;
    
    if (ownerLocation != null && userLocation != null) {
      distance = LocationService.calculateDistanceFromGeoPoints(
        userLocation,
        ownerLocation,
      );
    }
    
    // 궁합 점수 계산
    int matchScore = 50; // 기본값
    String matchGrade = '보통';
    
    if (myPet != null) {
      final matchResult = MatchingService.calculateCompatibility(
        myPet: myPet,
        otherPet: pet,
        myUser: myUser,
        otherUser: owners[pet.ownerId],
        distanceMeters: distance.isFinite ? distance : null,
      );
      matchScore = matchResult.score;
      matchGrade = matchResult.grade;
    }
    
    result.add(PetWithDistance(
      pet: pet,
      distanceMeters: distance,
      ownerAddress: ownerAddresses[pet.ownerId] ?? '',
      matchScore: matchScore,
      matchGrade: matchGrade,
    ));
  }
  
  // 거리순 정렬
  result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  
  return result;
});

/// 거리 필터가 적용된 데이팅 펫 목록 (AsyncValue 유지)
final filteredDatingPetsProvider = Provider.autoDispose.family<AsyncValue<List<PetWithDistance>>, double>((ref, radiusKm) {
  final petsAsync = ref.watch(datingPetsProvider);
  
  return petsAsync.whenData((pets) {
    return pets.where((p) => p.distanceMeters <= radiusKm * 1000).toList();
  });
});

// 받은 데이팅 신청 목록
final receivedDatingRequestsProvider = StreamProvider.autoDispose<List<DatingRequestModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<DatingRequestModel>[]);
      }
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.watchReceivedDatingRequests(user.uid).handleError((error, stackTrace) {
        AppLogger.error('DatingProvider', '데이팅 신청 스트림 오류 (userId: ${user.uid})', error, stackTrace);
        return <DatingRequestModel>[];
      });
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) {
      AppLogger.error('DatingProvider', '인증 상태 오류로 데이팅 신청 로드 실패', error, stackTrace);
      return Stream.value(<DatingRequestModel>[]);
    },
  );
});

// 매칭 목록
final userMatchesProvider = FutureProvider.autoDispose<List<MatchModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserMatches(userId);
});

// 받은 데이팅 신청 개수
final receivedDatingRequestsCountProvider = Provider.autoDispose<int>((ref) {
  final requests = ref.watch(receivedDatingRequestsProvider).valueOrNull ?? [];
  return requests.where((r) => r.status == DatingRequestStatus.pending).length;
});

// 교배 가능한 반려동물 목록 (isBreedingAvailable = true, 거리 정보 포함)
final breedingPetsProvider = FutureProvider.autoDispose<List<PetWithDistance>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  final userLocation = ref.watch(currentUserLocationProvider);
  
  final petRepository = ref.watch(petRepositoryProvider);
  final allPets = await petRepository.getAllPets();
  
  // 내 반려동물 제외 + 교배 가능한 반려동물만
  final breedingPets = allPets.where((pet) {
    if (userId != null && pet.ownerId == userId) return false;
    return pet.isBreedingAvailable;
  }).toList();
  
  // 위치 정보가 없으면 거리 없이 반환
  if (userLocation == null) {
    return breedingPets.map((pet) => PetWithDistance(
      pet: pet,
      distanceMeters: 0,
    )).toList();
  }
  
  // 각 펫의 주인 위치를 가져와서 거리 계산
  final result = <PetWithDistance>[];
  final ownerIds = breedingPets.map((p) => p.ownerId).toSet();
  
  final ownerLocations = <String, GeoPoint?>{};
  final ownerAddresses = <String, String>{};
  
  for (final ownerId in ownerIds) {
    final ownerDoc = await _firebase.usersCollection.doc(ownerId).get();
    if (ownerDoc.exists) {
      final data = ownerDoc.data()!;
      ownerLocations[ownerId] = data['homeLocation'] != null
          ? data['homeLocation'] as GeoPoint
          : null;
      ownerAddresses[ownerId] = data['address'] ?? '';
    }
  }
  
  for (final pet in breedingPets) {
    final ownerLocation = ownerLocations[pet.ownerId];
    
    if (ownerLocation != null) {
      final distance = LocationService.calculateDistanceFromGeoPoints(
        userLocation,
        ownerLocation,
      );
      result.add(PetWithDistance(
        pet: pet,
        distanceMeters: distance,
        ownerAddress: ownerAddresses[pet.ownerId] ?? '',
      ));
    } else {
      result.add(PetWithDistance(
        pet: pet,
        distanceMeters: double.infinity,
        ownerAddress: ownerAddresses[pet.ownerId] ?? '',
      ));
    }
  }
  
  result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return result;
});

/// 거리 필터가 적용된 교배 펫 목록 (AsyncValue 유지)
final filteredBreedingPetsProvider = Provider.autoDispose.family<AsyncValue<List<PetWithDistance>>, double>((ref, radiusKm) {
  final petsAsync = ref.watch(breedingPetsProvider);
  
  return petsAsync.whenData((pets) {
    return pets.where((p) => p.distanceMeters <= radiusKm * 1000).toList();
  });
});

// 추천 반려동물 목록 (궁합 알고리즘 적용)
final recommendedPetsProvider = FutureProvider.autoDispose<List<RecommendedPet>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  if (userId == null) return [];
  
  // 내 정보 가져오기
  final myUserDoc = await _firebase.usersCollection.doc(userId).get();
  final myUser = myUserDoc.exists 
      ? UserModel.fromFirestore(myUserDoc.data()!, id: myUserDoc.id)
      : null;
  
  // 내 대표 반려동물 가져오기
  final petRepository = ref.watch(petRepositoryProvider);
  final myPets = await petRepository.getUserPetsOnce(userId);
  if (myPets.isEmpty) return [];
  
  // 대표 반려동물 (isPrimary가 true인 것 또는 첫번째)
  final myPet = myPets.firstWhere(
    (p) => p.isPrimary,
    orElse: () => myPets.first,
  );
  
  // 다른 반려동물 목록 가져오기 (차단된 사용자 제외)
  final allPets = await petRepository.getAllPets();
  final otherPets = allPets.where((p) => p.ownerId != userId && !blockedUserIds.contains(p.ownerId)).toList();
  
  if (otherPets.isEmpty) return [];
  
  // 각 펫의 주인 정보 가져오기
  final ownerIds = otherPets.map((p) => p.ownerId).toSet();
  final owners = <String, UserModel>{};
  final ownerLocations = <String, GeoPoint?>{};
  
  for (final ownerId in ownerIds) {
    final ownerDoc = await _firebase.usersCollection.doc(ownerId).get();
    if (ownerDoc.exists) {
      owners[ownerId] = UserModel.fromFirestore(ownerDoc.data()!, id: ownerDoc.id);
      ownerLocations[ownerId] = ownerDoc.data()!['homeLocation'] as GeoPoint?;
    }
  }
  
  // 후보 목록 생성
  final candidates = <PetCandidate>[];
  for (final pet in otherPets) {
    double? distance;
    if (userLocation != null && ownerLocations[pet.ownerId] != null) {
      distance = LocationService.calculateDistanceFromGeoPoints(
        userLocation,
        ownerLocations[pet.ownerId]!,
      );
    }
    
    candidates.add(PetCandidate(
      pet: pet,
      owner: owners[pet.ownerId],
      distanceMeters: distance,
    ));
  }
  
  // 추천 알고리즘 적용
  final matchedPets = MatchingService.generateRecommendations(
    myPet: myPet,
    myUser: myUser,
    candidates: candidates,
    maxResults: 15,
  );
  
  // RecommendedPet으로 변환
  return matchedPets.map((m) => RecommendedPet(
    pet: m.pet,
    owner: m.owner,
    matchScore: m.matchResult.score,
    matchGrade: m.matchResult.grade,
    matchDescription: m.matchResult.description,
    distanceMeters: m.distanceMeters ?? 0,
  )).toList();
});

/// 추천된 반려동물 (점수 포함)
class RecommendedPet {
  final PetModel pet;
  final UserModel? owner;
  final int matchScore;
  final String matchGrade;
  final String matchDescription;
  final double distanceMeters;
  
  RecommendedPet({
    required this.pet,
    this.owner,
    required this.matchScore,
    required this.matchGrade,
    required this.matchDescription,
    required this.distanceMeters,
  });
  
  String get distanceString => LocationService.formatDistance(distanceMeters);
}

/// ============================================================
/// 페이지네이션 데이팅 Provider
/// 
/// 서버 사이드 필터링 + 클라이언트 거리/궁합 계산 + 캐싱
/// - 교배찾기 탭
/// - 근처검색 탭
/// - 추천 탭
/// - 20개씩 로드
/// - keepAlive로 화면 전환 시 상태 유지
/// ============================================================

/// 페이지네이션 교배찾기 목록 Provider (거리 필터)
final paginatedBreedingPetsProvider = StateNotifierProvider
    .family<ClientPaginatedNotifier<PetWithDistance>, PaginatedState<PetWithDistance>, double>((ref, radiusKm) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  return ClientPaginatedNotifier<PetWithDistance>(
    pageSize: 20,
    fetchAll: () async {
      final petRepository = ref.read(petRepositoryProvider);
      final allPets = await petRepository.getAllPets();
      
      // 내 반려동물 제외 + 차단된 사용자 제외 + 교배 가능한 펫만
      final otherPets = userId != null
          ? allPets.where((pet) => 
              pet.ownerId != userId && 
              !blockedUserIds.contains(pet.ownerId) &&
              pet.isBreedingAvailable).toList()
          : allPets.where((pet) => 
              !blockedUserIds.contains(pet.ownerId) &&
              pet.isBreedingAvailable).toList();
      
      // 주인 정보 일괄 조회
      final ownerIds = otherPets.map((p) => p.ownerId).toSet();
      final ownerLocations = <String, GeoPoint?>{};
      
      for (final ownerId in ownerIds) {
        final ownerDoc = await _firebase.usersCollection.doc(ownerId).get();
        if (ownerDoc.exists) {
          final data = ownerDoc.data()!;
          ownerLocations[ownerId] = data['homeLocation'] as GeoPoint?;
        }
      }
      
      // 교배찾기 글에서 description 가져오기
      final petIds = otherPets.map((p) => p.id).toSet();
      final breedingDescriptions = <String, String>{};
      
      for (final petId in petIds) {
        final breedingQuery = await _firebase.breedingPostsCollection
            .where('petId', isEqualTo: petId)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        if (breedingQuery.docs.isNotEmpty) {
          final data = breedingQuery.docs.first.data();
          breedingDescriptions[petId] = data['description'] as String? ?? '';
        }
      }
      
      final result = <PetWithDistance>[];
      for (final pet in otherPets) {
        final ownerLocation = ownerLocations[pet.ownerId];
        double distance = double.infinity;
        
        if (ownerLocation != null && userLocation != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            ownerLocation,
          );
        }
        
        // 거리 필터 적용
        if (distance <= radiusKm * 1000) {
          result.add(PetWithDistance(
            pet: pet,
            distanceMeters: distance,
            breedingDescription: breedingDescriptions[pet.id],
          ));
        }
      }
      
      // 거리순 정렬
      result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return result;
    },
  );
});

/// 페이지네이션 근처검색 목록 Provider (거리 필터)
final paginatedNearbyPetsProvider = StateNotifierProvider
    .family<ClientPaginatedNotifier<PetWithDistance>, PaginatedState<PetWithDistance>, double>((ref, radiusKm) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  return ClientPaginatedNotifier<PetWithDistance>(
    pageSize: 20,
    fetchAll: () async {
      final petRepository = ref.read(petRepositoryProvider);
      final allPets = await petRepository.getAllPets();
      
      // 내 반려동물 제외 + 차단된 사용자 제외
      final otherPets = userId != null
          ? allPets.where((pet) => pet.ownerId != userId && !blockedUserIds.contains(pet.ownerId)).toList()
          : allPets.where((pet) => !blockedUserIds.contains(pet.ownerId)).toList();
      
      // 내 대표 반려동물 가져오기 (궁합 계산용)
      PetModel? myPet;
      UserModel? myUser;
      if (userId != null) {
        final myPets = await petRepository.getUserPetsOnce(userId);
        if (myPets.isNotEmpty) {
          myPet = myPets.firstWhere((p) => p.isPrimary, orElse: () => myPets.first);
        }
        final myUserDoc = await _firebase.usersCollection.doc(userId).get();
        if (myUserDoc.exists) {
          myUser = UserModel.fromFirestore(myUserDoc.data()!, id: myUserDoc.id);
        }
      }
      
      // 주인 정보 일괄 조회
      final ownerIds = otherPets.map((p) => p.ownerId).toSet();
      final ownerLocations = <String, GeoPoint?>{};
      final owners = <String, UserModel>{};
      
      for (final ownerId in ownerIds) {
        final ownerDoc = await _firebase.usersCollection.doc(ownerId).get();
        if (ownerDoc.exists) {
          final data = ownerDoc.data()!;
          ownerLocations[ownerId] = data['homeLocation'] as GeoPoint?;
          owners[ownerId] = UserModel.fromFirestore(data, id: ownerId);
        }
      }
      
      final result = <PetWithDistance>[];
      for (final pet in otherPets) {
        final ownerLocation = ownerLocations[pet.ownerId];
        double distance = double.infinity;
        
        if (ownerLocation != null && userLocation != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            ownerLocation,
          );
        }
        
        // 거리 필터 적용
        if (distance <= radiusKm * 1000) {
          // 궁합 점수 계산
          int matchScore = 0;
          String matchGrade = '';
          if (myPet != null && myUser != null) {
            final owner = owners[pet.ownerId];
            if (owner != null) {
              final matchResult = MatchingService.calculateCompatibility(
                myPet: myPet,
                otherPet: pet,
                myUser: myUser,
                otherUser: owner,
              );
              matchScore = matchResult.score;
              matchGrade = matchResult.grade;
            }
          }
          
          result.add(PetWithDistance(
            pet: pet,
            distanceMeters: distance,
            matchScore: matchScore,
            matchGrade: matchGrade,
          ));
        }
      }
      
      // 궁합 점수순 정렬
      result.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return result;
    },
  );
});

/// 페이지네이션 추천 목록 Provider
final paginatedRecommendedPetsProvider = StateNotifierProvider<
    ClientPaginatedNotifier<RecommendedPet>,
    PaginatedState<RecommendedPet>>((ref) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  return ClientPaginatedNotifier<RecommendedPet>(
    pageSize: 20,
    fetchAll: () async {
      if (userId == null) return [];
      
      final petRepository = ref.read(petRepositoryProvider);
      
      // 내 대표 반려동물 가져오기
      final myPets = await petRepository.getUserPetsOnce(userId);
      if (myPets.isEmpty) return [];
      
      final myPet = myPets.firstWhere((p) => p.isPrimary, orElse: () => myPets.first);
      
      // 내 사용자 정보
      final myUserDoc = await _firebase.usersCollection.doc(userId).get();
      if (!myUserDoc.exists) return [];
      final myUser = UserModel.fromFirestore(myUserDoc.data()!, id: myUserDoc.id);
      
      // 다른 반려동물 목록
      final allPets = await petRepository.getAllPets();
      final otherPets = allPets.where((pet) => 
          pet.ownerId != userId && !blockedUserIds.contains(pet.ownerId)).toList();
      
      // 후보 목록 생성
      final candidates = <PetCandidate>[];
      for (final pet in otherPets) {
        final ownerDoc = await _firebase.usersCollection.doc(pet.ownerId).get();
        if (!ownerDoc.exists) continue;
        
        final owner = UserModel.fromFirestore(ownerDoc.data()!, id: ownerDoc.id);
        double? distance;
        if (userLocation != null && owner.homeLocation != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            owner.homeLocation!,
          );
        }
        
        candidates.add(PetCandidate(
          pet: pet,
          owner: owner,
          distanceMeters: distance,
        ));
      }
      
      // 추천 알고리즘 적용
      final matchedPets = MatchingService.generateRecommendations(
        myPet: myPet,
        myUser: myUser,
        candidates: candidates,
        maxResults: 50,
      );
      
      // RecommendedPet으로 변환
      return matchedPets.map((m) => RecommendedPet(
        pet: m.pet,
        owner: m.owner,
        matchScore: m.matchResult.score,
        matchGrade: m.matchResult.grade,
        matchDescription: m.matchResult.description,
        distanceMeters: m.distanceMeters ?? 0,
      )).toList();
    },
  );
});
