# 📚 MINGRR 가이드 파일 계획

> 프로젝트 가이드 문서 작성 진행 상황을 추적합니다.  
> 작업 완료 시 `[ ]`를 `[x]`로 변경하세요.

---

## ✅ 작성 완료 (4/50)

| 상태 | 파일명 | 설명 |
|:---:|-------|------|
| [x] | `KKOSUNNAE_GUIDE.md` | 꼬순내지수 (보호자 신뢰도) |
| [x] | `COMPATIBILITY_GUIDE.md` | 반려동물 궁합 알고리즘 |
| [x] | `DATING_GUIDE.md` | 데이팅 메뉴 |
| [x] | `TERMINOLOGY.md` | 용어 정의 |

---

## 📱 기능별 가이드 (0/14)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `MARKETPLACE_GUIDE.md` | 마켓 (중고거래) | `marketplace/`, `marketplace_model.dart` |
| [ ] | `CHAT_GUIDE.md` | 채팅 시스템 | `chat/`, `chat_model.dart`, `chat_service.dart` |
| [ ] | `SOCIAL_GUIDE.md` | 소모임/커뮤니티 | `social/`, `group_model.dart`, `community_post_model.dart` |
| [ ] | `HEALTH_GUIDE.md` | 건강수첩 | `health/`, `health_model.dart` |
| [ ] | `PET_GUIDE.md` | 반려동물 관리 | `pet/`, `pet_model.dart`, `pet_constants.dart` |
| [ ] | `PROFILE_GUIDE.md` | 프로필/설정 | `profile/`, `user_model.dart` |
| [ ] | `WALK_GUIDE.md` | 산책 기능 | `walk/`, `location_service.dart` |
| [ ] | `NOTIFICATION_GUIDE.md` | 알림 시스템 | `notification/`, `notification_model.dart`, `notification_service.dart` |
| [ ] | `RATING_GUIDE.md` | 평가 시스템 | `rating_model.dart`, `rating_service.dart`, `rating_widgets.dart` |
| [ ] | `BREEDING_GUIDE.md` | 교배 시스템 | `breeding_model.dart`, `breeding_write_screen.dart` |
| [ ] | `HOME_GUIDE.md` | 홈 화면/배너 | `home/`, `home_reminder_provider.dart`, `home_reminder_banner.dart` |
| [ ] | `BLOCK_GUIDE.md` | 차단 기능 | `block_provider.dart`, `report_sheet.dart` |
| [ ] | `FAVORITE_GUIDE.md` | 찜 목록 기능 | `favorite_provider.dart`, `favorite_service.dart` |
| [ ] | `SEARCH_GUIDE.md` | 검색 기능 | `search_screen.dart`, `search_bar.dart` |

---

## 🔧 기술/인프라 가이드 (0/12)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `FIREBASE_GUIDE.md` | Firebase 연동 (Auth, Firestore, Storage) | `firebase_service.dart`, `firestore_service.dart`, `storage_service.dart` |
| [ ] | `DATABASE_GUIDE.md` | Firestore DB 구조/모델 | `models/` (12개 모델), `FIRESTORE_STRUCTURE.md` |
| [ ] | `AUTH_GUIDE.md` | 회원체계/인증 (소셜로그인, 본인인증) | `auth/`, `auth_service.dart`, `user_model.dart` |
| [ ] | `LOCATION_GUIDE.md` | 위치 서비스 (카카오맵, 위치인증) | `location_service.dart`, `geocoding_service.dart`, `location_provider.dart`, `map/` |
| [ ] | `VERIFICATION_GUIDE.md` | 인증 시스템 (본인/위치/동물등록) | `animal_registration_service.dart`, `location_verification_provider.dart`, `verification_badge.dart` |
| [ ] | `IMAGE_GUIDE.md` | 이미지 처리 (업로드, 크롭, 갤러리) | `image_utils.dart`, `image_crop_service.dart`, `image_picker_sheet.dart` |
| [ ] | `RIVERPOD_GUIDE.md` | 상태관리 (Provider 구조) | `providers/` (12개 파일) |
| [ ] | `SHARE_GUIDE.md` | 공유 기능 | `share_service.dart` |
| [ ] | `GEOHASH_GUIDE.md` | GeoHash 위치 검색 | `geohash_service.dart`, `firestore.indexes.json` |
| [ ] | `PAGINATION_GUIDE.md` | 페이지네이션/무한스크롤 | `paginated_state.dart`, `paginated_provider.dart` |
| [ ] | `CACHING_GUIDE.md` | 캐싱 전략 (keepAlive) | `paginated_provider.dart`, 각 Provider |
| [ ] | `MATCHING_GUIDE.md` | 매칭 알고리즘 | `matching_service.dart`, `dating_service.dart` |

---

## 🎨 디자인/UI 가이드 (0/10)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `THEME_GUIDE.md` | 테마 시스템 (라이트/다크, 색상) | `app_theme.dart`, `feature_colors.dart`, `theme_provider.dart` |
| [ ] | `TYPOGRAPHY_GUIDE.md` | 타이포그래피/폰트 | `app_text_styles.dart`, `Pretendard` 폰트 |
| [ ] | `COMPONENT_GUIDE.md` | 공통 위젯/컴포넌트 | `common_widgets.dart`, `form_components.dart`, `filter_components.dart` |
| [ ] | `MODAL_GUIDE.md` | 모달/바텀시트 | `mingrr_bottom_sheet.dart`, `guardian_profile_modal.dart`, `pet_profile_modal.dart` |
| [ ] | `ICON_GUIDE.md` | 아이콘/SVG | `svg_icons.dart`, `assets/icons/` |
| [ ] | `SIZING_GUIDE.md` | 사이즈/간격 상수 | `app_sizes.dart` |
| [ ] | `LOADING_GUIDE.md` | 로딩/스켈레톤 UI | `loading_widgets.dart`, `skeleton_widgets.dart`, `common_widgets.dart` |
| [ ] | `DIALOG_GUIDE.md` | 다이얼로그 시스템 | `dialogs/` (8개 파일), `confirm_sheet.dart` |
| [ ] | `CARD_GUIDE.md` | 카드 컴포넌트 | `dating_card.dart`, `product_card.dart`, `profile_cards.dart` |
| [ ] | `REFRESH_GUIDE.md` | Pull-to-Refresh | `refresh_wrapper.dart` |

---

## 📖 개발 가이드 (0/6)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `PROJECT_STRUCTURE_GUIDE.md` | 프로젝트 구조/아키텍처 | 전체 폴더 구조 |
| [ ] | `ERROR_HANDLING_GUIDE.md` | 에러 처리/로깅 | `error_handler.dart`, `app_logger.dart` |
| [ ] | `VALIDATION_GUIDE.md` | 입력 검증/폼 | `validators.dart`, `form_strings.dart` |
| [ ] | `SEED_DATA_GUIDE.md` | 테스트 데이터 | `seed_data.dart` |
| [ ] | `FIRESTORE_INDEX_GUIDE.md` | Firestore 인덱스 설정 | `firestore.indexes.json`, `firestore.rules` |
| [ ] | `FORMAT_UTILS_GUIDE.md` | 포맷팅 유틸리티 | `format_utils.dart` |

---

## 📊 진행 현황

| 카테고리 | 완료 | 전체 | 진행률 |
|---------|:---:|:---:|:-----:|
| ✅ 작성 완료 | 4 | 4 | 100% |
| 📱 기능별 | 0 | 14 | 0% |
| 🔧 기술/인프라 | 0 | 12 | 0% |
| 🎨 디자인/UI | 0 | 10 | 0% |
| 📖 개발 | 0 | 6 | 0% |
| **총합** | **4** | **46** | **9%** |

---

## 🔥 우선순위 (권장 작업 순서)

### 1순위 - 핵심 인프라
1. `FIREBASE_GUIDE.md` - Firebase 연동 핵심
2. `DATABASE_GUIDE.md` - DB 모델 구조
3. `AUTH_GUIDE.md` - 회원체계
4. `PAGINATION_GUIDE.md` - 페이지네이션/무한스크롤 ⭐ NEW

### 2순위 - 주요 기능
5. `MARKETPLACE_GUIDE.md` - 마켓 기능
6. `CHAT_GUIDE.md` - 채팅 시스템
7. `SOCIAL_GUIDE.md` - 소모임
8. `NOTIFICATION_GUIDE.md` - 알림 시스템 ⭐ NEW
9. `BLOCK_GUIDE.md` - 차단 기능 ⭐ NEW
10. `FAVORITE_GUIDE.md` - 찜 목록 ⭐ NEW

### 3순위 - 디자인/UI
11. `THEME_GUIDE.md` - 디자인 테마
12. `COMPONENT_GUIDE.md` - 공통 컴포넌트
13. `LOADING_GUIDE.md` - 로딩/스켈레톤 UI ⭐ NEW
14. `DIALOG_GUIDE.md` - 다이얼로그 시스템 ⭐ NEW

### 4순위 - 기술/성능
15. `GEOHASH_GUIDE.md` - GeoHash 위치 검색 ⭐ NEW
16. `CACHING_GUIDE.md` - 캐싱 전략 ⭐ NEW
17. `SEARCH_GUIDE.md` - 검색 기능 ⭐ NEW
18. `LOCATION_GUIDE.md` - 위치/카카오맵

### 5순위 - 기타
19. 나머지 가이드들...

---

## 📝 신규 추가 가이드 (2025-01-20)

| 파일명 | 설명 | 추가 이유 |
|-------|------|----------|
| `BLOCK_GUIDE.md` | 차단 기능 | 사용자 차단/신고 시스템 |
| `FAVORITE_GUIDE.md` | 찜 목록 기능 | 상품/반려동물 찜하기 |
| `SEARCH_GUIDE.md` | 검색 기능 | 통합 검색 시스템 |
| `GEOHASH_GUIDE.md` | GeoHash 위치 검색 | 위치 기반 검색 최적화 |
| `PAGINATION_GUIDE.md` | 페이지네이션 | 무한 스크롤/커서 기반 |
| `CACHING_GUIDE.md` | 캐싱 전략 | keepAlive 패턴 |
| `MATCHING_GUIDE.md` | 매칭 알고리즘 | 반려동물 매칭 로직 |
| `LOADING_GUIDE.md` | 로딩/스켈레톤 | 로딩 상태 UI |
| `DIALOG_GUIDE.md` | 다이얼로그 | 모달/다이얼로그 시스템 |
| `CARD_GUIDE.md` | 카드 컴포넌트 | 공통 카드 위젯 |
| `REFRESH_GUIDE.md` | Pull-to-Refresh | 새로고침 래퍼 |
| `FIRESTORE_INDEX_GUIDE.md` | Firestore 인덱스 | 복합 인덱스 설정 |
| `FORMAT_UTILS_GUIDE.md` | 포맷팅 유틸리티 | 날짜/가격/거리 포맷 |

---

*최종 업데이트: 2025-01-20*
