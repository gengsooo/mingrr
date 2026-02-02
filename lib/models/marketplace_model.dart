import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_icons.dart';

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

/// ProductStatus 확장
extension ProductStatusExtension on ProductStatus {
  String get label {
    switch (this) {
      case ProductStatus.available:
        return '판매중';
      case ProductStatus.reserved:
        return '예약중';
      case ProductStatus.completed:
        return '거래완료';
      case ProductStatus.hidden:
        return '숨김';
    }
  }
}

/// 상품 타입
enum ProductType {
  sell,   // 판매
  share,  // 나눔
  job,    // 알바
}

/// 상품 카테고리
enum ProductCategory {
  food('사료/간식', AppIcons.food),
  clothes('의류/악세서리', AppIcons.clothes),
  toys('장난감', AppIcons.toys),
  supplies('용품', AppIcons.supplies),
  furniture('가구/하우스', AppIcons.furniture),
  health('건강/위생', AppIcons.healthOutlined),
  other('기타', AppIcons.more);

  final String label;
  final IconData icon;

  const ProductCategory(this.label, this.icon);
}

/// 상품 모델
class ProductModel extends Equatable {
  /// 상품 ID
  final String id;
  
  /// 판매자 ID
  final String sellerId;
  
  /// 판매자 닉네임 (비정규화 - 추가 쿼리 방지)
  final String? sellerName;
  
  /// 판매자 프로필 이미지 (비정규화)
  final String? sellerImageUrl;
  
  /// 판매자 꼬순내 지수 (비정규화)
  final double sellerKkosunnaeScore;
  
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
    this.sellerName,
    this.sellerImageUrl,
    this.sellerKkosunnaeScore = 50.0,
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
      sellerName: data['sellerName'],
      sellerImageUrl: data['sellerImageUrl'],
      sellerKkosunnaeScore: (data['sellerKkosunnaeScore'] ?? 50.0).toDouble(),
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
      'sellerName': sellerName,
      'sellerImageUrl': sellerImageUrl,
      'sellerKkosunnaeScore': sellerKkosunnaeScore,
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
    String? sellerName,
    String? sellerImageUrl,
    double? sellerKkosunnaeScore,
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
      sellerName: sellerName ?? this.sellerName,
      sellerImageUrl: sellerImageUrl ?? this.sellerImageUrl,
      sellerKkosunnaeScore: sellerKkosunnaeScore ?? this.sellerKkosunnaeScore,
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
        sellerName,
        sellerImageUrl,
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
  care('돌봄', AppIcons.care),
  walk('산책', AppIcons.walk),
  bath('목욕', AppIcons.bath),
  training('훈련', AppIcons.training),
  other('기타', AppIcons.more);

  final String label;
  final IconData icon;

  const JobType(this.label, this.icon);
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
  final String? startTime; // 시작 시간 (HH:mm 형식)
  final String? endTime; // 종료 시간 (HH:mm 형식)
  final bool isTimeFlexible; // 시간 미정 여부
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
    this.startTime,
    this.endTime,
    this.isTimeFlexible = false,
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

  String get priceString => '${_formatPrice(price)}원/$priceUnit';
  
  /// 가격 포맷팅 (천 단위 콤마)
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String get periodString {
    if (startDate != null && endDate != null) {
      return '${startDate!.month}/${startDate!.day} ~ ${endDate!.month}/${endDate!.day}';
    }
    if (duration != null) {
      return '$duration시간';
    }
    return '';
  }
  
  /// 시간 문자열 (시간 미정 포함)
  String get timeString {
    if (isTimeFlexible) {
      return '시간 미정';
    }
    final startStr = startTime ?? '미정';
    final endStr = endTime ?? '미정';
    if (startTime != null || endTime != null) {
      return '$startStr ~ $endStr';
    }
    return '';
  }
  
  /// 기간 + 시간 전체 문자열
  String get fullPeriodString {
    final period = periodString;
    final time = timeString;
    if (period.isNotEmpty && time.isNotEmpty) {
      return '$period ($time)';
    }
    return period.isNotEmpty ? period : time;
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
      startTime: data['startTime'],
      endTime: data['endTime'],
      isTimeFlexible: data['isTimeFlexible'] ?? false,
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
      'startTime': startTime,
      'endTime': endTime,
      'isTimeFlexible': isTimeFlexible,
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
        startTime,
        endTime,
        isTimeFlexible,
        duration,
        location,
        address,
        imageUrls,
        chatCount,
        createdAt,
        updatedAt,
      ];
}
