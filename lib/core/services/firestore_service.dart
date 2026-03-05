import 'firestore/firestore_base.dart';
import 'firestore/user_firestore.dart';
import 'firestore/pet_firestore.dart';
import 'firestore/chat_firestore.dart';
import 'firestore/dating_firestore.dart';
import 'firestore/product_firestore.dart';
import 'firestore/group_firestore.dart';
import 'firestore/job_firestore.dart';
import 'firestore/breeding_firestore.dart';
import 'firestore/verification_firestore.dart';
import 'firestore/block_firestore.dart';
import 'firestore/search_firestore.dart';
import 'firestore/community_firestore.dart';

/// ============================================================
/// Firestore 서비스 (도메인별 mixin 합성)
/// 
/// 각 도메인 로직은 개별 mixin 파일에 구현되어 있으며,
/// 이 클래스가 모든 mixin을 합성하여 단일 API를 제공합니다.
/// 
/// 도메인 mixin 파일:
/// - [UserFirestore]         : 사용자 CRUD, 활동 통계, GeoHash
/// - [PetFirestore]          : 반려동물 CRUD, 등록 인증 연결, 페이지네이션
/// - [ChatFirestore]         : 채팅방/메시지 CRUD
/// - [DatingFirestore]       : 데이팅 신청/매칭
/// - [ProductFirestore]      : 상품 CRUD, 찜, 페이지네이션, GeoHash
/// - [GroupFirestore]        : 소모임 CRUD, 일정, 좋아요, 가입 신청, GeoHash
/// - [JobFirestore]          : 알바 CRUD, 페이지네이션
/// - [BreedingFirestore]     : 교배 글 CRUD
/// - [VerificationFirestore] : 본인/동물등록 인증
/// - [BlockFirestore]        : 사용자 차단
/// - [SearchFirestore]       : 통합 검색
/// - [CommunityFirestore]    : 커뮤니티 게시글 페이지네이션
/// ============================================================
class FirestoreService extends FirestoreBase
    with
        UserFirestore,
        PetFirestore,
        ChatFirestore,
        DatingFirestore,
        ProductFirestore,
        GroupFirestore,
        JobFirestore,
        BreedingFirestore,
        VerificationFirestore,
        BlockFirestore,
        SearchFirestore,
        CommunityFirestore {}
