import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/community_model.dart';
import '../../models/breeding_model.dart';
import '../../models/rating_model.dart';
import '../services/firebase_service.dart';
import '../constants/pet_constants.dart';

class SeedData {
  final FirebaseService _firebase = FirebaseService();
  
  Future<void> seedAll() async {
    print('🌱 더미 데이터 생성 시작...');
    
    try {
      // 기존 사용자 ID 가져오기 (users는 생성하지 않음)
      final userIds = await _getExistingUserIds();
      if (userIds.isEmpty) {
        throw Exception('사용자 데이터가 없습니다. 먼저 회원가입을 해주세요.');
      }
      print('✅ 기존 사용자 ${userIds.length}명 확인');
      
      await _seedPets(userIds);
      print('✅ 반려동물 데이터 생성 완료');
      
      await _seedProducts(userIds);
      print('✅ 상품 데이터 생성 완료');
      
      await _seedGroups(userIds);
      print('✅ 모임 데이터 생성 완료');
      
      await _seedJobs(userIds);
      print('✅ 알바 데이터 생성 완료');
      
      print('🎉 모든 더미 데이터 생성 완료!');
    } catch (e) {
      print('❌ 더미 데이터 생성 실패: $e');
      rethrow;
    }
  }
  
  Future<void> _seedPets(List<String> userIds) async {
    final now = DateTime.now();
    
    // Firebase Storage 테스트 이미지 URL (실제 업로드된 이미지 사용)
    // 다양한 케이스 테스트: 프로필+추가사진, 프로필만, 추가사진만, 사진없음
    const storageBaseUrl = 'https://firebasestorage.googleapis.com/v0/b/mingrr.firebasestorage.app/o';
    
    // 샘플 강아지 이미지 URL (Firebase Storage에 업로드된 이미지)
    final sampleImages = [
      '$storageBaseUrl/pets%2Fsample%2Fdog1.jpg?alt=media',
      '$storageBaseUrl/pets%2Fsample%2Fdog2.jpg?alt=media',
      '$storageBaseUrl/pets%2Fsample%2Fdog3.jpg?alt=media',
      '$storageBaseUrl/pets%2Fsample%2Fdog4.jpg?alt=media',
      '$storageBaseUrl/pets%2Fsample%2Fdog5.jpg?alt=media',
      '$storageBaseUrl/pets%2Fsample%2Fdog6.jpg?alt=media',
    ];
    
    // 다양한 경우의 수를 테스트할 수 있는 펫 데이터
    final pets = [
      // 케이스 1: 프로필 + 추가사진 모두 있음
      {
        'id': 'dog_001',
        'ownerId': userIds[0],
        'name': '초코',
        'breed': '포메라니안',
        'gender': 'female',
        'weight': 3.5,
        'birthDate': now.subtract(const Duration(days: 365 * 2)), // 2살
        'isNeutered': true,
        'traits': [PetTrait.active, PetTrait.friendly, PetTrait.affectionate],
        'bio': '사람 좋아하는 초코에요! 산책을 좋아해요',
        'profileImageUrl': sampleImages[0],
        'photoUrls': [sampleImages[0], sampleImages[1], sampleImages[2]],
      },
      // 케이스 2: 추가사진만 있음 (프로필 없음)
      {
        'id': 'dog_002',
        'ownerId': userIds[1],
        'name': '골디',
        'breed': '골든리트리버',
        'gender': 'male',
        'weight': 28.0,
        'birthDate': now.subtract(const Duration(days: 365 * 3)), // 3살
        'isNeutered': false,
        'traits': [PetTrait.gentle, PetTrait.loyal, PetTrait.lovesPeople],
        'bio': '착한 골디입니다. 아이들과 잘 놀아요',
        'profileImageUrl': null,
        'photoUrls': [sampleImages[1], sampleImages[2]],
      },
      // 케이스 3: 프로필만 있음 (추가사진 없음)
      {
        'id': 'dog_003',
        'ownerId': userIds[2],
        'name': '쿠키',
        'breed': '토이푸들',
        'gender': 'female',
        'weight': 2.8,
        'birthDate': now.subtract(const Duration(days: 365)), // 1살
        'isNeutered': false,
        'traits': [PetTrait.affectionate, PetTrait.playful, PetTrait.smart],
        'bio': '귀여운 쿠키, 재롱 부리는 걸 좋아해요',
        'profileImageUrl': sampleImages[2],
        'photoUrls': <String>[],
      },
      // 케이스 4: 사진 없음 (프로필, 추가사진 모두 없음)
      {
        'id': 'dog_004',
        'ownerId': userIds[2],
        'name': '크림',
        'breed': '토이푸들',
        'gender': 'male',
        'weight': 3.2,
        'birthDate': now.subtract(const Duration(days: 180)), // 6개월
        'isNeutered': true,
        'traits': [PetTrait.gentle, PetTrait.calm, PetTrait.shy],
        'bio': '쿠키의 동생 크림이, 낯가림이 있어요',
        'profileImageUrl': null,
        'photoUrls': <String>[],
      },
      // 케이스 5: 추가사진 여러장
      {
        'id': 'dog_005',
        'ownerId': userIds[3],
        'name': '코코',
        'breed': '웰시코기',
        'gender': 'male',
        'weight': 12.5,
        'birthDate': now.subtract(const Duration(days: 365 * 4)), // 4살
        'isNeutered': true,
        'traits': [PetTrait.brave, PetTrait.protective, PetTrait.loyal, PetTrait.active],
        'bio': '에너지 넘치는 코코, 산책 많이 해야해요',
        'profileImageUrl': sampleImages[3],
        'photoUrls': [sampleImages[3], sampleImages[4], sampleImages[5], sampleImages[0]],
      },
      // 케이스 6: 사진 없음
      {
        'id': 'dog_006',
        'ownerId': userIds[4],
        'name': '시바',
        'breed': '시바견',
        'gender': 'female',
        'weight': 9.0,
        'birthDate': now.subtract(const Duration(days: 365 * 2 + 180)), // 2.5살
        'isNeutered': false,
        'traits': [PetTrait.independent, PetTrait.calm, PetTrait.smart],
        'bio': '도도한 시바, 자기만의 시간이 필요해요',
        'profileImageUrl': null,
        'photoUrls': <String>[],
      },
      // 케이스 7: 추가사진만 1장
      {
        'id': 'dog_007',
        'ownerId': userIds[5],
        'name': '뭉치',
        'breed': '비숑프리제',
        'gender': 'male',
        'weight': 5.5,
        'birthDate': now.subtract(const Duration(days: 365 * 5)), // 5살
        'isNeutered': true,
        'traits': [PetTrait.friendly, PetTrait.playful, PetTrait.lovesPeople, PetTrait.affectionate],
        'bio': '모든 강아지와 친하게 지내요',
        'profileImageUrl': null,
        'photoUrls': [sampleImages[4]],
      },
      // 케이스 8: 프로필 + 추가사진 모두 있음
      {
        'id': 'dog_008',
        'ownerId': userIds[6],
        'name': '하양이',
        'breed': '말티즈',
        'gender': 'female',
        'weight': 2.5,
        'birthDate': now.subtract(const Duration(days: 365 * 7)), // 7살 (노령견)
        'isNeutered': true,
        'traits': [PetTrait.shy, PetTrait.calm, PetTrait.affectionate],
        'bio': '조용한 산책을 좋아하는 하양이',
        'profileImageUrl': sampleImages[5],
        'photoUrls': [sampleImages[5], sampleImages[0]],
      },
      // 케이스 9: 사진 없음
      {
        'id': 'dog_009',
        'ownerId': userIds[7],
        'name': '뽀미',
        'breed': '포메라니안',
        'gender': 'male',
        'weight': 4.0,
        'birthDate': now.subtract(const Duration(days: 365)), // 1살
        'isNeutered': false,
        'traits': [PetTrait.active, PetTrait.playful, PetTrait.brave],
        'bio': '활발한 뽀미, 같이 뛰어놀 친구 찾아요',
        'profileImageUrl': null,
        'photoUrls': <String>[],
      },
      // 케이스 10: 추가사진만 있음
      {
        'id': 'dog_010',
        'ownerId': userIds[8],
        'name': '백구',
        'breed': '진돗개',
        'gender': 'male',
        'weight': 22.0,
        'birthDate': now.subtract(const Duration(days: 365 * 3)), // 3살
        'isNeutered': false,
        'traits': [PetTrait.loyal, PetTrait.protective, PetTrait.brave, PetTrait.independent],
        'bio': '충성스러운 백구, 등산 좋아해요',
        'profileImageUrl': null,
        'photoUrls': [sampleImages[1], sampleImages[3]],
      },
      // 케이스 11: 프로필 + 추가사진 모두 있음
      {
        'id': 'dog_011',
        'ownerId': userIds[9],
        'name': '슈슈',
        'breed': '미니어처 슈나우저',
        'gender': 'female',
        'weight': 7.0,
        'birthDate': now.subtract(const Duration(days: 365 * 2)), // 2살
        'isNeutered': true,
        'traits': [PetTrait.smart, PetTrait.active, PetTrait.friendly, PetTrait.playful],
        'bio': '똑똒한 슈슈, 훈련을 잘 받아요',
        'profileImageUrl': sampleImages[2],
        'photoUrls': [sampleImages[2], sampleImages[4], sampleImages[5]],
      },
      // 케이스 12: 사진 없음
      {
        'id': 'dog_012',
        'ownerId': userIds[0],
        'name': '래브',
        'breed': '래브라도 리트리버',
        'gender': 'female',
        'weight': 25.0,
        'birthDate': now.subtract(const Duration(days: 365 * 6)), // 6살
        'isNeutered': true,
        'traits': [PetTrait.gentle, PetTrait.calm, PetTrait.lovesPeople, PetTrait.loyal],
        'bio': '온순한 래브, 물놀이를 좋아해요',
        'profileImageUrl': null,
        'photoUrls': <String>[],
      },
      // 케이스 13: 프로필만 있음
      {
        'id': 'dog_013',
        'ownerId': userIds[1],
        'name': '치치',
        'breed': '치와와',
        'gender': 'male',
        'weight': 1.8,
        'birthDate': now.subtract(const Duration(days: 365 * 4)), // 4살
        'isNeutered': true,
        'traits': [PetTrait.shy, PetTrait.affectionate, PetTrait.protective],
        'bio': '작지만 용감한 치치',
        'profileImageUrl': sampleImages[0],
        'photoUrls': <String>[],
      },
      // 케이스 14: 추가사진 여러장
      {
        'id': 'dog_014',
        'ownerId': userIds[3],
        'name': '비비',
        'breed': '비글',
        'gender': 'female',
        'weight': 10.0,
        'birthDate': now.subtract(const Duration(days: 365 + 180)), // 1.5살
        'isNeutered': false,
        'traits': [PetTrait.friendly, PetTrait.active, PetTrait.playful, PetTrait.smart],
        'bio': '호기심 많은 비비, 냄새 맡는 걸 좋아해요',
        'profileImageUrl': sampleImages[3],
        'photoUrls': [sampleImages[3], sampleImages[1], sampleImages[5]],
      },
      // 케이스 15: 추가사진만 있음
      {
        'id': 'dog_015',
        'ownerId': userIds[5],
        'name': '하늘이',
        'breed': '시베리안 허스키',
        'gender': 'male',
        'weight': 23.0,
        'birthDate': now.subtract(const Duration(days: 365 * 2)), // 2살
        'isNeutered': false,
        'traits': [PetTrait.independent, PetTrait.active, PetTrait.playful, PetTrait.brave],
        'bio': '달리기를 좋아하는 하늘이',
        'profileImageUrl': null,
        'photoUrls': [sampleImages[4], sampleImages[2]],
      },
    ];
    
    for (int i = 0; i < pets.length; i++) {
      final petData = pets[i];
      // 첫번째 펫만 isPrimary = true
      final isPrimary = i == 0 || 
          (i > 0 && petData['ownerId'] != pets[i - 1]['ownerId']);
      
      final pet = PetModel(
        id: petData['id'] as String,
        ownerId: petData['ownerId'] as String,
        isPrimary: isPrimary,
        name: petData['name'] as String,
        breed: petData['breed'] as String,
        birthDate: petData['birthDate'] as DateTime?,
        gender: petData['gender'] == 'male' ? PetGender.male : PetGender.female,
        weight: petData['weight'] as double,
        isNeutered: petData['isNeutered'] as bool,
        traits: (petData['traits'] as List<PetTrait>),
        bio: petData['bio'] as String,
        profileImageUrl: petData['profileImageUrl'] as String?,
        photoUrls: (petData['photoUrls'] as List<String>?) ?? [],
        isRegistrationVerified: true,
        isVaccinationVerified: true,
        hasPedigree: false,
        isBreedingAvailable: !(petData['isNeutered'] as bool),
        healthBookEnabled: true,
        enabledHealthCategories: [HealthCategory.weight, HealthCategory.vaccination, HealthCategory.walk],
        walkFeatureEnabled: true,
        likeCount: i * 2, // 다양한 좋아요 수
        createdAt: now,
        updatedAt: now,
      );
      
      await _firebase.petsCollection.doc(pet.id).set(pet.toFirestore());
      
      await _firebase.usersCollection.doc(pet.ownerId).update({
        'petIds': FieldValue.arrayUnion([pet.id]),
      });
    }
  }
  
  Future<void> _seedProducts(List<String> userIds) async {
    final now = DateTime.now();
    
    final products = [
      {
        'sellerId': userIds[0],
        'title': '강아지 옷 (소형견용)',
        'description': '한번도 안입은 새상품입니다. 사이즈가 안맞아서 팔아요.',
        'price': 15000,
        'type': 'sell',
        'category': 'clothes',
        'location': const GeoPoint(37.5665, 126.9780),
        'address': '서울시 중구',
      },
      {
        'sellerId': userIds[1],
        'title': '강아지 사료 나눔',
        'description': '우리 강아지가 안먹어서 나눔합니다. 유통기한 충분해요.',
        'price': 0,
        'type': 'share',
        'category': 'food',
        'location': const GeoPoint(37.4979, 127.0276),
        'address': '서울시 강남구',
      },
      {
        'sellerId': userIds[2],
        'title': '강아지 장난감 세트',
        'description': '거의 새것입니다. 5개 세트로 판매해요.',
        'price': 20000,
        'type': 'sell',
        'category': 'toys',
        'location': const GeoPoint(37.5172, 127.0473),
        'address': '서울시 송파구',
      },
      {
        'sellerId': userIds[3],
        'title': '강아지 이동장 (중형견)',
        'description': '깨끗하게 사용했습니다. 직거래 선호',
        'price': 50000,
        'type': 'sell',
        'category': 'supplies',
        'location': const GeoPoint(37.5219, 126.9245),
        'address': '서울시 마포구',
      },
      {
        'sellerId': userIds[4],
        'title': '강아지 목줄 나눔',
        'description': '사이즈가 안맞아서 나눔합니다',
        'price': 0,
        'type': 'share',
        'category': 'supplies',
        'location': const GeoPoint(37.5326, 126.9910),
        'address': '서울시 용산구',
      },
    ];
    
    for (int i = 0; i < products.length; i++) {
      final productData = products[i];
      final product = ProductModel(
        id: 'product_${(i + 1).toString().padLeft(3, '0')}',
        sellerId: productData['sellerId'] as String,
        title: productData['title'] as String,
        description: productData['description'] as String,
        price: productData['price'] as int,
        type: productData['type'] == 'sell' ? ProductType.sell : ProductType.share,
        category: ProductCategory.values.firstWhere(
          (e) => e.name == productData['category'],
        ),
        status: ProductStatus.available,
        imageUrls: [],
        location: productData['location'] as GeoPoint,
        address: productData['address'] as String,
        viewCount: (i * 5) + 3,
        likeCount: i + 1,
        chatCount: i,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firebase.productsCollection.doc(product.id).set(product.toFirestore());
    }
  }
  
  Future<void> _seedGroups(List<String> userIds) async {
    final now = DateTime.now();
    
    final groups = [
      {
        'creatorId': userIds[0],
        'name': '한강 산책 모임',
        'description': '매주 주말 한강에서 산책해요! 소형견 환영',
        'type': 'walking',
        'location': const GeoPoint(37.5219, 126.9245),
        'address': '서울특별시 서울특별시 마포구',
        'isPublic': true,
        'maxMembers': 20,
        'likeCount': 45,
      },
      {
        'creatorId': userIds[1],
        'name': '대형견 놀이터',
        'description': '대형견들끼리 모여서 놀아요',
        'type': 'social',
        'location': const GeoPoint(37.5172, 127.0473),
        'address': '서울특별시 서울특별시 강남구',
        'isPublic': true,
        'maxMembers': 15,
        'likeCount': 32,
      },
      {
        'creatorId': userIds[2],
        'name': '강아지 훈련 스터디',
        'description': '같이 훈련 방법 공유하고 연습해요',
        'type': 'training',
        'location': const GeoPoint(37.5145, 127.1066),
        'address': '서울특별시 서울특별시 송파구',
        'isPublic': true,
        'maxMembers': 10,
        'likeCount': 18,
      },
      {
        'creatorId': userIds[0],
        'name': '분당 댕댕이 모임',
        'description': '분당 지역 반려견 친목 모임입니다',
        'type': 'social',
        'location': const GeoPoint(37.3825, 127.1188),
        'address': '경기도 성남시 분당구',
        'isPublic': true,
        'maxMembers': 25,
        'likeCount': 28,
      },
      {
        'creatorId': userIds[1],
        'name': '용인 산책 친구들',
        'description': '용인 지역에서 함께 산책해요',
        'type': 'walking',
        'location': const GeoPoint(37.2346, 127.2090),
        'address': '경기도 용인특례시 처인구',
        'isPublic': true,
        'maxMembers': 15,
        'likeCount': 12,
      },
      {
        'creatorId': userIds[2],
        'name': '수제 간식 만들기',
        'description': '건강한 수제 간식 함께 만들어요',
        'type': 'craft',
        'location': const GeoPoint(37.4837, 127.0324),
        'address': '서울특별시 서울특별시 서초구',
        'isPublic': true,
        'maxMembers': 8,
        'likeCount': 55,
      },
      {
        'creatorId': userIds[0],
        'name': '시니어 반려견 케어',
        'description': '노령견 케어 정보 공유 모임',
        'type': 'health',
        'location': const GeoPoint(37.5663, 126.9014),
        'address': '서울특별시 서울특별시 마포구',
        'isPublic': true,
        'maxMembers': 20,
        'likeCount': 38,
      },
    ];
    
    for (int i = 0; i < groups.length; i++) {
      final groupData = groups[i];
      final creatorId = groupData['creatorId'] as String;
      
      final group = GroupModel(
        id: 'group_${(i + 1).toString().padLeft(3, '0')}',
        name: groupData['name'] as String,
        description: groupData['description'] as String,
        type: GroupType.values.firstWhere(
          (e) => e.name == groupData['type'],
        ),
        creatorId: creatorId,
        adminIds: [creatorId],
        memberIds: [creatorId],
        maxMembers: groupData['maxMembers'] as int,
        location: groupData['location'] as GeoPoint,
        address: groupData['address'] as String,
        isPublic: groupData['isPublic'] as bool,
        requireApproval: false,
        tags: [],
        likeCount: groupData['likeCount'] as int,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firebase.groupsCollection.doc(group.id).set(group.toFirestore());
    }
  }
  Future<void> clearAllData() async {
    print('🗑️  모든 데이터 삭제 시작...');
    
    try {
      // 데이터베이스 데이터 삭제 (사용자 컨렉션은 제외 - 로그인 세션 유지를 위해)
      await _clearCollection(_firebase.petsCollection);
      await _clearCollection(_firebase.productsCollection);
      await _clearCollection(_firebase.groupsCollection);
      await _clearCollection(_firebase.groupLikesCollection);
      await _clearCollection(_firebase.chatRoomsCollection);
      await _clearCollection(_firebase.likesCollection);
      await _clearCollection(_firebase.matchesCollection);
      await _clearCollection(_firebase.jobsCollection);
      await _clearCollection(_firebase.breedingPostsCollection);
      await _clearCollection(_firebase.ratingsCollection);
      await _clearCollection(_firebase.firestore.collection('transaction_statuses'));
      
      print('✅ 모든 Firestore 데이터 삭제 완료 (users 컬렉션 제외)');
    } catch (e) {
      print('❌ 데이터 삭제 실패: $e');
      rethrow;
    }
  }
  
  Future<void> _clearCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    
    // 데이터베이스 배치는 최대 500개까지만 처리 가능
    const batchSize = 500;
    final docs = snapshot.docs;
    
    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = _firebase.firestore.batch();
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      
      for (int j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      
      await batch.commit();
    }
  }
  
  // ===== 항목별 생성 메서드 =====
  
  /// 반려동물 데이터만 생성
  Future<void> seedPets() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedPets(userIds);
  }
  
  /// 상품 데이터만 생성
  Future<void> seedProducts() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedProducts(userIds);
  }
  
  /// 소모임 데이터만 생성
  Future<void> seedGroups() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedGroups(userIds);
  }
  
  /// 알바 데이터만 생성
  Future<void> seedJobs() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedJobs(userIds);
  }
  
  /// 좋아요/매칭 데이터만 생성
  Future<void> seedLikesAndMatches() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedLikesAndMatches(userIds);
  }
  
  /// 채팅 데이터만 생성
  Future<void> seedChats() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedChats(userIds);
  }
  
  /// 교배 글 데이터만 생성
  Future<void> seedBreedingPosts() async {
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    await _seedBreedingPosts(userIds);
  }
  
  Future<void> _seedBreedingPosts(List<String> userIds) async {
    final now = DateTime.now();
    
    // 기존 펫 ID 가져오기
    final petsSnapshot = await _firebase.petsCollection.limit(5).get();
    final petIds = petsSnapshot.docs.map((doc) => doc.id).toList();
    
    if (petIds.isEmpty) {
      print('  ⚠️ 반려동물 데이터가 없어서 교배 글을 생성할 수 없습니다.');
      return;
    }
    
    final posts = [
      {
        'userId': userIds[0],
        'petId': petIds.isNotEmpty ? petIds[0] : 'pet_001',
        'title': '건강한 골든 리트리버 교배 원해요',
        'description': '3살 수컷 골든 리트리버입니다. 건강검진 완료했고, 성격이 온순해요. 같은 품종 또는 대형견 암컷 찾습니다.',
        'preferredGender': 'female',
        'preferredSizes': ['large', 'giant'],
        'sameBreedOnly': false,
        'maxAge': 5,
      },
      {
        'userId': userIds.length > 1 ? userIds[1] : userIds[0],
        'petId': petIds.length > 1 ? petIds[1] : petIds[0],
        'title': '말티즈 교배 상대 구합니다',
        'description': '2살 암컷 말티즈예요. 혈통서 있고 건강해요. 같은 품종 수컷 원합니다.',
        'preferredGender': 'male',
        'preferredSizes': ['tiny', 'small'],
        'sameBreedOnly': true,
        'maxAge': 3,
      },
      {
        'userId': userIds.length > 2 ? userIds[2] : userIds[0],
        'petId': petIds.length > 2 ? petIds[2] : petIds[0],
        'title': '푸들 교배 파트너 찾아요',
        'description': '토이푸들 수컷 4살입니다. 성격 좋고 건강해요. 소형견 암컷 구합니다.',
        'preferredGender': 'female',
        'preferredSizes': ['tiny', 'small'],
        'sameBreedOnly': false,
        'maxAge': 5,
      },
    ];
    
    for (int i = 0; i < posts.length; i++) {
      final postData = posts[i];
      
      final post = BreedingPostModel(
        id: 'breeding_${(i + 1).toString().padLeft(3, '0')}',
        userId: postData['userId'] as String,
        petId: postData['petId'] as String,
        title: postData['title'] as String,
        description: postData['description'] as String,
        status: BreedingStatus.active,
        preferredGender: postData['preferredGender'] as String?,
        preferredSizes: List<String>.from(postData['preferredSizes'] as List),
        sameBreedOnly: postData['sameBreedOnly'] as bool,
        maxAge: postData['maxAge'] as int?,
        viewCount: (i + 1) * 10,
        likeCount: (i + 1) * 3,
        chatCount: i,
        createdAt: now.subtract(Duration(days: i)),
        updatedAt: now.subtract(Duration(days: i)),
      );
      
      await _firebase.breedingPostsCollection.doc(post.id).set(post.toFirestore());
    }
    
    print('  ✓ 교배 글 ${posts.length}개 생성 완료');
  }
  
  // ===== 항목별 삭제 메서드 =====
  
  Future<void> clearUsers() async {
    await _clearCollection(_firebase.usersCollection);
  }
  
  Future<void> clearPets() async {
    await _clearCollection(_firebase.petsCollection);
  }
  
  Future<void> clearProducts() async {
    await _clearCollection(_firebase.productsCollection);
  }
  
  Future<void> clearGroups() async {
    await _clearCollection(_firebase.groupsCollection);
  }
  
  Future<void> clearJobs() async {
    await _clearCollection(_firebase.jobsCollection);
  }
  
  Future<void> clearLikesAndMatches() async {
    await _clearCollection(_firebase.likesCollection);
    await _clearCollection(_firebase.matchesCollection);
  }
  
  Future<void> clearChats() async {
    await _clearCollection(_firebase.chatRoomsCollection);
  }
  
  Future<void> clearBreedingPosts() async {
    await _clearCollection(_firebase.breedingPostsCollection);
  }
  
  // ===== 헬퍼 메서드 =====
  
  Future<List<String>> _getExistingUserIds() async {
    final snapshot = await _firebase.usersCollection.limit(10).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
  
  Future<void> _seedJobs(List<String> userIds) async {
    final now = DateTime.now();
    
    final jobs = [
      {
        'userId': userIds[0],
        'title': '여행 중 우리 아이 돌봐주실 분',
        'description': '12월 25일부터 28일까지 3박 4일 동안 돌봐주실 분 구해요',
        'type': 'care',
        'price': 50000,
        'priceUnit': '일',
        'startDate': now.add(const Duration(days: 5)),
        'endDate': now.add(const Duration(days: 8)),
        'address': '서울시 강남구 역삼동',
      },
      {
        'userId': userIds[1],
        'title': '평일 오전 산책 도우미 구해요',
        'description': '월~금 오전 8시~9시 산책 부탁드려요',
        'type': 'walk',
        'price': 15000,
        'priceUnit': '회',
        'duration': 1,
        'address': '서울시 마포구 상암동',
      },
      {
        'userId': userIds[2],
        'title': '대형견 목욕 도와주실 분',
        'description': '골든리트리버 목욕 도와주실 분 구해요',
        'type': 'bath',
        'price': 30000,
        'priceUnit': '회',
        'duration': 2,
        'address': '서울시 송파구 잠실동',
      },
      {
        'userId': userIds.length > 3 ? userIds[3] : userIds[0],
        'title': '기본 훈련 도와주실 분',
        'description': '앉아, 기다려 등 기본 훈련 도와주세요',
        'type': 'training',
        'price': 40000,
        'priceUnit': '회',
        'duration': 1,
        'address': '서울시 용산구 이태원동',
      },
    ];
    
    for (int i = 0; i < jobs.length; i++) {
      final jobData = jobs[i];
      final job = JobModel(
        id: 'job_${(i + 1).toString().padLeft(3, '0')}',
        userId: jobData['userId'] as String,
        title: jobData['title'] as String,
        description: jobData['description'] as String,
        type: JobType.values.firstWhere((e) => e.name == jobData['type']),
        status: JobStatus.recruiting,
        price: jobData['price'] as int,
        priceUnit: jobData['priceUnit'] as String,
        startDate: jobData['startDate'] as DateTime?,
        endDate: jobData['endDate'] as DateTime?,
        duration: jobData['duration'] as int?,
        address: jobData['address'] as String,
        createdAt: now.subtract(Duration(hours: i)),
        updatedAt: now.subtract(Duration(hours: i)),
      );
      
      await _firebase.jobsCollection.doc(job.id).set(job.toFirestore());
    }
  }
  
  Future<void> _seedLikesAndMatches(List<String> userIds) async {
    if (userIds.length < 2) return;
    
    final now = DateTime.now();
    final petsSnapshot = await _firebase.petsCollection.get();
    final pets = petsSnapshot.docs;
    
    if (pets.length < 2) return;
    
    // 좋아요 데이터 생성 (일부는 pending, 일부는 accepted)
    for (int i = 0; i < pets.length - 1; i++) {
      final fromPet = pets[i];
      final toPet = pets[(i + 1) % pets.length];
      
      final fromUserId = fromPet.data()['ownerId'] as String?;
      final toUserId = toPet.data()['ownerId'] as String?;
      
      if (fromUserId == null || toUserId == null || fromUserId == toUserId) continue;
      
      final likeId = 'like_${fromPet.id}_${toPet.id}';
      final status = i % 3 == 0 ? 'accepted' : (i % 3 == 1 ? 'rejected' : 'pending');
      
      await _firebase.likesCollection.doc(likeId).set({
        'fromUserId': fromUserId,
        'fromPetId': fromPet.id,
        'toUserId': toUserId,
        'toPetId': toPet.id,
        'status': status,
        'isSuperLike': i % 5 == 0,
        'message': i % 2 == 0 ? '안녕하세요! 우리 아이랑 친구해요 🐕' : null,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: i * 2))),
        'respondedAt': status != 'pending' 
            ? Timestamp.fromDate(now.subtract(Duration(hours: i)))
            : null,
      });
      
      // 매칭 데이터 생성 (accepted인 경우)
      if (status == 'accepted') {
        final matchId = 'match_${fromPet.id}_${toPet.id}';
        final chatRoomId = 'chat_$matchId';
        
        await _firebase.matchesCollection.doc(matchId).set({
          'userIds': [fromUserId, toUserId],
          'petIds': [fromPet.id, toPet.id],
          'chatRoomId': chatRoomId,
          'type': 'dating',
          'compatibilityScore': 70 + (i % 30),
          'matchedAt': Timestamp.fromDate(now.subtract(Duration(hours: i))),
          'isActive': true,
        });
      }
    }
  }
  
  Future<void> _seedChats(List<String> userIds) async {
    if (userIds.length < 2) return;
    
    final now = DateTime.now();
    
    // 채팅방 및 메시지 생성
    for (int i = 0; i < userIds.length - 1; i++) {
      final user1 = userIds[i];
      final user2 = userIds[(i + 1) % userIds.length];
      
      if (user1 == user2) continue;
      
      final chatRoomId = 'chatroom_${user1}_$user2';
      
      // 채팅방 생성 - 양쪽 사용자 모두에게 읽지 않은 메시지 설정
      await _firebase.chatRoomsCollection.doc(chatRoomId).set({
        'participantIds': [user1, user2],
        'participants': {}, // 참여자 정보는 나중에 업데이트
        'type': i % 2 == 0 ? 'dating' : 'market',
        'lastMessage': '안녕하세요! 반가워요 😊',
        'lastMessageSenderId': user1,
        'lastMessageAt': Timestamp.fromDate(now.subtract(Duration(minutes: i * 30))),
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: i))),
        'unreadCounts': {user1: i % 2 + 1, user2: i % 3 + 1},
        'isActive': true,
      });
      
      // 메시지 생성
      final messages = [
        {'sender': user1, 'content': '안녕하세요!', 'offset': 60},
        {'sender': user2, 'content': '안녕하세요~ 반가워요!', 'offset': 55},
        {'sender': user1, 'content': '우리 아이 사진 봤어요. 너무 귀여워요 🐕', 'offset': 50},
        {'sender': user2, 'content': '감사해요! 저도 사진 봤는데 정말 사랑스럽네요 💕', 'offset': 45},
        {'sender': user1, 'content': '이번 주말에 산책 어떠세요?', 'offset': 40},
        {'sender': user2, 'content': '좋아요! 한강공원 어때요?', 'offset': 35},
        {'sender': user1, 'content': '완전 좋아요! 토요일 오전 10시 어떨까요?', 'offset': 30},
        {'sender': user2, 'content': '네 좋습니다! 그때 봬요 😊', 'offset': 25},
      ];
      
      for (int j = 0; j < messages.length; j++) {
        final msg = messages[j];
        final messageId = 'msg_${chatRoomId}_$j';
        
        await _firebase.messagesCollection(chatRoomId).doc(messageId).set({
          'senderId': msg['sender'],
          'content': msg['content'],
          'type': 'text',
          'sentAt': Timestamp.fromDate(now.subtract(Duration(minutes: msg['offset'] as int))),
          'isRead': j < messages.length - 2,
        });
      }
    }
  }
  
  // ===== 건강수첩 데이터 생성 =====
  
  Future<void> seedHealthRecords() async {
    print('🏥 건강수첩 데이터 생성 시작...');
    
    try {
      // 기존 펫 ID 가져오기
      final petsSnapshot = await _firebase.petsCollection.limit(5).get();
      final petIds = petsSnapshot.docs.map((doc) => doc.id).toList();
      
      if (petIds.isEmpty) {
        print('❌ 반려동물 데이터가 없습니다. 먼저 반려동물을 생성해주세요.');
        return;
      }
      
      await _seedWeightRecords(petIds);
      print('  ✓ 체중 기록 생성 완료');
      
      await _seedWalkRecords(petIds);
      print('  ✓ 산책 기록 생성 완료');
      
      await _seedGroomingRecords(petIds);
      print('  ✓ 그루밍 기록 생성 완료');
      
      await _seedVaccinationRecords(petIds);
      print('  ✓ 예방접종 기록 생성 완료');
      
      await _seedCheckupRecords(petIds);
      print('  ✓ 검진 기록 생성 완료');
      
      await _seedMedicationRecords(petIds);
      print('  ✓ 약 복용 기록 생성 완료');
      
      print('✅ 건강수첩 데이터 생성 완료!');
    } catch (e) {
      print('❌ 건강수첩 데이터 생성 실패: $e');
      rethrow;
    }
  }
  
  Future<void> _seedWeightRecords(List<String> petIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('weight_records');
    
    for (int p = 0; p < petIds.length; p++) {
      final petId = petIds[p];
      final baseWeight = 3.0 + p * 2; // 3kg, 5kg, 7kg...
      
      for (int i = 0; i < 10; i++) {
        final recordDate = now.subtract(Duration(days: i * 7));
        final weight = baseWeight + (i % 3 - 1) * 0.1; // 약간의 변동
        
        await collection.doc('weight_${petId}_$i').set({
          'petId': petId,
          'weight': weight,
          'recordDate': Timestamp.fromDate(recordDate),
          'notes': i == 0 ? '정기 체중 측정' : null,
          'createdAt': Timestamp.fromDate(recordDate),
        });
      }
    }
  }
  
  Future<void> _seedWalkRecords(List<String> petIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('walk_records');
    
    for (int p = 0; p < petIds.length; p++) {
      final petId = petIds[p];
      
      for (int i = 0; i < 15; i++) {
        final startTime = now.subtract(Duration(days: i)).copyWith(hour: 8 + (i % 3) * 4);
        final duration = 20 + (i % 4) * 10; // 20~50분
        final distance = 800 + (i % 5) * 300; // 800~2000m
        
        await collection.doc('walk_${petId}_$i').set({
          'petId': petId,
          'petIds': [petId],
          'userId': 'user_00${(p % 10) + 1}',
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(startTime.add(Duration(minutes: duration))),
          'distance': distance.toDouble(),
          'calories': (distance * 0.05).toDouble(),
          'routePoints': [],
          'footprints': [],
          'notes': i == 0 ? '오늘 산책 완료!' : null,
          'photoUrls': [],
          'createdAt': Timestamp.fromDate(startTime),
        });
      }
    }
  }
  
  Future<void> _seedGroomingRecords(List<String> petIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('grooming_records');
    final groomingTypes = ['shower', 'brushing', 'nailTrim', 'haircut', 'earCleaning'];
    final locations = ['집에서', '미용실', '동물병원'];
    
    for (int p = 0; p < petIds.length; p++) {
      final petId = petIds[p];
      
      for (int i = 0; i < 8; i++) {
        final recordDate = now.subtract(Duration(days: i * 5));
        
        await collection.doc('grooming_${petId}_$i').set({
          'petId': petId,
          'groomingType': groomingTypes[i % groomingTypes.length],
          'recordDate': Timestamp.fromDate(recordDate),
          'location': locations[i % locations.length],
          'cost': i % 2 == 0 ? 30000 + i * 5000 : null,
          'notes': i == 0 ? '피부 상태 양호' : null,
          'photoUrls': [],
          'createdAt': Timestamp.fromDate(recordDate),
        });
      }
    }
  }
  
  Future<void> _seedVaccinationRecords(List<String> petIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('vaccination_records');
    final vaccines = ['종합백신 (DHPPL)', '광견병', '코로나', '켄넬코프', '인플루엔자'];
    
    for (int p = 0; p < petIds.length; p++) {
      final petId = petIds[p];
      
      for (int i = 0; i < vaccines.length; i++) {
        final vaccinationDate = now.subtract(Duration(days: i * 60 + p * 10));
        final nextDueDate = vaccinationDate.add(const Duration(days: 365));
        
        await collection.doc('vaccine_${petId}_$i').set({
          'petId': petId,
          'vaccineName': vaccines[i],
          'vaccinationDate': Timestamp.fromDate(vaccinationDate),
          'nextDueDate': Timestamp.fromDate(nextDueDate),
          'hospitalName': '행복 동물병원',
          'vetName': '김수의 원장',
          'notes': '접종 후 이상 반응 없음',
          'reminderEnabled': true,
          'reminderDaysBefore': 7,
          'createdAt': Timestamp.fromDate(vaccinationDate),
        });
      }
    }
  }
  
  Future<void> _seedCheckupRecords(List<String> petIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('checkup_records');
    final checkupTypes = ['정기 검진', '혈액 검사', '초음파 검사', 'X-ray 검사'];
    final results = ['정상', '양호 (관찰 필요)', '정상'];
    
    for (int p = 0; p < petIds.length; p++) {
      final petId = petIds[p];
      
      for (int i = 0; i < 4; i++) {
        final checkupDate = now.subtract(Duration(days: i * 90 + p * 15));
        
        await collection.doc('checkup_${petId}_$i').set({
          'petId': petId,
          'checkupDate': Timestamp.fromDate(checkupDate),
          'nextCheckupDate': Timestamp.fromDate(checkupDate.add(const Duration(days: 180))),
          'hospitalName': '행복 동물병원',
          'vetName': '김수의 원장',
          'diagnosis': results[i % results.length],
          'notes': '전반적으로 건강 상태 양호',
          'attachmentUrls': [],
          'reminderEnabled': true,
          'reminderDaysBefore': 7,
          'createdAt': Timestamp.fromDate(checkupDate),
        });
      }
    }
  }
  
  Future<void> _seedMedicationRecords(List<String> petIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('medication_records');
    final medications = [
      {'name': '심장약', 'dosage': '1정', 'interval': 'daily'},
      {'name': '피부약', 'dosage': '2정', 'interval': 'daily'},
      {'name': '관절 영양제', 'dosage': '1포', 'interval': 'daily'},
      {'name': '구충제', 'dosage': '1정', 'interval': 'monthly'},
    ];
    
    for (int p = 0; p < petIds.length; p++) {
      final petId = petIds[p];
      
      for (int i = 0; i < medications.length; i++) {
        final med = medications[i];
        final startDate = now.subtract(Duration(days: 30 + i * 10));
        
        await collection.doc('med_${petId}_$i').set({
          'petId': petId,
          'medicationName': med['name'],
          'dosage': med['dosage'],
          'interval': med['interval'],
          'intervalValue': 1,
          'startDate': Timestamp.fromDate(startDate),
          'endDate': i % 2 == 0 ? Timestamp.fromDate(startDate.add(const Duration(days: 90))) : null,
          'notes': '식후 30분에 복용',
          'reminderEnabled': true,
          'reminderTimes': ['08:00', '20:00'],
          'createdAt': Timestamp.fromDate(startDate),
        });
      }
    }
  }
  
  Future<void> clearHealthRecords() async {
    print('🗑️ 건강수첩 데이터 삭제 중...');
    await _clearCollection(_firebase.firestore.collection('weight_records'));
    await _clearCollection(_firebase.firestore.collection('walk_records'));
    await _clearCollection(_firebase.firestore.collection('grooming_records'));
    await _clearCollection(_firebase.firestore.collection('vaccination_records'));
    await _clearCollection(_firebase.firestore.collection('checkup_records'));
    await _clearCollection(_firebase.firestore.collection('medication_records'));
    print('✅ 건강수첩 데이터 삭제 완료');
  }
  
  // ===== 꼬순내 평가 데이터 =====
  
  Future<void> seedRatings() async {
    print('🌱 꼬순내 평가 데이터 생성 중...');
    
    final userIds = ['user_001', 'user_002', 'user_003', 'user_004', 'user_005', 
                     'user_006', 'user_007', 'user_008', 'user_009', 'user_010'];
    final now = DateTime.now();
    
    final positiveTags = ['친절해요', '시간 약속을 잘 지켜요', '반려동물을 잘 돌봐요', '매너가 좋아요', '응답이 빨라요', '다시 만나고 싶어요'];
    final negativeTags = ['불친절해요', '시간 약속을 안 지켜요', '연락이 안 돼요', '매너가 아쉬워요'];
    final ratingTypes = [RatingType.dating, RatingType.marketplace, RatingType.community];
    
    int ratingIndex = 0;
    
    // 각 사용자에게 다른 사용자들로부터 평가 생성
    for (int i = 0; i < userIds.length; i++) {
      final targetId = userIds[i];
      
      // 각 사용자는 3~5개의 평가를 받음
      final ratingCount = 3 + (i % 3);
      
      for (int j = 0; j < ratingCount; j++) {
        // 평가자는 다른 사용자
        final raterIndex = (i + j + 1) % userIds.length;
        final raterId = userIds[raterIndex];
        
        // 점수: 3~5점 (대부분 긍정적)
        final score = 3 + (ratingIndex % 3);
        
        // 태그 선택
        final tags = score >= 3 
            ? [positiveTags[ratingIndex % positiveTags.length], positiveTags[(ratingIndex + 1) % positiveTags.length]]
            : [negativeTags[ratingIndex % negativeTags.length]];
        
        // 평가 타입
        final ratingType = ratingTypes[ratingIndex % ratingTypes.length];
        
        // 활동 결과
        final result = score >= 3 ? ActivityResult.completed : ActivityResult.cancelled;
        
        final rating = RatingModel(
          id: 'rating_${ratingIndex.toString().padLeft(3, '0')}',
          raterId: raterId,
          targetId: targetId,
          type: ratingType,
          score: score,
          tags: tags,
          comment: score >= 4 ? '좋은 만남이었어요!' : (score >= 3 ? '괜찮았어요' : null),
          result: result,
          relatedId: 'chat_${ratingIndex % 10}',
          createdAt: now.subtract(Duration(days: ratingIndex * 2)),
        );
        
        await _firebase.ratingsCollection.doc(rating.id).set(rating.toFirestore());
        ratingIndex++;
      }
    }
    
    // 거래 상태 데이터도 생성
    await _seedTransactionStatuses(userIds);
    
    print('✅ 꼬순내 평가 ${ratingIndex}개 생성 완료');
  }
  
  Future<void> _seedTransactionStatuses(List<String> userIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('transaction_statuses');
    final types = ['marketplace', 'dating', 'breeding'];
    
    for (int i = 0; i < 10; i++) {
      final sellerId = userIds[i % userIds.length];
      final buyerId = userIds[(i + 1) % userIds.length];
      
      final status = TransactionStatusModel(
        id: 'txn_status_$i',
        chatRoomId: 'chat_$i',
        type: types[i % types.length],
        sellerId: sellerId,
        buyerId: buyerId,
        status: i % 3 == 0 ? 'completed' : 'pending',
        sellerRated: i % 4 == 0,
        buyerRated: i % 5 == 0,
        completedAt: i % 3 == 0 ? now.subtract(Duration(days: i)) : null,
        createdAt: now.subtract(Duration(days: i + 5)),
      );
      
      await collection.doc(status.id).set(status.toFirestore());
    }
  }
  
  Future<void> clearRatings() async {
    print('🗑️ 꼬순내 평가 데이터 삭제 중...');
    await _clearCollection(_firebase.ratingsCollection);
    await _clearCollection(_firebase.firestore.collection('transaction_statuses'));
    print('✅ 꼬순내 평가 데이터 삭제 완료');
  }
}
