import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../../models/breeding_model.dart';
import '../../models/rating_model.dart';
import '../../models/community_post_model.dart' as community;
import '../services/firebase_service.dart';
import '../constants/pet_constants.dart';

/// 테스트 데이터 ID 접두사 - 이 접두사로 시작하는 데이터만 테스트 데이터로 인식
class TestDataPrefix {
  static const String pet = 'test_pet_';
  static const String product = 'test_product_';
  static const String group = 'test_group_';
  static const String job = 'test_job_';
  static const String breeding = 'test_breeding_';
  static const String like = 'test_like_';
  static const String match = 'test_match_';
  static const String chat = 'test_chat_';
  static const String message = 'test_msg_';
  static const String rating = 'test_rating_';
  static const String user = 'test_user_';
  static const String feedPost = 'test_feed_';
  static const String schedule = 'test_schedule_';
  static const String comment = 'test_comment_';
}

class SeedData {
  final FirebaseService _firebase = FirebaseService();
  
  // 샘플 이미지 URL
  static const _storageBaseUrl = 'https://firebasestorage.googleapis.com/v0/b/mingrr.firebasestorage.app/o';
  static final sampleImages = [
    '$_storageBaseUrl/pets%2Fsample%2Fdog1.jpg?alt=media',
    '$_storageBaseUrl/pets%2Fsample%2Fdog2.jpg?alt=media',
    '$_storageBaseUrl/pets%2Fsample%2Fdog3.jpg?alt=media',
    '$_storageBaseUrl/pets%2Fsample%2Fdog4.jpg?alt=media',
    '$_storageBaseUrl/pets%2Fsample%2Fdog5.jpg?alt=media',
    '$_storageBaseUrl/pets%2Fsample%2Fdog6.jpg?alt=media',
  ];
  
  Future<void> seedAll() async {
    print('🌱 더미 데이터 생성 시작...');
    
    try {
      // 테스트 사용자 먼저 생성 (다른 사용자 펫 표시를 위해 필수)
      await seedTestUsers();
      
      // 기존 사용자 ID 가져오기
      final userIds = await _getExistingUserIds();
      if (userIds.isEmpty) {
        throw Exception('사용자 데이터가 없습니다. 먼저 회원가입을 해주세요.');
      }
      print('✅ 사용자 ${userIds.length}명 확인');
      
      // 사용자 위치 정보 업데이트 (거리 기반 기능에 필수)
      await seedUserLocations();
      print('✅ 사용자 위치 정보 생성 완료');
      
      await _seedPets(userIds);
      print('✅ 반려동물 데이터 생성 완료');
      
      // 교배글 생성 (펫 데이터 생성 후 호출해야 함)
      await _seedBreedingPosts(userIds);
      print('✅ 교배글 데이터 생성 완료');
      
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
    
    // 다양한 견종, 성별, 나이, 성격 조합의 테스트 데이터 (25마리)
    final petDataList = [
      // 소형견 (10마리)
      {'name': '초코', 'breed': '포메라니안', 'gender': 'female', 'weight': 3.5, 'ageDays': 365 * 2, 'neutered': true, 'traits': [PetTrait.active, PetTrait.friendly, PetTrait.affectionate], 'bio': '사람 좋아하는 초코에요! 산책을 좋아해요', 'hasProfile': true, 'photoCount': 3},
      {'name': '쿠키', 'breed': '토이푸들', 'gender': 'female', 'weight': 2.8, 'ageDays': 365, 'neutered': false, 'traits': [PetTrait.affectionate, PetTrait.playful, PetTrait.smart], 'bio': '귀여운 쿠키, 재롱 부리는 걸 좋아해요. 혈통서 있어요!', 'hasProfile': true, 'photoCount': 4},
      {'name': '뭉치', 'breed': '비숑프리제', 'gender': 'male', 'weight': 5.5, 'ageDays': 365 * 5, 'neutered': true, 'traits': [PetTrait.friendly, PetTrait.playful, PetTrait.lovesPeople], 'bio': '모든 강아지와 친하게 지내요', 'hasProfile': false, 'photoCount': 1},
      {'name': '하양이', 'breed': '말티즈', 'gender': 'female', 'weight': 2.5, 'ageDays': 365 * 7, 'neutered': true, 'traits': [PetTrait.shy, PetTrait.calm, PetTrait.affectionate], 'bio': '조용한 산책을 좋아하는 하양이', 'hasProfile': true, 'photoCount': 2},
      {'name': '뽀미', 'breed': '포메라니안', 'gender': 'male', 'weight': 4.0, 'ageDays': 365, 'neutered': false, 'traits': [PetTrait.active, PetTrait.playful, PetTrait.brave], 'bio': '활발한 뽀미, 같이 뛰어놀 친구 찾아요', 'hasProfile': false, 'photoCount': 0},
      {'name': '치치', 'breed': '치와와', 'gender': 'male', 'weight': 1.8, 'ageDays': 365 * 4, 'neutered': true, 'traits': [PetTrait.shy, PetTrait.affectionate, PetTrait.protective], 'bio': '작지만 용감한 치치', 'hasProfile': true, 'photoCount': 0},
      {'name': '크림', 'breed': '토이푸들', 'gender': 'male', 'weight': 3.2, 'ageDays': 180, 'neutered': false, 'traits': [PetTrait.gentle, PetTrait.calm, PetTrait.shy], 'bio': '쿠키의 동생 크림이, 낯가림이 있어요', 'hasProfile': false, 'photoCount': 0},
      {'name': '몽이', 'breed': '말티푸', 'gender': 'female', 'weight': 3.8, 'ageDays': 365 * 2, 'neutered': false, 'traits': [PetTrait.smart, PetTrait.playful, PetTrait.affectionate], 'bio': '똑똒하고 애교 많은 몽이입니다', 'hasProfile': true, 'photoCount': 3},
      {'name': '콩이', 'breed': '요크셔테리어', 'gender': 'male', 'weight': 2.2, 'ageDays': 365 * 3, 'neutered': true, 'traits': [PetTrait.brave, PetTrait.active, PetTrait.loyal], 'bio': '작은 거인 콩이! 산책을 좋아해요', 'hasProfile': false, 'photoCount': 2},
      {'name': '두부', 'breed': '시츄', 'gender': 'female', 'weight': 4.5, 'ageDays': 365 * 4, 'neutered': true, 'traits': [PetTrait.calm, PetTrait.gentle, PetTrait.lovesPeople], 'bio': '순둥순둥 두부, 무릎 위가 제일 좋아요', 'hasProfile': true, 'photoCount': 1},
      
      // 중형견 (8마리)
      {'name': '코코', 'breed': '웰시코기', 'gender': 'male', 'weight': 12.5, 'ageDays': 365 * 4, 'neutered': true, 'traits': [PetTrait.brave, PetTrait.protective, PetTrait.loyal, PetTrait.active], 'bio': '에너지 넘치는 코코, 산책 많이 해야해요', 'hasProfile': true, 'photoCount': 4},
      {'name': '시바', 'breed': '시바견', 'gender': 'female', 'weight': 9.0, 'ageDays': 365 * 2 + 180, 'neutered': false, 'traits': [PetTrait.independent, PetTrait.calm, PetTrait.smart], 'bio': '도도한 시바, 자기만의 시간이 필요해요', 'hasProfile': false, 'photoCount': 0},
      {'name': '슈슈', 'breed': '미니어처 슈나우저', 'gender': 'female', 'weight': 7.0, 'ageDays': 365 * 2, 'neutered': true, 'traits': [PetTrait.smart, PetTrait.active, PetTrait.friendly], 'bio': '똑똑한 슈슈, 훈련을 잘 받아요', 'hasProfile': true, 'photoCount': 3},
      {'name': '비비', 'breed': '비글', 'gender': 'female', 'weight': 10.0, 'ageDays': 365 + 180, 'neutered': false, 'traits': [PetTrait.friendly, PetTrait.active, PetTrait.playful], 'bio': '호기심 많은 비비, 냄새 맡는 걸 좋아해요', 'hasProfile': true, 'photoCount': 3},
      {'name': '보리', 'breed': '코카스파니엘', 'gender': 'male', 'weight': 11.0, 'ageDays': 365 * 3, 'neutered': false, 'traits': [PetTrait.gentle, PetTrait.friendly, PetTrait.playful], 'bio': '사람을 너무 좋아하는 보리입니다', 'hasProfile': false, 'photoCount': 2},
      {'name': '단비', 'breed': '스피츠', 'gender': 'female', 'weight': 8.5, 'ageDays': 365 * 2, 'neutered': true, 'traits': [PetTrait.active, PetTrait.smart, PetTrait.loyal], 'bio': '하얀 솜사탕 같은 단비에요', 'hasProfile': true, 'photoCount': 4},
      {'name': '까미', 'breed': '보더콜리', 'gender': 'male', 'weight': 15.0, 'ageDays': 365 * 1 + 180, 'neutered': false, 'traits': [PetTrait.smart, PetTrait.active, PetTrait.loyal, PetTrait.playful], 'bio': '원반 던지기 좋아하는 까미! 에너지가 넘쳐요', 'hasProfile': true, 'photoCount': 5},
      {'name': '호두', 'breed': '푸들 (미디엄)', 'gender': 'female', 'weight': 9.5, 'ageDays': 365 * 4, 'neutered': true, 'traits': [PetTrait.smart, PetTrait.gentle, PetTrait.affectionate], 'bio': '영리하고 우아한 호두입니다', 'hasProfile': false, 'photoCount': 1},
      
      // 대형견 (7마리)
      {'name': '골디', 'breed': '골든리트리버', 'gender': 'male', 'weight': 28.0, 'ageDays': 365 * 3, 'neutered': false, 'traits': [PetTrait.gentle, PetTrait.loyal, PetTrait.lovesPeople], 'bio': '착한 골디입니다. 아이들과 잘 놀아요. 혈통서 보유!', 'hasProfile': true, 'photoCount': 5},
      {'name': '백구', 'breed': '진돗개', 'gender': 'male', 'weight': 22.0, 'ageDays': 365 * 3, 'neutered': false, 'traits': [PetTrait.loyal, PetTrait.protective, PetTrait.brave, PetTrait.independent], 'bio': '충성스러운 백구, 등산 좋아해요', 'hasProfile': false, 'photoCount': 2},
      {'name': '래브', 'breed': '래브라도 리트리버', 'gender': 'female', 'weight': 25.0, 'ageDays': 365 * 6, 'neutered': true, 'traits': [PetTrait.gentle, PetTrait.calm, PetTrait.lovesPeople], 'bio': '온순한 래브, 물놀이를 좋아해요', 'hasProfile': false, 'photoCount': 0},
      {'name': '하늘이', 'breed': '시베리안 허스키', 'gender': 'male', 'weight': 23.0, 'ageDays': 365 * 2, 'neutered': false, 'traits': [PetTrait.independent, PetTrait.active, PetTrait.playful], 'bio': '달리기를 좋아하는 하늘이', 'hasProfile': false, 'photoCount': 2},
      {'name': '맥스', 'breed': '저먼셰퍼드', 'gender': 'male', 'weight': 32.0, 'ageDays': 365 * 4, 'neutered': true, 'traits': [PetTrait.loyal, PetTrait.protective, PetTrait.smart, PetTrait.brave], 'bio': '훈련받은 맥스, 가족을 지켜줘요', 'hasProfile': true, 'photoCount': 3},
      {'name': '루나', 'breed': '사모예드', 'gender': 'female', 'weight': 20.0, 'ageDays': 365 * 2, 'neutered': false, 'traits': [PetTrait.friendly, PetTrait.playful, PetTrait.gentle, PetTrait.lovesPeople], 'bio': '웃는 천사 루나! 모든 사람을 좋아해요', 'hasProfile': true, 'photoCount': 4},
      {'name': '제우스', 'breed': '그레이트데인', 'gender': 'male', 'weight': 55.0, 'ageDays': 365 * 3, 'neutered': true, 'traits': [PetTrait.gentle, PetTrait.calm, PetTrait.loyal], 'bio': '거대하지만 순한 제우스입니다', 'hasProfile': false, 'photoCount': 2},
    ];
    
    // 테스트 펫은 첫 번째 사용자(현재 로그인 사용자)가 아닌 다른 사용자에게 할당
    // 이렇게 해야 교배찾기에서 "다른 사용자의 펫"으로 표시됨
    final otherUserIds = userIds.length > 1 
        ? userIds.sublist(1)  // 첫 번째 사용자 제외
        : userIds;  // 사용자가 1명뿐이면 그대로 사용
    
    for (int i = 0; i < petDataList.length; i++) {
      final data = petDataList[i];
      final ownerId = otherUserIds[i % otherUserIds.length];
      final petId = '${TestDataPrefix.pet}${(i + 1).toString().padLeft(3, '0')}';
      
      // 이미지 설정
      final hasProfile = data['hasProfile'] as bool;
      final photoCount = data['photoCount'] as int;
      final profileImage = hasProfile ? sampleImages[i % sampleImages.length] : null;
      final photos = <String>[];
      for (int j = 0; j < photoCount; j++) {
        photos.add(sampleImages[(i + j) % sampleImages.length]);
      }
      
      final pet = PetModel(
        id: petId,
        ownerId: ownerId,
        isPrimary: i % 3 == 0, // 3개 중 1개만 대표
        name: data['name'] as String,
        breed: data['breed'] as String,
        birthDate: now.subtract(Duration(days: data['ageDays'] as int)),
        gender: data['gender'] == 'male' ? PetGender.male : PetGender.female,
        weight: data['weight'] as double,
        isNeutered: data['neutered'] as bool,
        traits: List<PetTrait>.from(data['traits'] as List),
        bio: data['bio'] as String,
        profileImageUrl: profileImage,
        photoUrls: photos,
        isRegistrationVerified: i % 2 == 0,
        isVaccinationVerified: i % 3 == 0,
        hasPedigree: i % 5 == 0,
        isBreedingAvailable: !(data['neutered'] as bool),
        healthBookEnabled: true,
        enabledHealthCategories: [HealthCategory.weight, HealthCategory.vaccination, HealthCategory.walk],
        walkFeatureEnabled: true,
        likeCount: (i + 1) * 3,
        createdAt: now.subtract(Duration(days: i * 2)),
        updatedAt: now,
      );
      
      await _firebase.petsCollection.doc(pet.id).set(pet.toFirestore());
    }
    print('  ✓ 반려동물 ${petDataList.length}마리 생성 완료');
  }
  
  Future<void> _seedProducts(List<String> userIds) async {
    final now = DateTime.now();
    
    // 다양한 상품 데이터 (판매/나눔, 다양한 카테고리, 가격대)
    final productDataList = [
      {'title': '강아지 옷 (소형견용)', 'desc': '한번도 안입은 새상품입니다. 사이즈가 안맞아서 팔아요.', 'price': 15000, 'type': 'sell', 'category': 'clothes', 'lat': 37.5665, 'lng': 126.9780, 'address': '서울시 중구'},
      {'title': '강아지 사료 나눔', 'desc': '우리 강아지가 안먹어서 나눔합니다. 유통기한 충분해요.', 'price': 0, 'type': 'share', 'category': 'food', 'lat': 37.4979, 'lng': 127.0276, 'address': '서울시 강남구'},
      {'title': '강아지 장난감 세트', 'desc': '거의 새것입니다. 5개 세트로 판매해요.', 'price': 20000, 'type': 'sell', 'category': 'toys', 'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 송파구'},
      {'title': '강아지 이동장 (중형견)', 'desc': '깨끗하게 사용했습니다. 직거래 선호', 'price': 50000, 'type': 'sell', 'category': 'supplies', 'lat': 37.5219, 'lng': 126.9245, 'address': '서울시 마포구'},
      {'title': '강아지 목줄 나눔', 'desc': '사이즈가 안맞아서 나눔합니다', 'price': 0, 'type': 'share', 'category': 'supplies', 'lat': 37.5326, 'lng': 126.9910, 'address': '서울시 용산구'},
      {'title': '프리미엄 사료 로얄캐닌 3kg', 'desc': '개봉했지만 거의 안먹었어요. 반값에 드려요.', 'price': 25000, 'type': 'sell', 'category': 'food', 'lat': 37.5045, 'lng': 127.0498, 'address': '서울시 강남구'},
      {'title': '강아지 방석 (대형)', 'desc': '세탁 완료! 깨끗합니다.', 'price': 30000, 'type': 'sell', 'category': 'supplies', 'lat': 37.5662, 'lng': 126.9784, 'address': '서울시 종로구'},
      {'title': '간식 모음 나눔', 'desc': '유통기한 임박이라 나눔해요', 'price': 0, 'type': 'share', 'category': 'food', 'lat': 37.5133, 'lng': 127.1001, 'address': '서울시 강동구'},
      {'title': '강아지 유모차', 'desc': '노령견용으로 구매했는데 안써서 팔아요', 'price': 80000, 'type': 'sell', 'category': 'supplies', 'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 송파구'},
      {'title': '겨울 패딩 조끼', 'desc': '따뜻한 패딩 조끼입니다. S사이즈', 'price': 25000, 'type': 'sell', 'category': 'clothes', 'lat': 37.5219, 'lng': 126.9245, 'address': '서울시 마포구'},
      {'title': '터그 장난감 나눔', 'desc': '새상품인데 우리 강아지가 안좋아해요', 'price': 0, 'type': 'share', 'category': 'toys', 'lat': 37.5665, 'lng': 126.9780, 'address': '서울시 중구'},
      {'title': '자동 급식기', 'desc': '타이머 설정 가능, 정상 작동합니다', 'price': 45000, 'type': 'sell', 'category': 'supplies', 'lat': 37.4979, 'lng': 127.0276, 'address': '서울시 강남구'},
      {'title': '강아지 샴푸 세트', 'desc': '피부가 예민한 아이용 저자극 샴푸', 'price': 18000, 'type': 'sell', 'category': 'supplies', 'lat': 37.5326, 'lng': 126.9910, 'address': '서울시 용산구'},
      {'title': '레인코트 (중형견)', 'desc': '비오는 날 산책용, 거의 새것', 'price': 20000, 'type': 'sell', 'category': 'clothes', 'lat': 37.5045, 'lng': 127.0498, 'address': '서울시 강남구'},
      {'title': '노즈워크 매트 나눔', 'desc': '사용감 있지만 아직 쓸만해요', 'price': 0, 'type': 'share', 'category': 'toys', 'lat': 37.5662, 'lng': 126.9784, 'address': '서울시 종로구'},
    ];
    
    for (int i = 0; i < productDataList.length; i++) {
      final data = productDataList[i];
      final productId = '${TestDataPrefix.product}${(i + 1).toString().padLeft(3, '0')}';
      
      final product = ProductModel(
        id: productId,
        sellerId: userIds[i % userIds.length],
        title: data['title'] as String,
        description: data['desc'] as String,
        price: data['price'] as int,
        type: data['type'] == 'sell' ? ProductType.sell : ProductType.share,
        category: ProductCategory.values.firstWhere((e) => e.name == data['category']),
        status: i % 5 == 0 ? ProductStatus.reserved : ProductStatus.available,
        imageUrls: [sampleImages[i % sampleImages.length]],
        location: GeoPoint(data['lat'] as double, data['lng'] as double),
        address: data['address'] as String,
        viewCount: (i + 1) * 8,
        likeCount: (i + 1) * 2,
        chatCount: i % 3,
        createdAt: now.subtract(Duration(days: i)),
        updatedAt: now,
      );
      
      await _firebase.productsCollection.doc(product.id).set(product.toFirestore());
    }
    print('  ✓ 상품 ${productDataList.length}개 생성 완료');
  }
  
  Future<void> _seedGroups(List<String> userIds) async {
    final now = DateTime.now();
    
    // 다양한 소모임 데이터 (다양한 타입, 지역, 멤버 수) - 20개
    final groupDataList = [
      {'name': '한강 산책 모임', 'desc': '매주 주말 한강에서 산책해요! 소형견 환영\n\n🕐 매주 토요일 오전 10시\n📍 여의도 한강공원\n\n함께 산책하며 친목 다져요!', 'type': 'walking', 'lat': 37.5219, 'lng': 126.9245, 'address': '서울시 마포구', 'maxMembers': 20, 'likeCount': 45, 'isPetAccompanied': true, 'tags': ['산책', '한강', '소형견']},
      {'name': '대형견 놀이터', 'desc': '대형견들끼리 모여서 놀아요!\n\n골든, 래브라도, 허스키 등 대형견 보호자 모임입니다.\n넓은 공간에서 마음껏 뛰어놀 수 있어요.', 'type': 'social', 'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 강남구', 'maxMembers': 15, 'likeCount': 32, 'isPetAccompanied': true, 'tags': ['대형견', '놀이터', '친목']},
      {'name': '강아지 훈련 스터디', 'desc': '같이 훈련 방법 공유하고 연습해요\n\n기본 훈련부터 고급 훈련까지!\n전문 트레이너 초청 강의도 있어요.', 'type': 'training', 'lat': 37.5145, 'lng': 127.1066, 'address': '서울시 송파구', 'maxMembers': 10, 'likeCount': 18, 'isPetAccompanied': true, 'tags': ['훈련', '교육', '스터디']},
      {'name': '분당 댕댕이 모임', 'desc': '분당 지역 반려견 친목 모임입니다\n\n매월 정기 모임 진행\n다양한 이벤트와 정보 공유!', 'type': 'social', 'lat': 37.3825, 'lng': 127.1188, 'address': '경기도 성남시 분당구', 'maxMembers': 25, 'likeCount': 28, 'isPetAccompanied': true, 'tags': ['분당', '친목', '정기모임']},
      {'name': '용인 산책 친구들', 'desc': '용인 지역에서 함께 산책해요\n\n에버랜드 근처 산책로 탐방\n주말 오전 정기 산책', 'type': 'walking', 'lat': 37.2346, 'lng': 127.2090, 'address': '경기도 용인시 처인구', 'maxMembers': 15, 'likeCount': 12, 'isPetAccompanied': true, 'tags': ['용인', '산책', '주말']},
      {'name': '수제 간식 만들기', 'desc': '건강한 수제 간식 함께 만들어요\n\n🍪 매월 2회 간식 만들기 모임\n📚 레시피 공유\n\n반려동물 동반 없이 보호자만 참여해요!', 'type': 'craft', 'lat': 37.4837, 'lng': 127.0324, 'address': '서울시 서초구', 'maxMembers': 8, 'likeCount': 55, 'isPetAccompanied': false, 'tags': ['수제간식', '요리', '레시피']},
      {'name': '시니어 반려견 케어', 'desc': '노령견 케어 정보 공유 모임\n\n10살 이상 노령견 보호자 모임\n건강관리, 영양, 케어 팁 공유', 'type': 'health', 'lat': 37.5663, 'lng': 126.9014, 'address': '서울시 마포구', 'maxMembers': 20, 'likeCount': 38, 'isPetAccompanied': false, 'tags': ['노령견', '건강', '케어']},
      {'name': '포메라니안 모임', 'desc': '포메 보호자들의 정보 공유 모임\n\n🐕 포메라니안 전용 모임\n털 관리, 건강 정보 공유\n정기 오프라인 모임', 'type': 'social', 'lat': 37.5665, 'lng': 126.9780, 'address': '서울시 중구', 'maxMembers': 30, 'likeCount': 62, 'isPetAccompanied': true, 'tags': ['포메라니안', '품종모임', '정보공유']},
      {'name': '반려견 수영 클럽', 'desc': '물놀이 좋아하는 강아지들 모여라!\n\n🏊 수영장 대관 모임\n여름철 물놀이 이벤트', 'type': 'social', 'lat': 37.4979, 'lng': 127.0276, 'address': '서울시 강남구', 'maxMembers': 12, 'likeCount': 41, 'isPetAccompanied': true, 'tags': ['수영', '물놀이', '여름']},
      {'name': '애견카페 투어', 'desc': '매주 다른 애견카페 탐방해요\n\n☕ 서울 애견카페 투어\n📸 인증샷 이벤트\n리뷰 공유', 'type': 'social', 'lat': 37.5326, 'lng': 126.9910, 'address': '서울시 용산구', 'maxMembers': 10, 'likeCount': 29, 'isPetAccompanied': true, 'tags': ['애견카페', '투어', '맛집']},
      {'name': '반려견 사진 동호회', 'desc': '예쁜 사진 찍고 공유해요\n\n📷 사진 촬영 팁 공유\n월 1회 출사 모임\n사진 콘테스트 진행', 'type': 'social', 'lat': 37.5045, 'lng': 127.0498, 'address': '서울시 강남구', 'maxMembers': 15, 'likeCount': 35, 'isPetAccompanied': true, 'tags': ['사진', '출사', '동호회']},
      {'name': '새벽 산책 모임', 'desc': '아침 6시 새벽 산책 함께해요\n\n🌅 매일 아침 6시\n조용한 새벽 산책\n건강한 하루 시작!', 'type': 'walking', 'lat': 37.5662, 'lng': 126.9784, 'address': '서울시 종로구', 'maxMembers': 8, 'likeCount': 15, 'isPetAccompanied': true, 'tags': ['새벽', '산책', '아침']},
      {'name': '반려견 요가', 'desc': '강아지와 함께하는 도가 요가\n\n🧘 도가(Doga) 요가 클래스\n반려견과 함께 힐링\n초보자 환영!', 'type': 'social', 'lat': 37.5133, 'lng': 127.1001, 'address': '서울시 강동구', 'maxMembers': 10, 'likeCount': 22, 'isPetAccompanied': true, 'tags': ['요가', '힐링', '운동']},
      {'name': '퍼피 플레이데이트', 'desc': '1살 미만 퍼피들의 사회화 모임\n\n🐶 퍼피 전용 모임\n사회화 훈련\n또래 친구 만들기', 'type': 'social', 'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 송파구', 'maxMembers': 15, 'likeCount': 48, 'isPetAccompanied': true, 'tags': ['퍼피', '사회화', '플레이']},
      {'name': '반려견 미용 스터디', 'desc': '셀프 미용 배우고 연습해요\n\n✂️ 셀프 미용 강좌\n발톱 깎기, 귀 청소 등\n전문가 초청 강의', 'type': 'craft', 'lat': 37.5219, 'lng': 126.9245, 'address': '서울시 마포구', 'maxMembers': 8, 'likeCount': 19, 'isPetAccompanied': false, 'tags': ['미용', '셀프', '스터디']},
      {'name': '코기 러버스', 'desc': '웰시코기 보호자 모임\n\n🐕 코기 전용 모임\n엉덩이 자랑 대회(?)\n정보 공유 및 친목', 'type': 'social', 'lat': 37.5500, 'lng': 126.9500, 'address': '서울시 서대문구', 'maxMembers': 20, 'likeCount': 55, 'isPetAccompanied': true, 'tags': ['웰시코기', '품종모임', '친목']},
      {'name': '반려견 영양학 스터디', 'desc': '반려견 영양에 대해 공부해요\n\n📚 영양학 기초부터\n사료 분석, 영양제 정보\n수의사 초청 강의', 'type': 'health', 'lat': 37.4800, 'lng': 127.0400, 'address': '서울시 서초구', 'maxMembers': 12, 'likeCount': 28, 'isPetAccompanied': false, 'tags': ['영양', '건강', '스터디']},
      {'name': '야간 산책 모임', 'desc': '퇴근 후 함께 산책해요\n\n🌙 평일 저녁 8시\n야경 보며 산책\n직장인 환영!', 'type': 'walking', 'lat': 37.5100, 'lng': 127.0600, 'address': '서울시 강남구', 'maxMembers': 15, 'likeCount': 33, 'isPetAccompanied': true, 'tags': ['야간', '산책', '직장인']},
      {'name': '푸들 동호회', 'desc': '푸들 보호자 모임\n\n토이, 미니, 스탠다드 모두 환영!\n미용 정보, 건강 정보 공유\n정기 오프라인 모임', 'type': 'social', 'lat': 37.5300, 'lng': 127.0000, 'address': '서울시 성동구', 'maxMembers': 25, 'likeCount': 42, 'isPetAccompanied': true, 'tags': ['푸들', '품종모임', '정보공유']},
      {'name': '반려견 응급처치 교육', 'desc': '응급상황 대처법을 배워요\n\n🏥 응급처치 기초\n심폐소생술, 지혈법 등\n수의사 직강!', 'type': 'health', 'lat': 37.5400, 'lng': 126.9700, 'address': '서울시 용산구', 'maxMembers': 15, 'likeCount': 36, 'isPetAccompanied': false, 'tags': ['응급처치', '교육', '건강']},
    ];
    
    for (int i = 0; i < groupDataList.length; i++) {
      final data = groupDataList[i];
      final creatorId = userIds[i % userIds.length];
      final groupId = '${TestDataPrefix.group}${(i + 1).toString().padLeft(3, '0')}';
      
      final group = GroupModel(
        id: groupId,
        name: data['name'] as String,
        description: data['desc'] as String,
        type: GroupType.values.firstWhere((e) => e.name == data['type'], orElse: () => GroupType.social),
        creatorId: creatorId,
        adminIds: [creatorId],
        memberIds: [creatorId, userIds[(i + 1) % userIds.length], userIds[(i + 2) % userIds.length]],
        maxMembers: data['maxMembers'] as int,
        location: GeoPoint(data['lat'] as double, data['lng'] as double),
        address: data['address'] as String,
        imageUrl: sampleImages[i % sampleImages.length],
        isPublic: i % 4 != 0, // 4개 중 1개는 비공개
        requireApproval: i % 3 == 0, // 3개 중 1개는 승인 필요
        isPetAccompanied: data['isPetAccompanied'] as bool,
        tags: List<String>.from(data['tags'] as List),
        likeCount: data['likeCount'] as int,
        createdAt: now.subtract(Duration(days: i * 3)),
        updatedAt: now,
      );
      
      await _firebase.groupsCollection.doc(group.id).set(group.toFirestore());
    }
    print('  ✓ 소모임 ${groupDataList.length}개 생성 완료');
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
      await _clearCollection(_firebase.datingRequestsCollection);
      await _clearCollection(_firebase.matchesCollection);
      await _clearCollection(_firebase.jobsCollection);
      await _clearCollection(_firebase.breedingPostsCollection);
      await _clearCollection(_firebase.ratingsCollection);
      await _clearCollection(_firebase.firestore.collection('transactionStatuses'));
      
      print('✅ 모든 Firestore 데이터 삭제 완료 (users 컬렉션 제외)');
    } catch (e) {
      print('❌ 데이터 삭제 실패: $e');
      rethrow;
    }
  }
  
  /// 테스트 데이터만 삭제 (test_ 접두사로 시작하는 문서만 삭제)
  Future<void> clearTestDataOnly() async {
    print('🧹 테스트 데이터만 삭제 시작...');
    
    try {
      int deletedCount = 0;
      
      // 반려동물
      deletedCount += await _clearTestDataFromCollection(_firebase.petsCollection, TestDataPrefix.pet);
      
      // 상품
      deletedCount += await _clearTestDataFromCollection(_firebase.productsCollection, TestDataPrefix.product);
      
      // 소모임
      deletedCount += await _clearTestDataFromCollection(_firebase.groupsCollection, TestDataPrefix.group);
      
      // 알바
      deletedCount += await _clearTestDataFromCollection(_firebase.jobsCollection, TestDataPrefix.job);
      
      // 교배
      deletedCount += await _clearTestDataFromCollection(_firebase.breedingPostsCollection, TestDataPrefix.breeding);
      
      // 좋아요
      deletedCount += await _clearTestDataFromCollection(_firebase.datingRequestsCollection, TestDataPrefix.like);
      
      // 매칭
      deletedCount += await _clearTestDataFromCollection(_firebase.matchesCollection, TestDataPrefix.match);
      
      // 채팅방 (메시지 서브컬렉션 포함)
      deletedCount += await _clearChatRoomsWithMessages(TestDataPrefix.chat);
      
      // 평가
      deletedCount += await _clearTestDataFromCollection(_firebase.ratingsCollection, TestDataPrefix.rating);
      
      // 테스트 사용자
      deletedCount += await _clearTestDataFromCollection(_firebase.usersCollection, TestDataPrefix.user);
      
      // 커뮤니티 게시글
      deletedCount += await _clearTestDataFromCollection(_firebase.feedPostsCollection, TestDataPrefix.feedPost);
      
      // 일정
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('schedules'), TestDataPrefix.schedule);
      
      // 건강수첩 데이터
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('weightRecords'), 'weight_${TestDataPrefix.pet}');
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('walkRecords'), 'walk_${TestDataPrefix.pet}');
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('groomingRecords'), 'grooming_${TestDataPrefix.pet}');
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('vaccinationRecords'), 'vaccine_${TestDataPrefix.pet}');
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('checkupRecords'), 'checkup_${TestDataPrefix.pet}');
      deletedCount += await _clearTestDataFromCollection(_firebase.firestore.collection('medicationRecords'), 'med_${TestDataPrefix.pet}');
      
      print('✅ 테스트 데이터 $deletedCount개 삭제 완료');
    } catch (e) {
      print('❌ 테스트 데이터 삭제 실패: $e');
      rethrow;
    }
  }
  
  /// 특정 접두사로 시작하는 문서만 삭제
  Future<int> _clearTestDataFromCollection(CollectionReference collection, String prefix) async {
    final snapshot = await collection.get();
    int deletedCount = 0;
    
    final batch = _firebase.firestore.batch();
    for (final doc in snapshot.docs) {
      if (doc.id.startsWith(prefix)) {
        batch.delete(doc.reference);
        deletedCount++;
      }
    }
    
    if (deletedCount > 0) {
      await batch.commit();
    }
    
    return deletedCount;
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
  
  /// 채팅방과 메시지 서브컬렉션 함께 삭제 (테스트 데이터만)
  Future<int> _clearChatRoomsWithMessages(String prefix) async {
    int deletedCount = 0;
    
    // 테스트 채팅방 조회
    final chatRoomsSnapshot = await _firebase.chatRoomsCollection.get();
    
    for (final chatDoc in chatRoomsSnapshot.docs) {
      if (chatDoc.id.startsWith(prefix)) {
        // 서브컬렉션 메시지 먼저 삭제
        final messagesSnapshot = await _firebase.messagesCollection(chatDoc.id).get();
        for (final msgDoc in messagesSnapshot.docs) {
          await msgDoc.reference.delete();
          deletedCount++;
        }
        // 채팅방 삭제
        await chatDoc.reference.delete();
        deletedCount++;
      }
    }
    
    return deletedCount;
  }
  
  // ===== 항목별 생성 메서드 =====
  
  /// 기존 사용자들에게 다양한 위치 정보 부여
  Future<void> seedUserLocations() async {
    print('📍 사용자 위치 정보 생성 시작...');
    
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      print('❌ 사용자 데이터가 없습니다.');
      return;
    }
    
    // 대한민국 주요 도시 위치 (서울, 경기, 부산, 대구, 인천, 광주, 대전, 울산, 제주 등)
    final locations = [
      // 서울
      {'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 강남구'},
      {'lat': 37.5665, 'lng': 126.9780, 'address': '서울시 중구'},
      {'lat': 37.5219, 'lng': 126.9245, 'address': '서울시 마포구'},
      {'lat': 37.4979, 'lng': 127.0276, 'address': '서울시 서초구'},
      {'lat': 37.5326, 'lng': 126.9910, 'address': '서울시 용산구'},
      {'lat': 37.5662, 'lng': 126.9784, 'address': '서울시 종로구'},
      {'lat': 37.5133, 'lng': 127.1001, 'address': '서울시 강동구'},
      {'lat': 37.5045, 'lng': 127.0498, 'address': '서울시 송파구'},
      {'lat': 37.5500, 'lng': 126.9500, 'address': '서울시 서대문구'},
      {'lat': 37.5300, 'lng': 127.0000, 'address': '서울시 성동구'},
      // 경기도
      {'lat': 37.3825, 'lng': 127.1188, 'address': '경기도 성남시 분당구'},
      {'lat': 37.2346, 'lng': 127.2090, 'address': '경기도 용인시'},
      {'lat': 37.4138, 'lng': 127.5183, 'address': '경기도 이천시'},
      {'lat': 37.6584, 'lng': 126.8320, 'address': '경기도 고양시'},
      {'lat': 37.3219, 'lng': 127.0956, 'address': '경기도 수원시'},
      // 부산
      {'lat': 35.1796, 'lng': 129.0756, 'address': '부산시 해운대구'},
      {'lat': 35.1547, 'lng': 129.0598, 'address': '부산시 수영구'},
      // 대구
      {'lat': 35.8714, 'lng': 128.6014, 'address': '대구시 중구'},
      {'lat': 35.8683, 'lng': 128.5986, 'address': '대구시 수성구'},
      // 인천
      {'lat': 37.4563, 'lng': 126.7052, 'address': '인천시 연수구'},
      {'lat': 37.4750, 'lng': 126.6178, 'address': '인천시 남동구'},
      // 광주
      {'lat': 35.1595, 'lng': 126.8526, 'address': '광주시 서구'},
      // 대전
      {'lat': 36.3504, 'lng': 127.3845, 'address': '대전시 서구'},
      // 제주
      {'lat': 33.4996, 'lng': 126.5312, 'address': '제주시'},
      {'lat': 33.2541, 'lng': 126.5600, 'address': '서귀포시'},
    ];
    
    // 특정 계정별 위치 지정
    final specificLocations = <String, Map<String, dynamic>>{
      'admin@mingrr.com': {'lat': 37.2346, 'lng': 127.2090, 'address': '경기도 용인시'},
      'test1@mingrr.com': {'lat': 37.2346, 'lng': 127.2090, 'address': '경기도 용인시'},
      'test2@mingrr.com': {'lat': 37.3825, 'lng': 127.1188, 'address': '경기도 성남시 분당구'},
      'test3@mingrr.com': {'lat': 37.3219, 'lng': 127.0956, 'address': '경기도 수원시'},
    };
    
    int otherLocationIndex = 0;
    for (final userId in userIds) {
      final userDoc = await _firebase.usersCollection.doc(userId).get();
      Map<String, dynamic> location;
      
      if (userDoc.exists) {
        final email = userDoc.data()!['email'] as String? ?? '';
        
        if (specificLocations.containsKey(email)) {
          // 특정 계정은 지정된 위치
          location = specificLocations[email]!;
        } else {
          // 나머지는 순환 방식으로 다양한 위치 부여
          location = locations[otherLocationIndex % locations.length];
          otherLocationIndex++;
        }
      } else {
        location = locations[otherLocationIndex % locations.length];
        otherLocationIndex++;
      }
      
      await _firebase.usersCollection.doc(userId).set({
        'homeLocation': GeoPoint(location['lat'] as double, location['lng'] as double),
        'homeAddress': location['address'],
        'isLocationVerified': true,
      }, SetOptions(merge: true));
    }
    
    print('✅ ${userIds.length}명의 사용자에게 위치 정보 부여 완료');
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
  
  /// 채팅 데이터만 생성 (현재 로그인 사용자 기준 테스트 채팅 포함)
  /// 메시지는 chatRooms/{chatRoomId}/messages 서브컬렉션에 저장
  Future<void> seedChats() async {
    print('🌱 채팅 테스트 데이터 생성 중...');
    
    final currentUserId = _firebase.currentUserId;
    if (currentUserId == null) {
      print('❌ 로그인된 사용자가 없습니다');
      return;
    }
    
    // 현재 사용자 정보 가져오기
    final currentUserDoc = await _firebase.usersCollection.doc(currentUserId).get();
    final currentUserData = currentUserDoc.data();
    final currentUserNickname = currentUserData?['nickname'] ?? '나';
    final currentUserProfileImage = currentUserData?['profileImageUrl'];
    
    // 현재 사용자의 반려동물 정보 가져오기
    final myPetsSnapshot = await _firebase.petsCollection
        .where('ownerId', isEqualTo: currentUserId)
        .limit(1)
        .get();
    String? myPetName;
    String? myPetImageUrl;
    if (myPetsSnapshot.docs.isNotEmpty) {
      final myPetData = myPetsSnapshot.docs.first.data();
      myPetName = myPetData['name'];
      myPetImageUrl = myPetData['profileImageUrl'];
    }
    
    final now = DateTime.now();
    
    // 테스트용 상대방 사용자 생성 (다양한 위치 포함)
    final testUsers = [
      {'id': '${TestDataPrefix.user}dating_001', 'nickname': '김민수', 'petName': '초코', 'petBreed': '포메라니안', 'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 강남구'},
      {'id': '${TestDataPrefix.user}dating_002', 'nickname': '시바견집사', 'petName': '시바', 'petBreed': '시바견', 'lat': 37.5665, 'lng': 126.9780, 'address': '서울시 중구'},
      {'id': '${TestDataPrefix.user}market_001', 'nickname': '이영희', 'petName': null, 'petBreed': null, 'lat': 37.5219, 'lng': 126.9245, 'address': '서울시 마포구'},
      {'id': '${TestDataPrefix.user}community_001', 'nickname': '박철수', 'petName': '뭉치', 'petBreed': '말티즈', 'lat': 37.4979, 'lng': 127.0276, 'address': '서울시 서초구'},
    ];
    
    for (final user in testUsers) {
      final userId = user['id'] as String;
      await _firebase.usersCollection.doc(userId).set({
        'nickname': user['nickname'],
        'profileImageUrl': null,
        'kkosunnaeScore': 75.0,
        'isIdentityVerified': true,
        'isPetVerified': true,
        'isLocationVerified': true,
        'homeLocation': GeoPoint(user['lat'] as double, user['lng'] as double),
        'homeAddress': user['address'],
        'matchCount': 5,
        'walkCount': 10,
        'transactionCount': 3,
        'groupCount': 2,
        'lastActiveAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      }, SetOptions(merge: true));
      
      if (user['petName'] != null) {
        await _firebase.petsCollection.doc('${TestDataPrefix.pet}${userId}').set({
          'ownerId': userId,
          'name': user['petName'],
          'breed': user['petBreed'] ?? '포메라니안',
          'birthDate': Timestamp.fromDate(now.subtract(const Duration(days: 365 * 3))),
          'gender': 'male',
          'weight': 5.0,
          'isNeutered': false,
          'profileImageUrl': sampleImages[0],
          'photoUrls': [sampleImages[0], sampleImages[1]],
          'traits': ['active', 'friendly'],
          'bio': '안녕하세요! ${user['petName']}입니다.',
          'likeCount': 42,
          'isPrimary': true,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
          'updatedAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
      }
    }
    
    // 1. 데이팅 채팅방 (초코) - 여러 메시지 포함
    final chatId1 = '${TestDataPrefix.chat}dating_001';
    final otherUser1 = '${TestDataPrefix.user}dating_001';
    await _firebase.chatRoomsCollection.doc(chatId1).set({
      'participantIds': [currentUserId, otherUser1],
      'participants': {
        currentUserId: {'id': currentUserId, 'nickname': currentUserNickname, 'profileImageUrl': currentUserProfileImage, 'petName': myPetName, 'petImageUrl': myPetImageUrl},
        otherUser1: {'id': otherUser1, 'nickname': '김민수', 'profileImageUrl': null, 'petName': '초코', 'petImageUrl': sampleImages[0]},
      },
      'type': 'dating',
      'lastMessage': '내일 오후 3시 한강공원에서 만나요! 🐕',
      'lastMessageSenderId': otherUser1,
      'lastMessageAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      'unreadCounts': {currentUserId: 2, otherUser1: 0},
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
    });
    // 메시지들 (서브컬렉션에 저장)
    final messages1 = [
      {'content': '안녕하세요! 초코 보호자입니다 😊', 'senderId': otherUser1, 'minutesAgo': 120},
      {'content': '안녕하세요! 반가워요~', 'senderId': currentUserId, 'minutesAgo': 115},
      {'content': '초코가 산책 친구를 찾고 있어요!', 'senderId': otherUser1, 'minutesAgo': 110},
      {'content': '저희 아이도 산책 좋아해요! 언제 만날까요?', 'senderId': currentUserId, 'minutesAgo': 60},
      {'content': '내일 오후 3시 한강공원에서 만나요! 🐕', 'senderId': otherUser1, 'minutesAgo': 5},
    ];
    for (int i = 0; i < messages1.length; i++) {
      final msg = messages1[i];
      await _firebase.messagesCollection(chatId1).doc('${TestDataPrefix.message}${chatId1}_$i').set({
        'senderId': msg['senderId'],
        'content': msg['content'],
        'type': 'text',
        'isRead': msg['senderId'] == currentUserId || i < messages1.length - 2,
        'sentAt': Timestamp.fromDate(now.subtract(Duration(minutes: msg['minutesAgo'] as int))),
      });
    }
    
    // 2. 데이팅 채팅방 (시바) - 받은 신청 (pending 상태)
    final chatId2 = '${TestDataPrefix.chat}dating_002';
    final otherUser2 = '${TestDataPrefix.user}dating_002';
    await _firebase.chatRoomsCollection.doc(chatId2).set({
      'participantIds': [currentUserId, otherUser2],
      'participants': {
        currentUserId: {'id': currentUserId, 'nickname': currentUserNickname, 'profileImageUrl': currentUserProfileImage, 'petName': myPetName, 'petImageUrl': myPetImageUrl},
        otherUser2: {'id': otherUser2, 'nickname': '시바견집사', 'profileImageUrl': null, 'petName': '시바', 'petImageUrl': sampleImages[1]},
      },
      'type': 'dating',
      'lastMessage': '시바가 산책 친구를 찾고 있어요! 같이 놀아요 🐕',
      'lastMessageSenderId': otherUser2,
      'lastMessageAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 15))),
      'unreadCounts': {currentUserId: 1, otherUser2: 0},
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
    });
    final messages2 = [
      {'content': '시바가 산책 친구를 찾고 있어요! 같이 놀아요 🐕', 'senderId': otherUser2, 'minutesAgo': 15},
    ];
    for (int i = 0; i < messages2.length; i++) {
      final msg = messages2[i];
      await _firebase.messagesCollection(chatId2).doc('${TestDataPrefix.message}${chatId2}_$i').set({
        'senderId': msg['senderId'],
        'content': msg['content'],
        'type': 'text',
        'isRead': false,
        'sentAt': Timestamp.fromDate(now.subtract(Duration(minutes: msg['minutesAgo'] as int))),
      });
    }
    
    // 3. 마켓 채팅방
    final chatId3 = '${TestDataPrefix.chat}market_001';
    final otherUser3 = '${TestDataPrefix.user}market_001';
    await _firebase.chatRoomsCollection.doc(chatId3).set({
      'participantIds': [currentUserId, otherUser3],
      'participants': {
        currentUserId: {'id': currentUserId, 'nickname': currentUserNickname, 'profileImageUrl': currentUserProfileImage, 'petName': myPetName, 'petImageUrl': myPetImageUrl},
        otherUser3: {'id': otherUser3, 'nickname': '이영희', 'profileImageUrl': null, 'petName': null, 'petImageUrl': null},
      },
      'type': 'marketplace',
      'lastMessage': '네, 아직 판매중이에요! 직거래 가능하세요?',
      'lastMessageSenderId': otherUser3,
      'lastMessageAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'unreadCounts': {currentUserId: 1, otherUser3: 0},
      'relatedId': '${TestDataPrefix.product}001',
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
    });
    final messages3 = [
      {'content': '안녕하세요! 강아지 사료 아직 판매하시나요?', 'senderId': currentUserId, 'minutesAgo': 180},
      {'content': '네, 아직 판매중이에요! 직거래 가능하세요?', 'senderId': otherUser3, 'minutesAgo': 60},
    ];
    for (int i = 0; i < messages3.length; i++) {
      final msg = messages3[i];
      await _firebase.messagesCollection(chatId3).doc('${TestDataPrefix.message}${chatId3}_$i').set({
        'senderId': msg['senderId'],
        'content': msg['content'],
        'type': 'text',
        'isRead': i < messages3.length - 1,
        'sentAt': Timestamp.fromDate(now.subtract(Duration(minutes: msg['minutesAgo'] as int))),
      });
    }
    
    // 4. 소모임 채팅방
    final groupId = '${TestDataPrefix.group}chat_001';
    await _firebase.groupsCollection.doc(groupId).set({
      'name': '말티즈 산책 모임',
      'description': '말티즈 보호자들의 산책 모임입니다. 매주 토요일 오후에 만나요!',
      'type': 'walking',
      'creatorId': '${TestDataPrefix.user}community_001',
      'adminIds': ['${TestDataPrefix.user}community_001'],
      'memberIds': [currentUserId, '${TestDataPrefix.user}community_001'],
      'maxMembers': 20,
      'location': const GeoPoint(37.5172, 127.0473),
      'address': '서울시 강남구',
      'imageUrl': sampleImages[2],
      'isPublic': true,
      'requireApproval': false,
      'tags': ['말티즈', '산책', '강남'],
      'likeCount': 15,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
    
    final chatId4 = '${TestDataPrefix.chat}community_001';
    final otherUser4 = '${TestDataPrefix.user}community_001';
    await _firebase.chatRoomsCollection.doc(chatId4).set({
      'participantIds': [currentUserId, otherUser4],
      'participants': {
        currentUserId: {'id': currentUserId, 'nickname': currentUserNickname, 'profileImageUrl': currentUserProfileImage, 'petName': myPetName, 'petImageUrl': myPetImageUrl},
        otherUser4: {'id': otherUser4, 'nickname': '박철수', 'profileImageUrl': null, 'petName': '뭉치', 'petImageUrl': sampleImages[3]},
      },
      'type': 'community',
      'lastMessage': '이번 주 토요일 산책 참여하실 분? 🚶‍♂️🐕',
      'lastMessageSenderId': otherUser4,
      'lastMessageAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
      'unreadCounts': {currentUserId: 2, otherUser4: 0},
      'relatedId': groupId,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
    });
    final messages4 = [
      {'content': '말티즈 산책 모임에 오신 것을 환영합니다! 🎉', 'senderId': otherUser4, 'minutesAgo': 10080},
      {'content': '감사합니다! 반가워요~', 'senderId': currentUserId, 'minutesAgo': 10000},
      {'content': '이번 주 토요일 산책 참여하실 분? 🚶‍♂️🐕', 'senderId': otherUser4, 'minutesAgo': 30},
    ];
    for (int i = 0; i < messages4.length; i++) {
      final msg = messages4[i];
      await _firebase.messagesCollection(chatId4).doc('${TestDataPrefix.message}${chatId4}_$i').set({
        'senderId': msg['senderId'],
        'content': msg['content'],
        'type': 'text',
        'isRead': i < messages4.length - 2,
        'sentAt': Timestamp.fromDate(now.subtract(Duration(minutes: msg['minutesAgo'] as int))),
      });
    }
    
    print('✅ 채팅 테스트 데이터 생성 완료');
    print('   - 데이팅 채팅 (초코): $chatId1 (메시지 ${messages1.length}개)');
    print('   - 데이팅 채팅 (시바): $chatId2 (메시지 ${messages2.length}개)');
    print('   - 마켓 채팅: $chatId3 (메시지 ${messages3.length}개)');
    print('   - 소모임 채팅: $chatId4 (메시지 ${messages4.length}개)');
  }
  
  /// 채팅 테스트 데이터 삭제
  Future<void> clearChats() async {
    print('🗑️ 채팅 테스트 데이터 삭제 중...');
    
    final testChatIds = [
      '${TestDataPrefix.chat}dating_001',
      '${TestDataPrefix.chat}dating_002', 
      '${TestDataPrefix.chat}market_001',
      '${TestDataPrefix.chat}community_001',
      // 기존 형식도 삭제
      'chat_dating_test', 
      'chat_dating_shiba_test', 
      'chat_market_test', 
      'chat_community_test',
    ];
    
    for (final chatId in testChatIds) {
      // 서브컬렉션 메시지 먼저 삭제
      final messagesSnapshot = await _firebase.messagesCollection(chatId).get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      // 채팅방 삭제
      await _firebase.chatRoomsCollection.doc(chatId).delete();
    }
    
    // 테스트 사용자 삭제
    final testUserIds = [
      '${TestDataPrefix.user}dating_001',
      '${TestDataPrefix.user}dating_002',
      '${TestDataPrefix.user}market_001',
      '${TestDataPrefix.user}community_001',
      // 기존 형식
      'test_user_dating',
      'test_user_dating_shiba',
      'test_user_market',
      'test_user_community',
    ];
    for (final userId in testUserIds) {
      await _firebase.usersCollection.doc(userId).delete();
      await _firebase.petsCollection.doc('${TestDataPrefix.pet}$userId').delete();
      await _firebase.petsCollection.doc('pet_$userId').delete();
    }
    
    // 테스트 그룹 삭제
    await _firebase.groupsCollection.doc('${TestDataPrefix.group}chat_001').delete();
    await _firebase.firestore.collection('groups').doc('group_test_001').delete();
    
    print('✅ 채팅 테스트 데이터 삭제 완료');
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
    
    // 교배 가능한 펫 정보 가져오기 (isBreedingAvailable: true)
    final petsSnapshot = await _firebase.petsCollection
        .where('isBreedingAvailable', isEqualTo: true)
        .limit(15)
        .get();
    
    // 펫 ID와 소유자 ID를 함께 저장
    final petInfoList = petsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'petId': doc.id,
        'ownerId': data['ownerId'] as String? ?? '',
      };
    }).toList();
    
    if (petInfoList.isEmpty) {
      print('  ⚠️ 반려동물 데이터가 없어서 교배 글을 생성할 수 없습니다.');
      return;
    }
    
    print('  📋 교배 가능한 펫 ${petInfoList.length}마리 발견');
    
    // 대한민국 주요 도시 위치 정보 (교배글용)
    final koreaLocations = [
      {'lat': 37.2346, 'lng': 127.2090, 'address': '경기도 용인시'},
      {'lat': 36.3504, 'lng': 127.3845, 'address': '대전광역시 서구'},
      {'lat': 37.5172, 'lng': 127.0473, 'address': '서울시 강남구'},
      {'lat': 35.1796, 'lng': 129.0756, 'address': '부산시 해운대구'},
      {'lat': 35.8714, 'lng': 128.6014, 'address': '대구광역시 중구'},
      {'lat': 37.4563, 'lng': 126.7052, 'address': '인천시 연수구'},
      {'lat': 35.1595, 'lng': 126.8526, 'address': '광주광역시 서구'},
      {'lat': 35.5384, 'lng': 129.3114, 'address': '울산광역시 남구'},
      {'lat': 33.4996, 'lng': 126.5312, 'address': '제주시'},
      {'lat': 37.3825, 'lng': 127.1188, 'address': '경기도 성남시 분당구'},
    ];
    
    // 다양한 교배 글 템플릿 (제목, 설명, 조건)
    final postTemplates = [
      {'title': '건강한 교배 상대 찾아요', 'desc': '건강검진 완료, 예방접종 완료!\n성격이 온순하고 사람을 좋아해요.\n같은 품종 또는 비슷한 크기 원합니다.', 'preferredGender': 'female', 'preferredSizes': ['large', 'giant'], 'sameBreedOnly': false},
      {'title': '교배 상대 구해요', 'desc': '혈통서 있고, 건강검진 완료했어요!\n성격이 활발하고 애교가 많아요.\n서울/경기 지역 선호해요.', 'preferredGender': 'male', 'preferredSizes': ['tiny', 'small'], 'sameBreedOnly': true},
      {'title': '교배 파트너 찾아요', 'desc': '건강하고 털 상태도 좋아요.\n📍 채팅으로 연락주세요!', 'preferredGender': 'female', 'preferredSizes': ['tiny', 'small'], 'sameBreedOnly': false},
      {'title': '교배 원해요', 'desc': '건강검진 완료, 예방접종 완료!\n성격 좋은 아이면 좋겠어요.', 'preferredGender': 'male', 'preferredSizes': ['medium'], 'sameBreedOnly': true},
      {'title': '교배 상대 구합니다', 'desc': '✅ 건강검진 완료\n✅ 유전병 검사 완료\n똑똑하고 에너지가 넘쳐요.', 'preferredGender': 'female', 'preferredSizes': ['medium', 'large'], 'sameBreedOnly': false},
      {'title': '교배 파트너 찾아요', 'desc': '성격이 정말 좋고 사람을 좋아해요.\n건강하고 털 관리 잘 되어있어요.', 'preferredGender': 'male', 'preferredSizes': ['large', 'giant'], 'sameBreedOnly': false},
      {'title': '교배 원해요', 'desc': '모든 강아지와 친하게 지내요!\n건강검진 완료했고 성격 좋아요.', 'preferredGender': 'female', 'preferredSizes': ['tiny', 'small'], 'sameBreedOnly': false},
      {'title': '교배 상대 구해요', 'desc': '충성스럽고 건강해요!\n등산도 좋아하고 체력이 좋아요.', 'preferredGender': 'female', 'preferredSizes': ['large'], 'sameBreedOnly': true},
      {'title': '교배 파트너 찾아요', 'desc': '에너지 넘치고 건강해요.\n산책을 정말 좋아합니다.', 'preferredGender': 'female', 'preferredSizes': ['medium'], 'sameBreedOnly': true},
      {'title': '교배 원해요', 'desc': '호기심 많고 활발해요!\n건강검진 완료, 예방접종 완료.', 'preferredGender': 'male', 'preferredSizes': ['medium'], 'sameBreedOnly': false},
    ];
    
    // 실제 펫 정보를 기반으로 교배글 생성 (펫 소유자 = 교배글 작성자)
    final postCount = petInfoList.length < postTemplates.length ? petInfoList.length : postTemplates.length;
    
    for (int i = 0; i < postCount; i++) {
      final petInfo = petInfoList[i];
      final template = postTemplates[i];
      final locationInfo = koreaLocations[i % koreaLocations.length];
      
      final post = BreedingPostModel(
        id: '${TestDataPrefix.breeding}${(i + 1).toString().padLeft(3, '0')}',
        authorId: petInfo['ownerId'] as String,  // 펫 소유자 = 교배글 작성자
        petId: petInfo['petId'] as String,
        title: template['title'] as String,
        description: template['desc'] as String,
        status: BreedingStatus.active,
        preferredGender: template['preferredGender'] as String?,
        preferredSizes: List<String>.from(template['preferredSizes'] as List),
        sameBreedOnly: template['sameBreedOnly'] as bool,
        minAge: 1,
        maxAge: 5,
        location: GeoPoint(locationInfo['lat'] as double, locationInfo['lng'] as double),
        address: locationInfo['address'] as String,
        viewCount: (i + 1) * 15 + (i * 7),
        likeCount: (i + 1) * 4,
        chatCount: i % 5,
        createdAt: now.subtract(Duration(days: i * 2)),
        updatedAt: now.subtract(Duration(days: i)),
      );
      
      await _firebase.breedingPostsCollection.doc(post.id).set(post.toFirestore());
    }
    
    print('  ✓ 교배 글 $postCount개 생성 완료');
  }
  
  // ===== 항목별 삭제 메서드 =====
  
  Future<void> clearUsers() async {
    await _clearCollection(_firebase.usersCollection);
  }
  
  Future<void> clearPets() async {
    // 테스트 데이터만 삭제 (권한 문제 방지)
    await _clearTestDataFromCollection(_firebase.petsCollection, TestDataPrefix.pet);
  }
  
  Future<void> clearProducts() async {
    // 테스트 데이터만 삭제 (권한 문제 방지)
    await _clearTestDataFromCollection(_firebase.productsCollection, TestDataPrefix.product);
  }
  
  Future<void> clearGroups() async {
    // 테스트 데이터만 삭제 (권한 문제 방지)
    await _clearTestDataFromCollection(_firebase.groupsCollection, TestDataPrefix.group);
  }
  
  Future<void> clearJobs() async {
    // 테스트 데이터만 삭제 (권한 문제 방지)
    await _clearTestDataFromCollection(_firebase.jobsCollection, TestDataPrefix.job);
  }
  
  Future<void> clearLikesAndMatches() async {
    // 테스트 데이터만 삭제 (권한 문제 방지)
    await _clearTestDataFromCollection(_firebase.datingRequestsCollection, TestDataPrefix.like);
    await _clearTestDataFromCollection(_firebase.matchesCollection, TestDataPrefix.match);
  }
  
  Future<void> clearBreedingPosts() async {
    // 테스트 데이터만 삭제 (권한 문제 방지)
    await _clearTestDataFromCollection(_firebase.breedingPostsCollection, TestDataPrefix.breeding);
  }
  
  // ===== 헬퍼 메서드 =====
  
  /// 테스트 사용자 문서 생성 (users 컬렉션에 가상 사용자 추가)
  Future<void> seedTestUsers() async {
    print('👤 테스트 사용자 생성 중...');
    
    final testUsers = [
      {'id': 'test_user_001', 'email': 'test1@mingrr.com', 'nickname': '테스트유저1', 'address': '경기도 용인시'},
      {'id': 'test_user_002', 'email': 'test2@mingrr.com', 'nickname': '테스트유저2', 'address': '서울시 강남구'},
      {'id': 'test_user_003', 'email': 'test3@mingrr.com', 'nickname': '테스트유저3', 'address': '부산시 해운대구'},
      {'id': 'test_user_004', 'email': 'test4@mingrr.com', 'nickname': '테스트유저4', 'address': '대전광역시 서구'},
      {'id': 'test_user_005', 'email': 'test5@mingrr.com', 'nickname': '테스트유저5', 'address': '대구광역시 중구'},
    ];
    
    // 대한민국 주요 도시 위치
    final locations = [
      {'lat': 37.2346, 'lng': 127.2090}, // 용인
      {'lat': 37.5172, 'lng': 127.0473}, // 강남
      {'lat': 35.1796, 'lng': 129.0756}, // 해운대
      {'lat': 36.3504, 'lng': 127.3845}, // 대전
      {'lat': 35.8714, 'lng': 128.6014}, // 대구
    ];
    
    for (int i = 0; i < testUsers.length; i++) {
      final user = testUsers[i];
      final loc = locations[i];
      
      await _firebase.usersCollection.doc(user['id'] as String).set({
        'email': user['email'],
        'nickname': user['nickname'],
        'address': user['address'],
        'homeLocation': GeoPoint(loc['lat'] as double, loc['lng'] as double),
        'profileImageUrl': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    }
    
    print('✅ 테스트 사용자 ${testUsers.length}명 생성 완료');
  }
  
  Future<List<String>> _getExistingUserIds() async {
    final snapshot = await _firebase.usersCollection.limit(10).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
  
  Future<void> _seedJobs(List<String> userIds) async {
    final now = DateTime.now();
    
    // 다양한 알바 데이터 (다양한 타입, 가격대, 기간)
    final jobDataList = [
      {'title': '여행 중 우리 아이 돌봐주실 분', 'desc': '3박 4일 동안 돌봐주실 분 구해요', 'type': 'care', 'price': 50000, 'unit': '일', 'address': '서울시 강남구 역삼동'},
      {'title': '평일 오전 산책 도우미 구해요', 'desc': '월~금 오전 8시~9시 산책 부탁드려요', 'type': 'walk', 'price': 15000, 'unit': '회', 'address': '서울시 마포구 상암동'},
      {'title': '대형견 목욕 도와주실 분', 'desc': '골든리트리버 목욕 도와주실 분 구해요', 'type': 'bath', 'price': 30000, 'unit': '회', 'address': '서울시 송파구 잠실동'},
      {'title': '기본 훈련 도와주실 분', 'desc': '앉아, 기다려 등 기본 훈련 도와주세요', 'type': 'training', 'price': 40000, 'unit': '회', 'address': '서울시 용산구 이태원동'},
      {'title': '주말 산책 도우미', 'desc': '토요일, 일요일 오후 산책 부탁드려요', 'type': 'walk', 'price': 20000, 'unit': '회', 'address': '서울시 강남구 삼성동'},
      {'title': '출장 중 펫시터 구해요', 'desc': '일주일간 돌봐주실 분 구합니다', 'type': 'care', 'price': 45000, 'unit': '일', 'address': '서울시 서초구 반포동'},
      {'title': '노령견 케어 도우미', 'desc': '약 먹이기, 산책 등 도와주세요', 'type': 'care', 'price': 35000, 'unit': '일', 'address': '서울시 종로구 평창동'},
      {'title': '강아지 미용 도우미', 'desc': '셀프 미용 도와주실 분 구해요', 'type': 'bath', 'price': 25000, 'unit': '회', 'address': '서울시 강동구 천호동'},
      {'title': '저녁 산책 도우미', 'desc': '평일 저녁 7시 산책 부탁드려요', 'type': 'walk', 'price': 18000, 'unit': '회', 'address': '서울시 중구 명동'},
      {'title': '퍼피 사회화 훈련 도우미', 'desc': '다른 강아지와 어울리는 훈련 도와주세요', 'type': 'training', 'price': 50000, 'unit': '회', 'address': '서울시 강남구 청담동'},
      {'title': '주 3회 산책 도우미', 'desc': '월수금 오전 산책 부탁드려요', 'type': 'walk', 'price': 15000, 'unit': '회', 'address': '서울시 마포구 연남동'},
      {'title': '당일 펫시터 급구', 'desc': '오늘 하루만 돌봐주실 분 구해요', 'type': 'care', 'price': 60000, 'unit': '일', 'address': '서울시 송파구 문정동'},
      {'title': '발톱 깎기 도와주실 분', 'desc': '대형견 발톱 깎기 도와주세요', 'type': 'bath', 'price': 20000, 'unit': '회', 'address': '서울시 용산구 한남동'},
      {'title': '배변 훈련 도우미', 'desc': '퍼피 배변 훈련 도와주세요', 'type': 'training', 'price': 35000, 'unit': '회', 'address': '서울시 강남구 논현동'},
      {'title': '장기 펫시터 구해요', 'desc': '한 달간 돌봐주실 분 구합니다', 'type': 'care', 'price': 40000, 'unit': '일', 'address': '서울시 서초구 방배동'},
    ];
    
    for (int i = 0; i < jobDataList.length; i++) {
      final data = jobDataList[i];
      final jobId = '${TestDataPrefix.job}${(i + 1).toString().padLeft(3, '0')}';
      
      final job = JobModel(
        id: jobId,
        userId: userIds[i % userIds.length],
        title: data['title'] as String,
        description: data['desc'] as String,
        type: JobType.values.firstWhere((e) => e.name == data['type']),
        status: i % 4 == 0 ? JobStatus.completed : JobStatus.recruiting,
        price: data['price'] as int,
        priceUnit: data['unit'] as String,
        startDate: now.add(Duration(days: i + 1)),
        endDate: now.add(Duration(days: i + 3)),
        duration: 1,
        address: data['address'] as String,
        createdAt: now.subtract(Duration(hours: i * 2)),
        updatedAt: now,
      );
      
      await _firebase.jobsCollection.doc(job.id).set(job.toFirestore());
    }
    print('  ✓ 알바 ${jobDataList.length}개 생성 완료');
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
      
      await _firebase.datingRequestsCollection.doc(likeId).set({
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
    final collection = _firebase.firestore.collection('weightRecords');
    
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
    final collection = _firebase.firestore.collection('walkRecords');
    
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
    final collection = _firebase.firestore.collection('groomingRecords');
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
    final collection = _firebase.firestore.collection('vaccinationRecords');
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
    final collection = _firebase.firestore.collection('checkupRecords');
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
    final collection = _firebase.firestore.collection('medicationRecords');
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
    await _clearCollection(_firebase.firestore.collection('weightRecords'));
    await _clearCollection(_firebase.firestore.collection('walkRecords'));
    await _clearCollection(_firebase.firestore.collection('groomingRecords'));
    await _clearCollection(_firebase.firestore.collection('vaccinationRecords'));
    await _clearCollection(_firebase.firestore.collection('checkupRecords'));
    await _clearCollection(_firebase.firestore.collection('medicationRecords'));
    print('✅ 건강수첩 데이터 삭제 완료');
  }
  
  // ===== 꼬순내 평가 데이터 =====
  
  Future<void> seedRatings() async {
    print('🌱 꼬순내 평가 데이터 생성 중...');
    
    // 실제 사용자 ID 가져오기
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    
    // 최소 2명 이상 필요
    if (userIds.length < 2) {
      print('⚠️ 평가 데이터 생성을 위해 최소 2명의 사용자가 필요합니다.');
      return;
    }
    
    final now = DateTime.now();
    
    final positiveTags = ['친절해요', '시간 약속을 잘 지켜요', '반려동물을 잘 돌봐요', '매너가 좋아요', '응답이 빨라요', '다시 만나고 싶어요'];
    final negativeTags = ['불친절해요', '시간 약속을 안 지켜요', '연락이 안 돼요', '매너가 아쉬워요'];
    final ratingTypes = [RatingType.dating, RatingType.marketplace, RatingType.breeding];
    
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
          id: '${TestDataPrefix.rating}${ratingIndex.toString().padLeft(3, '0')}',
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
    
    // 거래 상태 데이터도 생성 (실제 사용자 ID 사용)
    await _seedTransactionStatuses(userIds);
    
    print('✅ 꼬순내 평가 ${ratingIndex}개 생성 완료 (사용자 ${userIds.length}명 기준)');
  }
  
  Future<void> _seedTransactionStatuses(List<String> userIds) async {
    final now = DateTime.now();
    final collection = _firebase.firestore.collection('transactionStatuses');
    final types = ['marketplace', 'dating', 'breeding'];
    
    for (int i = 0; i < 10; i++) {
      final sellerId = userIds[i % userIds.length];
      final buyerId = userIds[(i + 1) % userIds.length];
      
      final status = TransactionStatusModel(
        id: '${TestDataPrefix.rating}txn_status_$i',
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
    // 테스트 데이터만 삭제
    await _clearTestDataFromCollection(_firebase.ratingsCollection, TestDataPrefix.rating);
    await _clearTestDataFromCollection(_firebase.firestore.collection('transactionStatuses'), TestDataPrefix.rating);
    print('✅ 꼬순내 평가 데이터 삭제 완료');
  }
  
  // ===== 커뮤니티 게시글 데이터 =====
  
  /// 커뮤니티 게시글 데이터 생성
  Future<void> seedCommunityPosts() async {
    print('🌱 커뮤니티 게시글 데이터 생성 중...');
    
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    
    // 사용자 닉네임 가져오기
    final userNicknames = <String, String>{};
    for (final userId in userIds) {
      final userDoc = await _firebase.usersCollection.doc(userId).get();
      userNicknames[userId] = userDoc.data()?['nickname'] ?? '사용자';
    }
    
    await _seedCommunityPosts(userIds, userNicknames);
    print('✅ 커뮤니티 게시글 데이터 생성 완료');
  }
  
  Future<void> _seedCommunityPosts(List<String> userIds, Map<String, String> userNicknames) async {
    final now = DateTime.now();
    
    final postDataList = [
      // 일상 카테고리
      {'category': 'daily', 'content': '오늘 우리 초코랑 한강 산책 다녀왔어요! 🐕 날씨가 너무 좋아서 2시간이나 걸었네요. 초코가 너무 행복해하는 모습 보니까 저도 기분이 좋아졌어요 ☺️', 'tags': ['산책', '한강', '일상'], 'likeCount': 45, 'commentCount': 12, 'viewCount': 230},
      {'category': 'daily', 'content': '새로 산 강아지 옷 입혀봤어요! 어떤가요? 너무 귀엽지 않나요? 🎀', 'tags': ['강아지옷', '패션', '귀여움'], 'likeCount': 78, 'commentCount': 23, 'viewCount': 456},
      {'category': 'daily', 'content': '우리 뭉치 오늘 3살 생일이에요! 🎂 케이크 만들어줬더니 너무 좋아하네요', 'tags': ['생일', '케이크', '축하'], 'likeCount': 156, 'commentCount': 45, 'viewCount': 892},
      
      // 질문 카테고리
      {'category': 'question', 'content': '강아지가 자꾸 발을 핥는데 이유가 뭘까요? 😥 스트레스인가요 아니면 피부 문제일까요?', 'tags': ['질문', '건강', '행동'], 'likeCount': 23, 'commentCount': 34, 'viewCount': 567},
      {'category': 'question', 'content': '소형견 사료 추천 부탁드려요! 현재 로얄캐닌 먹이고 있는데 다른 좋은 사료 있을까요?', 'tags': ['사료', '추천', '소형견'], 'likeCount': 34, 'commentCount': 56, 'viewCount': 789},
      {'category': 'question', 'content': '강아지 미용 주기가 어떻게 되나요? 푸들인데 한 달에 한 번이면 될까요?', 'tags': ['미용', '푸들', '질문'], 'likeCount': 19, 'commentCount': 28, 'viewCount': 345},
      
      // 정보공유 카테고리
      {'category': 'info', 'content': '강남역 근처 애견동반 카페 추천해요! ☕🐕\n\n1. 멍멍카페 - 넓고 쾌적함\n2. 도그파크카페 - 놀이터 있음\n3. 퍼피라운지 - 음료 맛있음\n\n모두 소형견~중형견까지 가능해요!', 'tags': ['카페', '강남', '추천'], 'likeCount': 234, 'commentCount': 67, 'viewCount': 1234},
      {'category': 'info', 'content': '여름철 강아지 열사병 예방법 공유합니다! 🌞\n\n1. 한낮 산책 피하기\n2. 물 자주 마시게 하기\n3. 시원한 매트 깔아주기\n4. 에어컨 적정 온도 유지\n\n모두 건강한 여름 보내세요!', 'tags': ['건강', '여름', '열사병'], 'likeCount': 189, 'commentCount': 45, 'viewCount': 987},
      
      // 후기 카테고리
      {'category': 'review', 'content': '행복 동물병원 후기입니다! ⭐⭐⭐⭐⭐\n\n우리 강아지 중성화 수술 받았는데 원장님이 정말 친절하시고 설명도 자세히 해주셨어요. 수술 후 관리도 꼼꼼하게 해주셔서 회복도 빨랐어요. 강추합니다!', 'tags': ['동물병원', '후기', '중성화'], 'likeCount': 67, 'commentCount': 23, 'viewCount': 456},
      {'category': 'review', 'content': '강아지 자동 급식기 사용 후기! 📦\n\n출장 갈 때 유용하게 쓰고 있어요. 타이머 설정도 쉽고 양 조절도 잘 돼요. 다만 소리가 좀 나서 처음엔 강아지가 놀랐어요 ㅎㅎ', 'tags': ['급식기', '후기', '용품'], 'likeCount': 45, 'commentCount': 18, 'viewCount': 345},
      
      // 실종/목격 카테고리
      {'category': 'lost', 'content': '⚠️ 실종 신고 ⚠️\n\n잃어버린 날짜: 어제 오후 3시경\n장소: 서울 마포구 상암동 월드컵공원 근처\n특징: 흰색 말티즈, 수컷, 3살, 파란색 목줄\n이름: 하양이\n\n목격하신 분 연락 부탁드립니다 😢', 'tags': ['실종', '말티즈', '마포구'], 'likeCount': 234, 'commentCount': 89, 'viewCount': 2345},
      
      // 이벤트 카테고리
      {'category': 'event', 'content': '🎉 반려견 사진 콘테스트 🎉\n\n이번 주 일요일 오후 2시 한강공원에서 반려견 사진 콘테스트가 열립니다!\n\n참가비: 무료\n상품: 1등 사료 1년치, 2등 간식세트, 3등 장난감세트\n\n많은 참여 부탁드려요!', 'tags': ['이벤트', '콘테스트', '한강'], 'likeCount': 156, 'commentCount': 67, 'viewCount': 1567},
      
      // 기타 카테고리
      {'category': 'other', 'content': '강아지 입양 고민 중이에요... 🤔\n\n직장인인데 강아지 키울 수 있을까요? 출퇴근 시간이 길어서 걱정이에요. 경험 있으신 분들 조언 부탁드려요!', 'tags': ['입양', '고민', '조언'], 'likeCount': 89, 'commentCount': 78, 'viewCount': 678},
      {'category': 'other', 'content': '오늘 처음 가입했어요! 👋\n\n우리 집 막내 골든리트리버 골디입니다. 앞으로 자주 소통해요~', 'tags': ['가입인사', '골든리트리버', '신규'], 'likeCount': 123, 'commentCount': 34, 'viewCount': 456},
    ];
    
    for (int i = 0; i < postDataList.length; i++) {
      final data = postDataList[i];
      final authorId = userIds[i % userIds.length];
      final postId = '${TestDataPrefix.feedPost}${(i + 1).toString().padLeft(3, '0')}';
      
      final post = community.CommunityPostModel(
        id: postId,
        authorId: authorId,
        authorName: userNicknames[authorId] ?? '사용자',
        category: community.CommunityCategory.values.firstWhere(
          (e) => e.name == data['category'],
          orElse: () => community.CommunityCategory.daily,
        ),
        content: data['content'] as String,
        imageUrls: i % 3 == 0 ? [sampleImages[i % sampleImages.length]] : [],
        tags: List<String>.from(data['tags'] as List),
        likeCount: data['likeCount'] as int,
        commentCount: data['commentCount'] as int,
        viewCount: data['viewCount'] as int,
        isAnonymous: i % 5 == 0,
        createdAt: now.subtract(Duration(hours: i * 3)),
        updatedAt: now.subtract(Duration(hours: i * 3)),
      );
      
      await _firebase.feedPostsCollection.doc(post.id).set(post.toFirestore());
    }
    
    // 댓글도 일부 생성
    await _seedCommunityComments(userIds, userNicknames);
    
    print('  ✓ 커뮤니티 게시글 ${postDataList.length}개 생성 완료');
  }
  
  Future<void> _seedCommunityComments(List<String> userIds, Map<String, String> userNicknames) async {
    final now = DateTime.now();
    final commentsCollection = _firebase.firestore.collection('communityComments');
    
    final commentDataList = [
      {'postId': '${TestDataPrefix.feedPost}001', 'content': '너무 귀여워요! 🥰'},
      {'postId': '${TestDataPrefix.feedPost}001', 'content': '저도 오늘 산책 다녀왔어요~'},
      {'postId': '${TestDataPrefix.feedPost}002', 'content': '어디서 사셨어요? 저도 사고 싶어요!'},
      {'postId': '${TestDataPrefix.feedPost}003', 'content': '생일 축하해요! 🎉🎂'},
      {'postId': '${TestDataPrefix.feedPost}003', 'content': '케이크 레시피 공유해주세요~'},
      {'postId': '${TestDataPrefix.feedPost}004', 'content': '스트레스일 수도 있어요. 산책 자주 시켜주세요!'},
      {'postId': '${TestDataPrefix.feedPost}004', 'content': '저희 강아지도 그랬는데 피부 알러지였어요'},
      {'postId': '${TestDataPrefix.feedPost}005', 'content': '오리젠 추천해요! 우리 강아지 잘 먹어요'},
      {'postId': '${TestDataPrefix.feedPost}007', 'content': '정보 감사합니다! 저장해둘게요 📌'},
      {'postId': '${TestDataPrefix.feedPost}011', 'content': '꼭 찾으시길 바랍니다 😢 공유할게요'},
    ];
    
    for (int i = 0; i < commentDataList.length; i++) {
      final data = commentDataList[i];
      final authorId = userIds[(i + 1) % userIds.length];
      final commentId = '${TestDataPrefix.comment}${(i + 1).toString().padLeft(3, '0')}';
      
      final comment = community.CommunityCommentModel(
        id: commentId,
        postId: data['postId'] as String,
        authorId: authorId,
        authorName: userNicknames[authorId] ?? '사용자',
        content: data['content'] as String,
        likeCount: i * 2,
        isAnonymous: i % 4 == 0,
        createdAt: now.subtract(Duration(hours: i)),
      );
      
      await commentsCollection.doc(comment.id).set(comment.toFirestore());
    }
    
    print('  ✓ 커뮤니티 댓글 ${commentDataList.length}개 생성 완료');
  }
  
  /// 커뮤니티 게시글 데이터 삭제 (테스트 데이터만)
  Future<void> clearCommunityPosts() async {
    print('🗑️ 커뮤니티 게시글 데이터 삭제 중...');
    // 테스트 데이터만 삭제
    await _clearTestDataFromCollection(_firebase.feedPostsCollection, TestDataPrefix.feedPost);
    await _clearTestDataFromCollection(_firebase.firestore.collection('communityComments'), TestDataPrefix.comment);
    print('✅ 커뮤니티 게시글 데이터 삭제 완료');
  }
  
  // ===== 소모임 일정 데이터 =====
  
  /// 소모임 일정 데이터 생성
  Future<void> seedGroupSchedules() async {
    print('🌱 소모임 일정 데이터 생성 중...');
    
    final userIds = await _getExistingUserIds();
    if (userIds.isEmpty) {
      throw Exception('사용자 데이터가 없습니다. 먼저 사용자를 생성해주세요.');
    }
    
    // 기존 그룹 ID 가져오기
    final groupsSnapshot = await _firebase.groupsCollection.limit(5).get();
    final groupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();
    
    if (groupIds.isEmpty) {
      print('❌ 소모임 데이터가 없습니다. 먼저 소모임을 생성해주세요.');
      return;
    }
    
    await _seedGroupSchedules(userIds, groupIds);
    print('✅ 소모임 일정 데이터 생성 완료');
  }
  
  Future<void> _seedGroupSchedules(List<String> userIds, List<String> groupIds) async {
    final now = DateTime.now();
    final schedulesCollection = _firebase.firestore.collection('schedules');
    
    final scheduleDataList = [
      {'title': '주말 한강 산책', 'desc': '이번 주 토요일 오후 2시에 한강공원에서 만나요!', 'place': '여의도 한강공원 입구', 'maxParticipants': 10},
      {'title': '강아지 수영 모임', 'desc': '애견 수영장에서 물놀이해요~', 'place': '멍멍 수영장', 'maxParticipants': 8},
      {'title': '훈련 스터디', 'desc': '기본 훈련 방법 공유하고 연습해요', 'place': '서울숲 공원', 'maxParticipants': 6},
      {'title': '수제 간식 만들기', 'desc': '건강한 수제 간식 함께 만들어요', 'place': '마포구 공방', 'maxParticipants': 5},
      {'title': '애견카페 투어', 'desc': '새로 오픈한 애견카페 탐방!', 'place': '강남역 근처', 'maxParticipants': 8},
      {'title': '저녁 산책 모임', 'desc': '퇴근 후 가볍게 산책해요', 'place': '올림픽공원', 'maxParticipants': 12},
      {'title': '반려견 사진 촬영', 'desc': '예쁜 사진 찍어요 📸', 'place': '북서울꿈의숲', 'maxParticipants': 10},
      {'title': '노령견 케어 정보 공유', 'desc': '노령견 케어 팁 나눠요', 'place': '온라인 (줌)', 'maxParticipants': 20},
      {'title': '새벽 산책', 'desc': '아침 6시 상쾌한 산책!', 'place': '남산공원', 'maxParticipants': 6},
      {'title': '퍼피 플레이데이트', 'desc': '1살 미만 퍼피들의 사회화 모임', 'place': '반포 한강공원', 'maxParticipants': 8},
    ];
    
    for (int i = 0; i < scheduleDataList.length; i++) {
      final data = scheduleDataList[i];
      final groupId = groupIds[i % groupIds.length];
      final creatorId = userIds[i % userIds.length];
      final scheduleId = '${TestDataPrefix.schedule}${(i + 1).toString().padLeft(3, '0')}';
      
      // 일정 시간 설정 (과거/현재/미래 다양하게)
      final daysOffset = i < 3 ? -(i + 1) : (i - 2); // 처음 3개는 과거, 나머지는 미래
      final startTime = now.add(Duration(days: daysOffset)).copyWith(hour: 14 + (i % 4), minute: 0);
      
      final schedule = GroupScheduleModel(
        id: scheduleId,
        groupId: groupId,
        title: data['title'] as String,
        description: data['desc'] as String,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        place: data['place'] as String,
        participantIds: [creatorId, userIds[(i + 1) % userIds.length]],
        maxParticipants: data['maxParticipants'] as int,
        creatorId: creatorId,
        status: daysOffset < 0 ? ScheduleStatus.completed : ScheduleStatus.upcoming,
        createdAt: now.subtract(Duration(days: 7 - i)),
      );
      
      await schedulesCollection.doc(schedule.id).set(schedule.toFirestore());
    }
    
    print('  ✓ 소모임 일정 ${scheduleDataList.length}개 생성 완료');
  }
  
  /// 소모임 일정 데이터 삭제 (테스트 데이터만)
  Future<void> clearGroupSchedules() async {
    print('🗑️ 소모임 일정 데이터 삭제 중...');
    // 테스트 데이터만 삭제
    await _clearTestDataFromCollection(_firebase.firestore.collection('schedules'), TestDataPrefix.schedule);
    print('✅ 소모임 일정 데이터 삭제 완료');
  }
}
