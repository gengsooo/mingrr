# MINGRR 2차 리팩토링 가이드 (V2)

> 작성일: 2026-01-18  
> 완료일: 2026-01-20  
> 상태: ✅ **완료**  
> 목적: V1 완료 후 디자인 통일성, 성능, UX, 백엔드 연동 종합 분석 및 개선

---

## ✅ 완료된 작업 (2026-01-20)

### Phase 1: 백엔드 연동 완료

| 작업 | 수정 파일 | 상태 |
|------|----------|:----:|
| **차단 기능 구현** | `firebase_service.dart`, `firestore_service.dart`, `pet_detail_screen.dart`, `product_detail_screen.dart` | ✅ 완료 |
| **찜 목록 백엔드 연동** | `firestore_service.dart`, `product_detail_screen.dart` | ✅ 완료 |
| **알림 네비게이션 구현** | `notification_service.dart`, `app.dart` | ✅ 완료 |
| **인앱 알림 UI 구현** | `notification_service.dart` | ✅ 완료 |
| **채팅 차단 기능 추가** | `chat_detail_screen.dart` | ✅ 완료 |
| **차단된 사용자 필터링** | `block_provider.dart`, `dating_provider.dart`, `marketplace_provider.dart`, `community_provider.dart` | ✅ 완료 |
| **찜 목록 API 개선** | `profile_provider.dart`, `wishlist_screen.dart` | ✅ 완료 |
| **가입 신청 관리 화면** | `group_detail_screen.dart`, `firestore_service.dart`, `firebase_service.dart` | ✅ 완료 |
| **고객센터 URL 설정** | `customer_service_screen.dart` | ✅ 완료 |
| **앱 정보 URL 설정 + 공통화** | `app_info_screen.dart` | ✅ 완료 |

### Phase 2: 공통 컴포넌트 통일

| 작업 | 수정 파일 | 상태 |
|------|----------|:----:|
| **ElevatedButton → MingrrButton** | `pet_detail_screen.dart`, `product_detail_screen.dart`, `dating_screen.dart`, `onboarding_screen.dart`, `profile_screen.dart`, `rating_widgets.dart`, `chat_list_screen.dart`, `mingrr_bottom_sheet.dart`, `app_dialog.dart`, `confirm_sheet.dart`, `error_dialog.dart`, `info_dialog.dart`, `request_sheet.dart`, `report_sheet.dart`, `guardian_profile_modal.dart`, `image_picker_sheet.dart`, `dating_card.dart`, `health_screen.dart`, `job_detail_screen.dart`, `map_location_picker.dart`, `pet_selector_card.dart`, `group_detail_screen.dart`, `home_screen.dart`, `community_detail_screen.dart` | ✅ 완료 |
| **debugPrint → AppLogger** | `pet_detail_screen.dart`, `location_helper.dart` | ✅ 완료 |

### 신규 추가된 기능

#### 1. 차단 기능 (`firestore_service.dart`)
```dart
// 사용자 차단
await firestoreService.blockUser(blockerId, blockedId);

// 차단 해제
await firestoreService.unblockUser(blockerId, blockedId);

// 차단 여부 확인
final isBlocked = await firestoreService.isUserBlocked(blockerId, blockedId);

// 차단한 사용자 목록
final blockedIds = await firestoreService.getBlockedUserIds(userId);
```

#### 2. 상품 찜 기능 (`firestore_service.dart`)
```dart
// 찜하기 토글
final isNowLiked = await firestoreService.toggleProductLike(productId, userId);

// 찜 여부 확인
final isLiked = await firestoreService.isProductLiked(productId, userId);

// 찜한 상품 목록
final likedProducts = await firestoreService.getUserLikedProducts(userId);
```

#### 3. 알림 네비게이션 (`notification_service.dart`)
- 알림 타입별 화면 이동 로직 구현
- 인앱 알림 SnackBar UI 구현
- `navigateFromNotification()` 메서드 추가

---

## �️ V2 개발 로드맵 (체크리스트)

> 하나씩 차근히 진행하세요. 완료되면 체크 표시(✅)로 변경합니다.

### 📅 Phase 1: 백엔드 연동 (우선순위: 높음)

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 1-1 | 차단 기능 구현 | `firestore_service.dart`, `pet_detail_screen.dart`, `product_detail_screen.dart` | 2시간 | ✅ 완료 |
| 1-2 | 찜 목록 백엔드 연동 | `firestore_service.dart`, `product_detail_screen.dart` | 1시간 | ✅ 완료 |
| 1-3 | 알림 네비게이션 구현 | `notification_service.dart` | 1시간 | ✅ 완료 |
| 1-4 | 인앱 알림 UI 구현 | `notification_service.dart` | 30분 | ✅ 완료 |
| 1-5 | 채팅 차단 기능 추가 | `chat_detail_screen.dart` | 30분 | ✅ 완료 |
| 1-6 | 차단된 사용자 필터링 | `block_provider.dart`, `dating_provider.dart`, `marketplace_provider.dart`, `community_provider.dart` | 1시간 | ✅ 완료 |
| 1-7 | 가입 신청 관리 화면 | `group_detail_screen.dart`, `firestore_service.dart`, `firebase_service.dart` | 2시간 | ✅ 완료 |
| 1-8 | 고객센터 URL 설정 | `customer_service_screen.dart` | 30분 | ✅ 완료 |
| 1-9 | 앱 정보 URL 설정 + 공통화 | `app_info_screen.dart` | 30분 | ✅ 완료 |

### 📅 Phase 2: 디자인 통일성 - 버튼 (우선순위: 높음)

| # | 작업 | 대상 파일 | 변경 수 | 상태 |
|:-:|------|----------|:------:|:----:|
| 2-1 | ElevatedButton → MingrrButton | `profile_screen.dart` | 14개 | ✅ 완료 |
| 2-2 | ElevatedButton → MingrrButton | `rating_widgets.dart` | 6개 | ✅ 완료 |
| 2-3 | ElevatedButton → MingrrButton | `chat_list_screen.dart` | 3개 | ✅ 완료 |
| 2-4 | ElevatedButton → MingrrButton | `mingrr_bottom_sheet.dart` | 2개 | ✅ 완료 |
| 2-5 | ElevatedButton → MingrrButton | `app_dialog.dart` | 4개 | ✅ 완료 |
| 2-6 | ElevatedButton → MingrrButton | `pet_detail_screen.dart` | - | ✅ 완료 |
| 2-7 | ElevatedButton → MingrrButton | `product_detail_screen.dart` | - | ✅ 완료 |
| 2-8 | ElevatedButton → MingrrButton | `dating_screen.dart` | - | ✅ 완료 |
| 2-9 | ElevatedButton → MingrrButton | `onboarding_screen.dart` | - | ✅ 완료 |
| 2-10 | ElevatedButton → MingrrButton | `confirm_sheet.dart` | 1개 | ✅ 완료 |
| 2-11 | ElevatedButton → MingrrButton | `error_dialog.dart` | 1개 | ✅ 완료 |
| 2-12 | ElevatedButton → MingrrButton | `info_dialog.dart` | 1개 | ✅ 완료 |
| 2-13 | ElevatedButton → MingrrButton | `request_sheet.dart` | 1개 | ✅ 완료 |
| 2-14 | ElevatedButton → MingrrButton | `report_sheet.dart` | 1개 | ✅ 완료 |
| 2-15 | ElevatedButton → MingrrButton | `guardian_profile_modal.dart` | 1개 | ✅ 완료 |
| 2-16 | ElevatedButton → MingrrButton | `image_picker_sheet.dart` | 1개 | ✅ 완료 |
| 2-17 | ElevatedButton → MingrrButton | `dating_card.dart` | 1개 | ✅ 완료 |
| 2-18 | ElevatedButton → MingrrButton | `health_screen.dart` | 1개 | ✅ 완료 |
| 2-19 | ElevatedButton → MingrrButton | `job_detail_screen.dart` | 1개 | ✅ 완료 |
| 2-20 | ElevatedButton → MingrrButton | `map_location_picker.dart` | 1개 | ✅ 완료 |
| 2-21 | ElevatedButton → MingrrButton | `pet_selector_card.dart` | 1개 | ✅ 완료 |
| 2-22 | ElevatedButton → MingrrButton | `group_detail_screen.dart` | 1개 | ✅ 완료 |
| 2-23 | ElevatedButton → MingrrButton | `home_screen.dart` | 1개 | ✅ 완료 |
| 2-24 | ElevatedButton → MingrrButton | `community_detail_screen.dart` | 1개 | ✅ 완료 |

### 📅 Phase 3: 디자인 통일성 - 로딩/바텀시트 (우선순위: 중간)

| # | 작업 | 대상 파일 | 변경 수 | 상태 |
|:-:|------|----------|:------:|:----:|
| 3-1 | CircularProgressIndicator → MingrrLoadingIndicator | `kkosunnae_widgets.dart` | 1개 | ✅ 완료 |
| 3-2 | CircularProgressIndicator → MingrrLoadingIndicator | `map_location_picker.dart` | 1개 | ✅ 완료 |
| 3-3 | CircularProgressIndicator → MingrrLoadingIndicator | `chat_detail_screen.dart` | 3개 | ✅ 완료 |
| 3-4 | CircularProgressIndicator → MingrrLoadingIndicator | `profile_screen.dart` | 2개 | ✅ 완료 |
| 3-5 | CircularProgressIndicator → MingrrLoadingIndicator | `community_detail_screen.dart` | 2개 | ✅ 완료 |
| 3-6 | CircularProgressIndicator → MingrrLoadingIndicator | `home_screen.dart` | 1개 | ✅ 완료 |
| 3-7 | CircularProgressIndicator → MingrrLoadingIndicator | `group_detail_screen.dart` | 1개 | ✅ 완료 |
| 3-8 | showModalBottomSheet | 공통 컴포넌트 내부 사용 | - | ⏭️ 스킵 |
| 3-9 | MingrrLoadingIndicator 진행률 옵션 추가 | `loading_widgets.dart` | 1개 | ✅ 완료 |
| 3-10 | MingrrButton 내부 로딩 통일 | `common_widgets.dart` | 3개 | ✅ 완료 |
| 3-11 | 지도 로딩 위젯 통일 | `map_loading_widget.dart` | 2개 | ✅ 완료 |
| 3-12 | 채팅 이미지 진행률 통일 | `chat_detail_screen.dart` | 1개 | ✅ 완료 |
| 3-13 | 건강 기록 진행률 통일 | `health_record_detail_screens.dart` | 1개 | ✅ 완료 |

### 📅 Phase 4: 성능 최적화 - 로깅 (우선순위: 중간)

| # | 작업 | 대상 파일 | 변경 수 | 상태 |
|:-:|------|----------|:------:|:----:|
| 4-1 | debugPrint → AppLogger | `location_helper.dart` | 39개 | ✅ 완료 |
| 4-2 | debugPrint → AppLogger | `main.dart` | 6개 | ✅ 완료 |
| 4-3 | debugPrint → AppLogger | `firebase_service.dart` | 3개 | ✅ 완료 |
| 4-4 | debugPrint → AppLogger | `geocoding_service.dart` | 3개 | ✅ 완료 |
| 4-5 | debugPrint → AppLogger | `animal_registration_service.dart` | 5개 | ✅ 완료 |
| 4-6 | debugPrint → AppLogger | `bottom_sheet_stack_manager.dart` | 4개 | ✅ 완료 |
| 4-7 | debugPrint → AppLogger | `location_verification_provider.dart` | 6개 | ✅ 완료 |
| 4-8 | debugPrint → AppLogger | `video_utils.dart` | 3개 | ✅ 완료 |
| 4-9 | debugPrint → AppLogger | `image_utils.dart` | 2개 | ✅ 완료 |
| 4-10 | debugPrint → AppLogger | `pet_profile_modal.dart` | 2개 | ✅ 완료 |
| 4-11 | debugPrint → AppLogger | `svg_icons.dart` | 1개 | ✅ 완료 |
| 4-12 | debugPrint → AppLogger | `map_location_picker.dart` | 15개 | ✅ 완료 |
| 4-13 | debugPrint → AppLogger | `walk_screen.dart` | 23개 | ✅ 완료 |
| 4-14 | debugPrint → AppLogger | `chat_detail_screen.dart` | 17개 | ✅ 완료 |
| 4-15 | debugPrint → AppLogger | `profile_screen.dart` | 8개 | ✅ 완료 |
| 4-16 | debugPrint → AppLogger | `walk_record_detail_screen.dart` | 1개 | ✅ 완료 |

### 📅 Phase 5: 신규 공통 컴포넌트 (우선순위: 낮음)

| # | 작업 | 생성 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 5-1-1 | 스켈레톤 기본 컴포넌트 생성 | `skeleton_widgets.dart` | 1시간 | ✅ 완료 |
| 5-1-2 | dating_screen.dart 적용 | `dating_screen.dart` | 30분 | ✅ 완료 |
| 5-1-3 | chat_list_screen.dart 적용 | `chat_list_screen.dart` | 20분 | ✅ 완료 |
| 5-1-4 | marketplace_screen.dart 적용 | `marketplace_screen.dart` | 20분 | ✅ 완료 |
| 5-1-5 | notification_screen.dart 적용 | `notification_screen.dart` | 15분 | ✅ 완료 |
| 5-1-6 | community_screen.dart 적용 | `community_screen.dart` | 15분 | ✅ 완료 |
| 5-1-7 | home_screen.dart 적용 | `home_screen.dart` | 15분 | ✅ 완료 |
| 5-1-8 | activity_history_screen.dart 적용 | `activity_history_screen.dart` | 15분 | ✅ 완료 |
| 5-1-9 | transaction_history_screen.dart 적용 | `transaction_history_screen.dart` | 15분 | ✅ 완료 |
| 5-1-10 | wishlist_screen.dart 적용 | `wishlist_screen.dart` | 10분 | ✅ 완료 |
| 5-1-11 | received_dating_requests_screen.dart 적용 | `received_dating_requests_screen.dart` | 10분 | ✅ 완료 |
| 5-1-12 | group_detail_screen.dart 적용 | `group_detail_screen.dart` | 15분 | ✅ 완료 |
| 5-2-1 | ConfirmSheetType 확장 (차단/거절) | `confirm_sheet.dart` | 15분 | ✅ 완료 |
| 5-2-2 | 4개 화면 AlertDialog → ConfirmSheet | 4개 화면 | 20분 | ✅ 완료 |
| 5-2-3 | MingrrSelectionDialog 생성 | `selection_dialog.dart` | 30분 | ✅ 완료 |
| 5-2-4 | MingrrImageViewer 생성 | `image_viewer.dart` | 30분 | ✅ 완료 |
| 5-2-5 | MingrrInputDialog 생성 | `input_dialog.dart` | 30분 | ✅ 완료 |
| 5-2-6 | 이미지 뷰어 통합 | `mingrr_image_viewer.dart` | 30분 | ✅ 완료 |
| 5-2-7 | MingrrInfoActionDialog 생성 | `info_action_dialog.dart` | 30분 | ✅ 완료 |
| 5-2-8 | MingrrActionPromptDialog 생성 | `action_prompt_dialog.dart` | 30분 | ✅ 완료 |
| 5-2-9 | 본인인증 다이얼로그 → ConfirmSheet | `profile_screen.dart` | 10분 | ✅ 완료 |
| 5-3-1 | MingrrRefreshWrapper 생성 | `refresh_wrapper.dart` | 30분 | ✅ 완료 |
| 5-3-2 | 기존 3개 화면 교체 | community, community_detail, group_list | 15분 | ✅ 완료 |
| 5-3-3 | chat_list_screen 적용 | `chat_list_screen.dart` | 10분 | ✅ 완료 |
| 5-3-4 | notification_screen 적용 | `notification_screen.dart` | 10분 | ✅ 완료 |
| 5-3-5 | marketplace_screen 적용 | `marketplace_screen.dart` | 10분 | ✅ 완료 |
| 5-3-6 | dating_screen 적용 (3개 탭) | `dating_screen.dart` | 15분 | ✅ 완료 |
| 5-4-1 | PaginatedState 모델 생성 | `paginated_state.dart` | 20분 | ✅ 완료 |
| 5-4-2 | PaginatedNotifier 생성 | `paginated_provider.dart` | 40분 | ✅ 완료 |
| 5-4-3 | community_screen 페이지네이션 적용 | `community_screen.dart` | 30분 | ✅ 완료 |
| 5-4-4 | group_list_screen 페이지네이션 적용 | `group_list_screen.dart` | 25분 | ✅ 완료 |
| 5-4-5 | marketplace_screen 페이지네이션 적용 | `marketplace_screen.dart` | 30분 | ✅ 완료 |
| 5-4-6 | dating_screen 페이지네이션 적용 (3개 탭) | `dating_screen.dart` | 40분 | ✅ 완료 |
| 5-5-1 | GeoHash 서비스 생성 | `geohash_service.dart` | 30분 | ✅ 완료 |
| 5-5-2 | 서버 사이드 필터링 메서드 추가 | `firestore_service.dart` | 40분 | ✅ 완료 |
| 5-5-3 | 캐싱 전략 적용 (keepAlive) | 모든 페이지네이션 Provider | 20분 | ✅ 완료 |
| 5-5-4 | Firestore GeoHash 인덱스 추가 | `firestore.indexes.json` | 10분 | ✅ 완료 |
| 5-6 | MingrrSearchBar 위젯 분리 | `search_bar.dart` | 20분 | ✅ 완료 |

### 📅 Phase 6: 코드 정리 (우선순위: 낮음)

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 6-1 | Deprecated 항목 제거 | 전체 | 1시간 | ⬜ 대기 |
| 6-2 | 미사용 import 정리 | 전체 | 30분 | ⬜ 대기 |
| 6-3 | TODO 주석 정리 | 전체 (63개) | 2시간 | ⬜ 대기 |
| 6-4 | Mock 데이터 분리 | `seed_data.dart` 등 | 1시간 | ⬜ 대기 |

---

### 📊 진행 현황 요약

| Phase | 전체 | 완료 | 진행률 |
|:-----:|:----:|:----:|:------:|
| Phase 1: 백엔드 연동 | 9 | 9 | **100%** ✅ |
| Phase 2: 버튼 통일 | 24 | 24 | **100%** ✅ |
| Phase 3: 로딩/바텀시트 | 13 | 13 | **100%** ✅ |
| Phase 4: 로깅 최적화 | 16 | 16 | **100%** ✅ |
| Phase 5: 신규 컴포넌트 | 41 | 41 | **100%** ✅ |
| Phase 6: 코드 정리 | 4 | 0 | **0%** (V3로 이관) |
| **전체** | **107** | **103** | **96%** |

---

## �📊 V2 리팩토링 개요

V1에서 공통 컴포넌트화를 완료했습니다. V2에서는 다음 영역을 집중적으로 개선합니다:

| 영역 | 목표 |
|------|------|
| **🎨 디자인 통일성** | 남은 불일치 요소 해결 |
| **⚡ 성능 최적화** | 로딩 속도, 메모리 사용량 개선 |
| **👤 UX 개선** | 사용자 편의성 향상 |
| **🔧 백엔드 연동** | TODO 항목 완료, 미연동 기능 구현 |
| **🧹 코드 품질** | 디버그 코드 정리, 테스트 데이터 분리 |

---

## 🔴 1. 백엔드 연동 미완료 항목 (우선순위: 높음)

### 1.1 TODO 항목 분석 (68개 발견)

#### 핵심 기능 미구현 (즉시 수정 필요)

| 파일 | 위치 | TODO 내용 | 우선순위 |
|------|------|----------|---------|
| `dating_screen.dart` | 465줄 | 교배 신청 DB 저장 미구현 | 🔴 높음 |
| `pet_detail_screen.dart` | 834줄 | 차단 기능 미구현 | 🔴 높음 |
| `product_detail_screen.dart` | 118줄 | 찜 목록 백엔드 연동 미구현 | 🔴 높음 |
| `product_detail_screen.dart` | 502줄 | 판매자 차단 기능 미구현 | 🔴 높음 |
| `group_detail_screen.dart` | 882줄 | 가입 신청 관리 화면 미구현 | 🔴 높음 |
| `notification_service.dart` | 143줄 | 알림 탭 네비게이션 미구현 | 🔴 높음 |
| `notification_service.dart` | 150줄 | 인앱 알림 UI 미구현 | 🟡 중간 |

#### 설정/정보 화면 미구현

| 파일 | TODO 내용 | 우선순위 |
|------|----------|---------|
| `customer_service_screen.dart` | 6개 TODO - 고객센터 기능들 | 🟡 중간 |
| `app_info_screen.dart` | 이용약관/개인정보처리방침 URL 설정 | 🟡 중간 |

#### 공유 기능 미구현

| 파일 | TODO 내용 | 우선순위 |
|------|----------|---------|
| `product_detail_screen.dart` | 상품 공유 기능 | 🟢 낮음 |
| `group_detail_screen.dart` | 소모임 공유 기능 | 🟢 낮음 |

### 1.2 Mock 데이터 사용 중인 파일 (7개)

| 파일 | 내용 | 조치 필요 |
|------|------|----------|
| `dating_request_provider.dart` | `_mockReceivedRequests`, `_mockSentRequests` | Firebase 연동 필요 |
| `seed_data.dart` | 17개 mock 데이터 함수 | 개발 모드 전용으로 분리 |
| `chat_list_screen.dart` | 일부 mock 데이터 | Firebase 연동 확인 |
| `home_reminder_provider.dart` | mock 리마인더 | Firebase 연동 필요 |
| `location_helper.dart` | mock 위치 데이터 | 실제 위치 서비스 연동 |

### 1.3 Firebase 연동 현황

#### ✅ 완료된 연동

| 기능 | 서비스 | 상태 |
|------|--------|------|
| 사용자 인증 | `auth_service.dart` | ✅ 완료 |
| 사용자 CRUD | `firestore_service.dart` | ✅ 완료 |
| 반려동물 CRUD | `firestore_service.dart` | ✅ 완료 |
| 채팅 메시지 | `chat_service.dart` | ✅ 완료 |
| 데이팅 신청 | `dating_service.dart` | ✅ 완료 |
| 상품 CRUD | `firestore_service.dart` | ✅ 완료 |
| 소모임 CRUD | `firestore_service.dart` | ✅ 완료 |
| 커뮤니티 CRUD | `firestore_service.dart` | ✅ 완료 |
| 건강 기록 | `firestore_service.dart` | ✅ 완료 |
| 꼬순내지수 | `kkosunnae_service.dart` | ✅ 완료 |
| 평가 시스템 | `rating_service.dart` | ✅ 완료 |

#### 🔴 미완료 연동

| 기능 | 현재 상태 | 필요 작업 |
|------|----------|----------|
| ~~**차단 기능**~~ | ✅ 완료 | ~~`blocks` 컬렉션 생성, 차단 로직 구현~~ |
| ~~**찜 목록 (상품)**~~ | ✅ 완료 | ~~`productLikes` 컬렉션 연동~~ |
| ~~**알림 네비게이션**~~ | ✅ 완료 | ~~GoRouter 연동~~ |
| ~~**인앱 알림 UI**~~ | ✅ 완료 | ~~OverlayEntry 또는 SnackBar 구현~~ |
| **가입 신청 관리** | TODO 상태 | 화면 및 로직 구현 |
| **FCM 푸시 알림** | 주석 처리됨 | Personal Team 제한 해제 후 활성화 |

---

## 🎨 2. 디자인 통일성 개선 (우선순위: 중간)

### 2.1 남은 불일치 요소

| 영역 | 현재 상태 | 개선 방안 |
|------|----------|----------|
| **에러 메시지 스타일** | 화면마다 다름 | `MingrrErrorState` 통일 사용 |
| **확인 다이얼로그** | 일부 개별 구현 | `showMingrrConfirmDialog` 통일 |
| **토스트/스낵바** | 대부분 통일됨 | 남은 `ScaffoldMessenger` 직접 호출 제거 |
| **아이콘 사용** | 일부 하드코딩 | `svg_icons.dart` 중앙화 |

### 2.2 색상 상수 미사용 영역

| 파일 | 문제 | 해결 |
|------|------|------|
| 일부 화면 | 하드코딩된 색상값 | `FeatureColors`, `ColorScheme` 사용 |
| 그라데이션 | 개별 정의 | 공통 그라데이션 상수화 |

### 2.3 폰트 스타일 불일치

| 영역 | 현재 | 개선 |
|------|------|------|
| 일부 `TextStyle` | 직접 정의 | `AppTextStyles` 사용 |
| `fontWeight` | 다양한 값 사용 | w400, w500, w600, w700만 사용 |

---

## ⚡ 3. 성능 최적화 (우선순위: 중간)

### 3.1 디버그 코드 정리 (220개 발견)

| 파일 | debugPrint 수 | 조치 |
|------|--------------|------|
| `seed_data.dart` | 57개 | 개발 모드 전용 분리 |
| `location_helper.dart` | 39개 | `AppLogger` 사용으로 교체 |
| `walk_screen.dart` | 26개 | `AppLogger` 사용으로 교체 |
| `chat_detail_screen.dart` | 17개 | `AppLogger` 사용으로 교체 |
| `map_location_picker.dart` | 15개 | `AppLogger` 사용으로 교체 |
| `notification_service.dart` | 10개 | `kDebugMode` 체크 확인 |
| 기타 16개 파일 | 56개 | `AppLogger` 사용으로 교체 |

**제안**: `AppLogger` 클래스 활용하여 릴리즈 빌드에서 자동 제거

```dart
// 현재
debugPrint('좋아요 상태 로드 오류: $e');

// 개선
AppLogger.error('좋아요 상태 로드 오류', error: e);
```

### 3.2 이미지 최적화

| 영역 | 현재 | 개선 |
|------|------|------|
| 이미지 캐싱 | `cached_network_image` 사용 | ✅ 양호 |
| 이미지 리사이징 | 업로드 시 제한 | ✅ 양호 |
| 썸네일 생성 | 일부 구현 | 리스트용 썸네일 자동 생성 추가 |
| 지연 로딩 | 미구현 | `ListView.builder` 확인 |

### 3.3 Provider 최적화

| 영역 | 현재 | 개선 |
|------|------|------|
| `autoDispose` | 대부분 적용 | ✅ 양호 |
| `family` Provider | 적절히 사용 | ✅ 양호 |
| 불필요한 리빌드 | 일부 존재 | `select` 사용 검토 |

### 3.4 Firestore 쿼리 최적화

| 영역 | 현재 | 개선 |
|------|------|------|
| 인덱스 | 기본 인덱스 | 복합 인덱스 추가 검토 |
| 페이지네이션 | 일부 구현 | 전체 리스트에 적용 |
| 캐싱 | Firestore 기본 | 오프라인 지원 강화 |

---

## 👤 4. UX 개선 (우선순위: 중간)

### 4.1 사용자 편의 기능 추가

| 기능 | 현재 | 개선 |
|------|------|------|
| **Pull to Refresh** | 일부 화면 | 모든 리스트 화면에 적용 |
| **무한 스크롤** | 일부 구현 | 전체 리스트에 적용 |
| **스켈레톤 로딩** | 미구현 | `MingrrSkeletonLoader` 추가 |
| **오프라인 모드** | 미지원 | 기본 데이터 캐싱 |
| **검색 히스토리** | 미구현 | 최근 검색어 저장 |
| **자동 저장** | 미구현 | 글쓰기 화면 임시저장 |

### 4.2 에러 처리 개선

| 영역 | 현재 | 개선 |
|------|------|------|
| 네트워크 에러 | 일반 메시지 | 구체적 안내 + 재시도 |
| 권한 에러 | 일반 메시지 | 설정 화면 이동 유도 |
| 입력 검증 | 제출 시 검증 | 실시간 검증 |

### 4.3 접근성 개선

| 영역 | 현재 | 개선 |
|------|------|------|
| Semantics | 일부 적용 | 전체 적용 |
| 색상 대비 | 양호 | WCAG AA 기준 검증 |
| 터치 영역 | 대부분 48px | 전체 확인 |

### 4.4 애니메이션 개선

| 영역 | 현재 | 개선 |
|------|------|------|
| 화면 전환 | 기본 | 커스텀 트랜지션 |
| 리스트 아이템 | 없음 | 페이드인 애니메이션 |
| 좋아요 버튼 | 없음 | 하트 애니메이션 |
| 로딩 | 스피너 | Shimmer 효과 |

---

## 🧹 5. 코드 품질 개선 (우선순위: 낮음)

### 5.1 Deprecated 항목 제거

| 파일 | Deprecated 항목 | 조치 |
|------|----------------|------|
| `firebase_service.dart` | `dogsCollection`, `dogImageRef` | 사용처 확인 후 제거 |
| `firebase_service.dart` | `likesCollection` | 사용처 확인 후 제거 |
| `common_widgets.dart` | `NotificationIconButton` | 사용처 확인 후 제거 |
| `filter_widgets.dart` | `CategoryFilterChips`, `DistanceBottomSheet` | 사용처 확인 후 제거 |
| `dating_provider.dart` | `receivedLikesProvider`, `aiRecommendedPetsProvider` | 사용처 확인 후 제거 |

### 5.2 미사용 코드 정리

| 영역 | 조치 |
|------|------|
| 미사용 import | `dart analyze` 실행 |
| 미사용 변수 | `dart analyze` 실행 |
| 미사용 파일 | 수동 검토 |

### 5.3 테스트 코드 분리

| 파일 | 현재 | 개선 |
|------|------|------|
| `seed_data.dart` | `lib/core/utils/` | `lib/dev/` 또는 `test/` 이동 |
| `dev_tools_screen.dart` | `lib/features/dev/` | 릴리즈 빌드 제외 설정 |
| Mock Provider | 프로덕션 코드에 포함 | 개발 모드 전용 분리 |

### 5.4 문서화

| 영역 | 현재 | 개선 |
|------|------|------|
| 서비스 클래스 | 일부 주석 | 전체 문서화 |
| 공통 위젯 | 일부 주석 | 사용 예시 추가 |
| API 응답 | 미문서화 | 에러 코드 문서화 |

---

## 📋 6. 리팩토링 로드맵

### Phase 1: 백엔드 연동 완료 (1주)

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 1 | 차단 기능 구현 | 4시간 |
| 2 | 찜 목록 백엔드 연동 | 2시간 |
| 3 | 교배 신청 DB 저장 | 2시간 |
| 4 | 알림 네비게이션 구현 | 3시간 |
| 5 | 가입 신청 관리 화면 | 4시간 |
| 6 | Mock 데이터 Firebase 연동 | 4시간 |

### Phase 2: 성능 최적화 (3일)

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 1 | debugPrint → AppLogger 교체 | 3시간 |
| 2 | 스켈레톤 로딩 구현 | 4시간 |
| 3 | 페이지네이션 전체 적용 | 4시간 |
| 4 | Firestore 인덱스 최적화 | 2시간 |

### Phase 3: UX 개선 (3일)

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 1 | Pull to Refresh 전체 적용 | 2시간 |
| 2 | 에러 처리 개선 | 3시간 |
| 3 | 애니메이션 추가 | 4시간 |
| 4 | 접근성 개선 | 3시간 |

### Phase 4: 코드 품질 (2일)

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 1 | Deprecated 항목 제거 | 2시간 |
| 2 | 미사용 코드 정리 | 2시간 |
| 3 | 테스트 코드 분리 | 2시간 |
| 4 | 문서화 | 4시간 |

---

## 📊 예상 효과

| 항목 | Before | After |
|------|--------|-------|
| TODO 항목 | 68개 | 0개 |
| Mock 데이터 | 프로덕션 포함 | 개발 모드 분리 |
| debugPrint | 220개 | AppLogger 통합 |
| 백엔드 연동 | 85% | 100% |
| UX 완성도 | 80% | 95% |
| 코드 품질 | B+ | A |

---

## 🧩 7. 공통화/컴포넌트화 분석 결과

### 7.1 현재 공통 컴포넌트 현황 (✅ 잘 구현됨)

#### 📁 `lib/core/widgets/` 구조 (42개 파일)

| 파일 | 컴포넌트 | 사용 빈도 | 평가 |
|------|----------|----------|------|
| `common_widgets.dart` | `MingrrButton`, `MingrrCard`, `MingrrAvatar`, `MingrrTextField`, `MingrrEmptyState`, `MingrrLoading`, `MingrrBadge`, `MingrrBackButton`, `MingrrSectionHeader`, `MingrrDateSelector` | 144회+ | ✅ 우수 |
| `mingrr_bottom_sheet.dart` | `MingrrBottomSheet`, `MingrrOptionsSheet`, `MingrrBottomButtonBar`, `MingrrSubmitButtonBar`, `MingrrInputBottomSheet` | 14회+ | ✅ 우수 |
| `filter_components.dart` | `MingrrFilterChip`, `MingrrFilterRow`, `MingrrFilterSection`, `MingrrCategoryChips`, `MingrrSortChips` | 14회+ | ✅ 우수 |
| `loading_widgets.dart` | `MingrrLoadingDialog`, `MingrrLoadingOverlay`, `MingrrLoadingIndicator`, `MingrrFullScreenLoading` | 다수 | ✅ 우수 |
| `mingrr_fab.dart` | `MingrrFAB`, `MingrrFABBuilder`, `MingrrFABColumn` | 7회+ | ✅ 우수 |
| `mingrr_settings_tile.dart` | `MingrrSettingsTile`, `MingrrSettingsSection` | 15회+ | ✅ 우수 |
| `form_components.dart` | `MingrrSectionLabel`, `MingrrSwitchRow`, `MingrrSwitchCard`, `MingrrChipSelector`, `MingrrImagePicker` | 다수 | ✅ 우수 |
| `profile_modal_components.dart` | `ProfileModalContainer`, `ProfileModalHeader`, `ProfileModalSection`, `ProfileModalHorizontalList` 등 11개 | 3개 모달 | ✅ 우수 |
| `dating_card.dart` | `DatingRecommendCard`, `DatingNearbyCard`, `DatingBreedingCard` | 3회 | ✅ 우수 |
| `info_badge.dart` | `InfoBadge`, `DistanceBadge`, `MatchScoreBadge`, `GenderAgeBadge`, `PetGenderBadge` | 다수 | ✅ 우수 |

#### 📁 `lib/core/services/` 구조 (19개 서비스)

| 서비스 | 역할 | 평가 |
|--------|------|------|
| `firebase_service.dart` | Firebase 인스턴스 중앙 관리 (싱글톤) | ✅ 우수 |
| `firestore_service.dart` | Firestore CRUD 통합 | ✅ 우수 |
| `auth_service.dart` | 인증 로직 | ✅ 우수 |
| `chat_service.dart` | 채팅 기능 | ✅ 우수 |
| `dating_service.dart` | 데이팅/교배 신청 | ✅ 우수 |
| `kkosunnae_service.dart` | 꼬순내지수 계산 | ✅ 우수 |
| `matching_service.dart` | 궁합 점수 계산 | ✅ 우수 |
| `notification_service.dart` | 알림 처리 | 🟡 TODO 있음 |

### 7.2 공통화 잘 된 점 (✅ 강점)

| 영역 | 내용 |
|------|------|
| **네이밍 컨벤션** | `Mingrr` 접두사로 통일 (MingrrButton, MingrrCard 등) |
| **기능별 색상** | `FeatureColors` 확장으로 `context.features.dating` 형태 사용 |
| **바텀시트** | 용도별 분리 (`MingrrOptionsSheet`, `MingrrInputBottomSheet` 등) |
| **FAB** | 타입별 팩토리 (`MingrrFAB.write()`, `MingrrFAB.add()`) |
| **설정 타일** | 다양한 variant (`destructive`, `toggle`, `radio`, `badge`, `connection`) |
| **로딩 상태** | 타입별 색상 지원 (`MingrrLoadingType` enum) |
| **프로필 모달** | 빌딩 블록 패턴으로 재사용성 극대화 |
| **필터 컴포넌트** | 데이팅 화면 기준 통일된 디자인 |

### 7.3 수정이 필요한 항목 (🔧 개선 필요)

#### 7.3.1 버튼 사용 불일치

| 문제 | 현황 | 해결 방안 |
|------|------|----------|
| `ElevatedButton` 직접 사용 | 106회 (20개 파일) | `MingrrButton` 사용으로 통일 |
| `profile_screen.dart` | 45회 직접 사용 | 공통 버튼으로 교체 |
| `chat_list_screen.dart` | 12회 직접 사용 | 공통 버튼으로 교체 |

**제안**: 특수한 스타일이 필요한 경우를 제외하고 `MingrrButton` 사용 권장

#### 7.3.2 로딩 인디케이터 불일치

| 문제 | 현황 | 해결 방안 |
|------|------|----------|
| `CircularProgressIndicator` 직접 사용 | 28회 (14개 파일) | `MingrrLoadingIndicator` 사용 |
| `chat_detail_screen.dart` | 4회 직접 사용 | 공통 로딩으로 교체 |

#### 7.3.3 바텀시트 직접 호출

| 문제 | 현황 | 해결 방안 |
|------|------|----------|
| `showModalBottomSheet` 직접 사용 | 15회 (9개 파일) | `showMingrrBottomSheet` 사용 |
| `health_record_add_screens.dart` | 6회 직접 사용 | 공통 함수로 교체 |

### 7.4 추가 공통화가 필요한 항목 (➕ 신규 제안)

#### 7.4.1 스켈레톤 로딩 컴포넌트

```dart
// 제안: lib/core/widgets/skeleton_widgets.dart
class MingrrSkeletonCard extends StatelessWidget { ... }
class MingrrSkeletonList extends StatelessWidget { ... }
class MingrrSkeletonAvatar extends StatelessWidget { ... }
```

**사용처**: 모든 리스트 화면의 초기 로딩

#### 7.4.2 확인 다이얼로그 공통화

```dart
// 제안: lib/core/widgets/dialogs/confirm_dialog.dart
Future<bool?> showMingrrConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDestructive = false,
});
```

**사용처**: 삭제, 로그아웃, 탈퇴 등 확인이 필요한 모든 액션

#### 7.4.3 Pull to Refresh 래퍼

```dart
// 제안: lib/core/widgets/refresh_wrapper.dart
class MingrrRefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? indicatorColor;
}
```

**사용처**: 모든 리스트 화면

#### 7.4.4 페이지네이션 리스트

```dart
// 제안: lib/core/widgets/paginated_list.dart
class MingrrPaginatedList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
}
```

**사용처**: 데이팅, 마켓, 커뮤니티 등 모든 리스트

#### 7.4.5 검색 바 공통화

```dart
// 제안: lib/core/widgets/search_bar.dart
class MingrrSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final Color? accentColor;
}
```

**사용처**: 데이팅, 마켓, 커뮤니티, 채팅 검색

### 7.5 컴포넌트 사용 통계

| 컴포넌트 | 사용 파일 수 | 사용 빈도 | 상태 |
|----------|------------|----------|------|
| `MingrrButton` | 31개+ | 높음 | ✅ 활발 |
| `MingrrCard` | 20개+ | 높음 | ✅ 활발 |
| `MingrrEmptyState` | 15개+ | 중간 | ✅ 활발 |
| `MingrrLoading` | 10개+ | 중간 | ✅ 활발 |
| `MingrrFilterChip` | 4개 | 낮음 | 🟡 확대 필요 |
| `MingrrFAB` | 7개 | 중간 | ✅ 적절 |
| `MingrrSettingsTile` | 4개 | 낮음 | ✅ 적절 (설정 화면 전용) |
| `DatingCard` 시리즈 | 1개 | 낮음 | ✅ 적절 (데이팅 전용) |

### 7.6 공통화 개선 로드맵

#### Phase A: 기존 컴포넌트 사용 확대 (2일)

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 1 | `ElevatedButton` → `MingrrButton` 교체 | 4시간 |
| 2 | `CircularProgressIndicator` → `MingrrLoadingIndicator` 교체 | 2시간 |
| 3 | `showModalBottomSheet` → `showMingrrBottomSheet` 교체 | 2시간 |

#### Phase B: 신규 컴포넌트 추가 (3일)

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 1 | `MingrrSkeletonCard/List/Avatar` 구현 | 4시간 |
| 2 | `showMingrrConfirmDialog` 구현 | 2시간 |
| 3 | `MingrrRefreshWrapper` 구현 | 2시간 |
| 4 | `MingrrPaginatedList` 구현 | 4시간 |
| 5 | `MingrrSearchBar` 구현 | 2시간 |

---

## 📊 종합 평가

### 공통화/컴포넌트화 점수

| 영역 | 점수 | 평가 |
|------|:----:|------|
| **네이밍 일관성** | 95/100 | ✅ 우수 - `Mingrr` 접두사 통일 |
| **컴포넌트 재사용성** | 90/100 | ✅ 우수 - 팩토리 패턴, 빌딩 블록 패턴 적용 |
| **디자인 통일성** | 85/100 | ✅ 양호 - 일부 직접 구현 존재 |
| **코드 중복** | 80/100 | 🟡 개선 필요 - 버튼/로딩 직접 사용 |
| **문서화** | 85/100 | ✅ 양호 - 주석 및 사용 예시 포함 |
| **확장성** | 90/100 | ✅ 우수 - enum, 팩토리로 확장 용이 |

### 총점: **87/100** (✅ 우수)

V1 리팩토링으로 공통화 기반이 잘 구축되었습니다. V2에서는 기존 컴포넌트 사용 확대와 신규 컴포넌트 추가로 완성도를 높일 수 있습니다.

---

## 🔗 관련 문서

- [REFACTORING_V1.md](./REFACTORING_V1.md) - 1차 리팩토링 (완료)
- [GUIDE_FILE_PLANNING.md](./GUIDE_FILE_PLANNING.md) - 가이드 파일 계획
- [FIRESTORE_STRUCTURE.md](../FIRESTORE_STRUCTURE.md) - DB 구조

---

### 추가 완료 작업 (2026-01-20)

| 작업 | 수정 파일 | 상태 |
|------|----------|:----:|
| **스켈레톤 UI → MingrrLoadingState 전환** | 11개 화면 | ✅ 완료 |
| **MingrrEmptyState pull-to-refresh 지원** | `common_widgets.dart` + 4개 화면 | ✅ 완료 |
| **커뮤니티 카드 UI 재설계** | `community_screen.dart` | ✅ 완료 |
| **CommunityPostModel title 필드 추가** | `community_post_model.dart` | ✅ 완료 |

---

*최종 업데이트: 2026-01-20*
