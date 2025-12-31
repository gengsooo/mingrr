import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/community_model.dart';
import '../services/firebase_service.dart';
import '../constants/pet_constants.dart';

class SeedData {
  final FirebaseService _firebase = FirebaseService();
  
  Future<void> seedAll() async {
    print('🌱 더미 데이터 생성 시작...');
    
    try {
      // 1. Firebase Auth 테스트 계정 생성
      await _createTestAccounts();
      print('✅ 테스트 계정 10개 생성 완료');
      
      // 2. Firestore 사용자 데이터 생성
      final userIds = await _seedUsers();
      print('✅ 사용자 ${userIds.length}명 생성 완료');
      
      await _seedPets(userIds);
      print('✅ 반려동물 데이터 생성 완료');
      
      await _seedProducts(userIds);
      print('✅ 상품 데이터 생성 완료');
      
      await _seedGroups(userIds);
      print('✅ 모임 데이터 생성 완료');
      
      print('🎉 모든 더미 데이터 생성 완료!');
    } catch (e) {
      print('❌ 더미 데이터 생성 실패: $e');
      rethrow;
    }
  }
  
  /// Firebase Auth 테스트 계정 생성
  Future<void> _createTestAccounts() async {
    final auth = FirebaseAuth.instance;
    final password = 'test1234'; // 6자 이상 필요
    
    // 1. 관리자 계정 생성
    try {
      final adminEmail = 'admin@mingrr.com';
      final methods = await auth.fetchSignInMethodsForEmail(adminEmail);
      
      if (methods.isEmpty) {
        await auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: 'admin1234',
        );
        print('  ✓ $adminEmail 계정 생성 (관리자)');
      } else {
        print('  ⊚ $adminEmail 계정 이미 존재 (관리자)');
      }
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        print('  ⊚ admin@mingrr.com 계정 이미 존재 (관리자)');
      } else {
        print('  ✗ admin@mingrr.com 계정 생성 실패: $e');
      }
    }
    
    // 2. 테스트 계정 생성 (test1~test10)
    for (int i = 1; i <= 10; i++) {
      final email = 'test$i@mingrr.com';
      
      try {
        // 기존 계정이 있는지 확인
        final methods = await auth.fetchSignInMethodsForEmail(email);
        
        if (methods.isEmpty) {
          // 계정이 없으면 생성
          await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('  ✓ $email 계정 생성');
        } else {
          print('  ⊙ $email 계정 이미 존재');
        }
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          print('  ⊙ $email 계정 이미 존재');
        } else {
          print('  ✗ $email 계정 생성 실패: $e');
        }
      }
    }
    
    // 관리자 계정으로 자동 로그인 (Firestore 쓰기 권한 획듍)
    try {
      await auth.signInWithEmailAndPassword(
        email: 'admin@mingrr.com',
        password: 'admin1234',
      );
      print('  ✓ admin@mingrr.com 계정으로 자동 로그인 (관리자)');
    } catch (e) {
      print('  ✗ 관리자 로그인 실패: $e');
    }
  }
  
  Future<List<String>> _seedUsers() async {
    final userIds = <String>[];
    final now = DateTime.now();
    
    final users = [
      {
        'id': 'user_001',
        'email': 'test1@mingrr.com',
        'nickname': '멍멍이집사',
        'gender': 'female',
        'bio': '우리 강아지 친구 찾아요! 산책 같이 해요 🐕',
        'location': const GeoPoint(37.5665, 126.9780),
        'address': '서울시 중구',
        'isVerified': true,
        'kkosunnaeScore': 85,
      },
      {
        'id': 'user_002',
        'email': 'test2@mingrr.com',
        'nickname': '골든러버',
        'gender': 'male',
        'bio': '골든리트리버 키우고 있어요',
        'location': const GeoPoint(37.4979, 127.0276),
        'address': '서울시 강남구',
        'isVerified': true,
        'kkosunnaeScore': 92,
      },
      {
        'id': 'user_003',
        'email': 'test3@mingrr.com',
        'nickname': '푸들맘',
        'gender': 'female',
        'bio': '토이푸들 두마리 키워요 💕',
        'location': const GeoPoint(37.5172, 127.0473),
        'address': '서울시 송파구',
        'isVerified': true,
        'kkosunnaeScore': 78,
      },
      {
        'id': 'user_004',
        'email': 'test4@mingrr.com',
        'nickname': '웰시코기사랑',
        'gender': 'male',
        'bio': '웰시코기 산책 매일 해요',
        'location': const GeoPoint(37.5219, 126.9245),
        'address': '서울시 마포구',
        'isVerified': true,
        'kkosunnaeScore': 88,
      },
      {
        'id': 'user_005',
        'email': 'test5@mingrr.com',
        'nickname': '시바견집사',
        'gender': 'female',
        'bio': '시바견 키우는 직장인입니다',
        'location': const GeoPoint(37.5326, 126.9910),
        'address': '서울시 용산구',
        'isVerified': false,
        'kkosunnaeScore': 65,
      },
      {
        'id': 'user_006',
        'email': 'test6@mingrr.com',
        'nickname': '비숑프리제맘',
        'gender': 'female',
        'bio': '비숑프리제와 함께하는 행복한 일상 ☁️',
        'location': const GeoPoint(37.4833, 127.0322),
        'address': '서울시 서초구',
        'isVerified': true,
        'kkosunnaeScore': 90,
      },
      {
        'id': 'user_007',
        'email': 'test7@mingrr.com',
        'nickname': '말티즈아빠',
        'gender': 'male',
        'bio': '말티즈 2마리 키우는 아빠입니다',
        'location': const GeoPoint(37.5585, 126.9368),
        'address': '서울시 서대문구',
        'isVerified': true,
        'kkosunnaeScore': 82,
      },
      {
        'id': 'user_008',
        'email': 'test8@mingrr.com',
        'nickname': '포메러버',
        'gender': 'female',
        'bio': '포메라니안 산책 친구 구해요 🐾',
        'location': const GeoPoint(37.5509, 127.0407),
        'address': '서울시 광진구',
        'isVerified': true,
        'kkosunnaeScore': 75,
      },
      {
        'id': 'user_009',
        'email': 'test9@mingrr.com',
        'nickname': '진돗개집사',
        'gender': 'male',
        'bio': '진돗개와 함께 등산 다녀요 🏔️',
        'location': const GeoPoint(37.4954, 126.8882),
        'address': '서울시 구로구',
        'isVerified': false,
        'kkosunnaeScore': 70,
      },
      {
        'id': 'user_010',
        'email': 'test10@mingrr.com',
        'nickname': '슈나우저맘',
        'gender': 'female',
        'bio': '미니어처 슈나우저 키워요',
        'location': const GeoPoint(37.5271, 126.8561),
        'address': '서울시 양천구',
        'isVerified': true,
        'kkosunnaeScore': 88,
      },
    ];
    
    for (final userData in users) {
      final user = UserModel(
        id: userData['id'] as String,
        email: userData['email'] as String,
        nickname: userData['nickname'] as String,
        gender: userData['gender'] == 'male' ? UserGender.male : UserGender.female,
        bio: userData['bio'] as String,
        location: userData['location'] as GeoPoint,
        address: userData['address'] as String,
        homeAddress: userData['address'] as String,
        homeLocation: userData['location'] as GeoPoint,
        loginProvider: 'email',
        isVerified: userData['isVerified'] as bool,
        isIdentityVerified: userData['isVerified'] as bool,
        isLocationVerified: true,
        isWalking: false,
        petIds: [],
        createdAt: now,
        lastActiveAt: now,
        isPremium: false,
        kkosunnaeScore: (userData['kkosunnaeScore'] as int).toDouble(),
        ratingCount: 10,
        homeHealthCategories: [],
        homeSafetyEnabled: false,
      );
      
      await _firebase.usersCollection.doc(user.id).set(user.toFirestore());
      userIds.add(user.id);
    }
    
    return userIds;
  }
  
  Future<void> _seedPets(List<String> userIds) async {
    final now = DateTime.now();
    
    final pets = [
      {
        'id': 'dog_001',
        'ownerId': userIds[0],
        'name': '초코',
        'breed': '포메라니안',
        'gender': 'female',
        'weight': 3.5,
        'isNeutered': true,
        'traits': [PetTrait.active, PetTrait.friendly, PetTrait.affectionate],
        'bio': '사람 좋아하는 초코에요!',
      },
      {
        'id': 'dog_002',
        'ownerId': userIds[1],
        'name': '골디',
        'breed': '골든리트리버',
        'gender': 'male',
        'weight': 28.0,
        'isNeutered': false,
        'traits': [PetTrait.gentle, PetTrait.loyal, PetTrait.lovesPeople],
        'bio': '착한 골디입니다',
      },
      {
        'id': 'dog_003',
        'ownerId': userIds[2],
        'name': '쿠키',
        'breed': '토이푸들',
        'gender': 'female',
        'weight': 2.8,
        'isNeutered': false,
        'traits': [PetTrait.affectionate, PetTrait.playful],
        'bio': '귀여운 쿠키',
      },
      {
        'id': 'dog_004',
        'ownerId': userIds[2],
        'name': '크림',
        'breed': '토이푸들',
        'gender': 'male',
        'weight': 3.2,
        'isNeutered': true,
        'traits': [PetTrait.gentle, PetTrait.calm],
        'bio': '쿠키의 동생 크림이',
      },
      {
        'id': 'dog_005',
        'ownerId': userIds[3],
        'name': '코코',
        'breed': '웰시코기',
        'gender': 'male',
        'weight': 12.5,
        'isNeutered': true,
        'traits': [PetTrait.brave, PetTrait.protective, PetTrait.loyal],
        'bio': '에너지 넘치는 코코',
      },
      {
        'id': 'dog_006',
        'ownerId': userIds[4],
        'name': '시바',
        'breed': '시바견',
        'gender': 'female',
        'weight': 9.0,
        'isNeutered': false,
        'traits': [PetTrait.independent, PetTrait.calm],
        'bio': '도도한 시바',
      },
    ];
    
    for (final petData in pets) {
      final pet = PetModel(
        id: petData['id'] as String,
        ownerId: petData['ownerId'] as String,
        isPrimary: true,
        name: petData['name'] as String,
        breed: petData['breed'] as String,
        gender: petData['gender'] == 'male' ? PetGender.male : PetGender.female,
        weight: petData['weight'] as double,
        isNeutered: petData['isNeutered'] as bool,
        traits: (petData['traits'] as List<PetTrait>),
        bio: petData['bio'] as String,
        isRegistrationVerified: true,
        isVaccinationVerified: true,
        hasPedigree: false,
        isBreedingAvailable: !(petData['isNeutered'] as bool),
        healthBookEnabled: true,
        enabledHealthCategories: [HealthCategory.weight, HealthCategory.vaccination, HealthCategory.walk],
        walkFeatureEnabled: true,
        likeCount: 0,
        createdAt: now,
        updatedAt: now,
        photoUrls: [],
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
        'address': '서울시 마포구 한강공원',
        'isPublic': true,
        'maxMembers': 20,
      },
      {
        'creatorId': userIds[1],
        'name': '대형견 놀이터',
        'description': '대형견들끼리 모여서 놀아요',
        'type': 'social',
        'location': const GeoPoint(37.4979, 127.0276),
        'address': '서울시 강남구',
        'isPublic': true,
        'maxMembers': 15,
      },
      {
        'creatorId': userIds[2],
        'name': '강아지 훈련 스터디',
        'description': '같이 훈련 방법 공유하고 연습해요',
        'type': 'training',
        'location': const GeoPoint(37.5172, 127.0473),
        'address': '서울시 송파구',
        'isPublic': true,
        'maxMembers': 10,
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
        createdAt: now,
        updatedAt: now,
      );
      
      await _firebase.groupsCollection.doc(group.id).set(group.toFirestore());
    }
  }
  
  Future<void> clearAllData() async {
    print('🗑️  모든 데이터 삭제 시작...');
    
    try {
      // Firestore 데이터 삭제 (users 컬렉션은 제외 - 로그인 세션 유지를 위해)
      await _clearCollection(_firebase.petsCollection);
      await _clearCollection(_firebase.productsCollection);
      await _clearCollection(_firebase.groupsCollection);
      await _clearCollection(_firebase.chatRoomsCollection);
      await _clearCollection(_firebase.likesCollection);
      await _clearCollection(_firebase.matchesCollection);
      await _clearCollection(_firebase.jobsCollection);
      
      print('✅ 모든 Firestore 데이터 삭제 완료 (users 컬렉션 제외)');
    } catch (e) {
      print('❌ 데이터 삭제 실패: $e');
      rethrow;
    }
  }
  
  Future<void> _clearCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    final batch = _firebase.firestore.batch();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  
  // ===== 항목별 생성 메서드 =====
  
  /// 사용자 데이터만 생성
  Future<void> seedUsers() async {
    await _createTestAccounts();
    await _seedUsers();
  }
  
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
    // TODO: 좋아요/매칭 테스트 데이터 생성 로직 구현 예정
  }
  
  Future<void> _seedChats(List<String> userIds) async {
    // TODO: 채팅 테스트 데이터 생성 로직 구현 예정
  }
}
