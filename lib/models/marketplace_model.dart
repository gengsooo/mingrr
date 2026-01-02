import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 마켓플레이스(중고거래/나눔) 모델
/// 상품 등록, 거래 상태 등 데이터 구조
/// ============================================================

/// 상품 상태
enum ProductStatus {
  available,  // 판매/나눔 중
  reserved,   // 예약됨
  completed,  // 거래 완료
  hidden,     // 숨김
}

/// 상품 타입
enum ProductType {
  sell,   // 판매
  share,  // 나눔
  job,    // 알바
}

/// 상품 카테고리
enum ProductCategory {
  food,       // 사료/간식
  clothes,    // 의류/악세서리
  toys,       // 장난감
  supplies,   // 용품
  furniture,  // 가구/하우스
  health,     // 건강/위생
  other,      // 기타
}

/// 상품 모델
class ProductModel extends Equatable {
  /// 상품 ID
  final String id;
  
  /// 판매자 ID
  final String sellerId;
  
  /// 제목
  final String title;
  
  /// 설명
  final String description;
  
  /// 가격 (나눔인 경우 0)
  final int price;
  
  /// 상품 타입 (판매/나눔)
  final ProductType type;
  
  /// 카테고리
  final ProductCategory category;
  
  /// 상태
  final ProductStatus status;
  
  /// 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 위치 (GeoPoint)
  final GeoPoint? location;
  
  /// 주소 (표시용)
  final String? address;
  
  /// 조회수
  final int viewCount;
  
  /// 찜 수
  final int likeCount;
  
  /// 채팅 수
  final int chatCount;
  
  /// 대상 반려동물 종류 (선택사항)
  final String? targetPetType;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 수정일
  final DateTime updatedAt;
  
  /// 끌어올리기 시간
  final DateTime? bumpedAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.category,
    this.status = ProductStatus.available,
    this.imageUrls = const [],
    this.location,
    this.address,
    this.viewCount = 0,
    this.likeCount = 0,
    this.chatCount = 0,
    this.targetPetType,
    required this.createdAt,
    required this.updatedAt,
    this.bumpedAt,
  });

  /// 카테고리 한글 표시
  String get categoryString {
    switch (category) {
      case ProductCategory.food:
        return '사료/간식';
      case ProductCategory.clothes:
        return '의류/악세서리';
      case ProductCategory.toys:
        return '장난감';
      case ProductCategory.supplies:
        return '용품';
      case ProductCategory.furniture:
        return '가구/하우스';
      case ProductCategory.health:
        return '건강/위생';
      case ProductCategory.other:
        return '기타';
    }
  }

  /// 상태 한글 표시
  String get statusString {
    switch (status) {
      case ProductStatus.available:
        return type == ProductType.sell ? '판매중' : '나눔중';
      case ProductStatus.reserved:
        return '예약중';
      case ProductStatus.completed:
        return type == ProductType.sell ? '판매완료' : '나눔완료';
      case ProductStatus.hidden:
        return '숨김';
    }
  }

  /// 가격 표시 문자열
  String get priceString {
    if (type == ProductType.share) return '무료나눔';
    return '${_formatPrice(price)}원';
  }

  /// 가격 포맷팅 (천 단위 콤마)
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  factory ProductModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return ProductModel(
      id: id ?? data['id'] ?? '',
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      type: ProductType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ProductType.sell,
      ),
      category: ProductCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ProductCategory.other,
      ),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProductStatus.available,
      ),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: data['location'],
      address: data['address'],
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      chatCount: data['chatCount'] ?? 0,
      targetPetType: data['targetPetType'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      bumpedAt: data['bumpedAt'] != null
          ? (data['bumpedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'type': type.name,
      'category': category.name,
      'status': status.name,
      'imageUrls': imageUrls,
      'location': location,
      'address': address,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'chatCount': chatCount,
      'targetPetType': targetPetType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'bumpedAt': bumpedAt != null ? Timestamp.fromDate(bumpedAt!) : null,
    };
  }

  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    int? price,
    ProductType? type,
    ProductCategory? category,
    ProductStatus? status,
    List<String>? imageUrls,
    GeoPoint? location,
    String? address,
    int? viewCount,
    int? likeCount,
    int? chatCount,
    String? targetPetType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? bumpedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      address: address ?? this.address,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      chatCount: chatCount ?? this.chatCount,
      targetPetType: targetPetType ?? this.targetPetType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bumpedAt: bumpedAt ?? this.bumpedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        title,
        description,
        price,
        type,
        category,
        status,
        imageUrls,
        location,
        address,
        viewCount,
        likeCount,
        chatCount,
        targetPetType,
        createdAt,
        updatedAt,
        bumpedAt,
      ];
}

/// 상품 찜 모델
class ProductLikeModel extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  const ProductLikeModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory ProductLikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return ProductLikeModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, productId, createdAt];
}

/// ============================================================
/// 알바(펫시터/산책 등) 모델
/// ============================================================

/// 알바 타입
enum JobType {
  care,     // 돌봄
  walk,     // 산책
  bath,     // 목욕
  training, // 훈련
  other,    // 기타
}

/// 알바 상태
enum JobStatus {
  recruiting, // 모집중
  reserved,   // 예약됨
  completed,  // 완료
  cancelled,  // 취소됨
}

/// 알바 모델
class JobModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final JobType type;
  final JobStatus status;
  final int price;
  final String priceUnit; // '일', '회', '시간'
  final DateTime? startDate;
  final DateTime? endDate;
  final int? duration; // 시간 단위
  final GeoPoint? location;
  final String? address;
  final List<String> imageUrls;
  final int chatCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    this.status = JobStatus.recruiting,
    required this.price,
    required this.priceUnit,
    this.startDate,
    this.endDate,
    this.duration,
    this.location,
    this.address,
    this.imageUrls = const [],
    this.chatCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeString {
    switch (type) {
      case JobType.care:
        return '돌봄';
      case JobType.walk:
        return '산책';
      case JobType.bath:
        return '목욕';
      case JobType.training:
        return '훈련';
      case JobType.other:
        return '기타';
    }
  }

  String get priceString => '$price원/$priceUnit';

  String get periodString {
    if (startDate != null && endDate != null) {
      return '${startDate!.month}/${startDate!.day} ~ ${endDate!.month}/${endDate!.day}';
    }
    if (duration != null) {
      return '$duration시간';
    }
    return '';
  }

  factory JobModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return JobModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: JobType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => JobType.other,
      ),
      status: JobStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JobStatus.recruiting,
      ),
      price: data['price'] ?? 0,
      priceUnit: data['priceUnit'] ?? '회',
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      duration: data['duration'],
      location: data['location'],
      address: data['address'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      chatCount: data['chatCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'price': price,
      'priceUnit': priceUnit,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'duration': duration,
      'location': location,
      'address': address,
      'imageUrls': imageUrls,
      'chatCount': chatCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        type,
        status,
        price,
        priceUnit,
        startDate,
        endDate,
        duration,
        location,
        address,
        imageUrls,
        chatCount,
        createdAt,
        updatedAt,
      ];
}
