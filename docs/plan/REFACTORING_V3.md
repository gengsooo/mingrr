# MINGRR 3차 리팩토링 가이드 (V3)

> 작성일: 2026-01-20  
> 상태: 🚧 **계획 수립 완료**  
> 목적: 대규모 디자인 리팩토링, 상태 관리 개선, 성능 최적화, 코드 품질 향상

---

## 📊 V3 리팩토링 개요

V1에서 공통 컴포넌트화, V2에서 백엔드 연동 및 로딩 UI 개선을 완료했습니다.  
V3에서는 **전체 앱 디자인 통일성**, **상태 관리 개선**, **성능 최적화**를 집중적으로 진행합니다.

| 영역 | 목표 |
|------|------|
| **🎨 디자인 통일성** | 리스트 카드, 상세 화면, 폼 화면 크기/간격 통일 |
| **🔄 상태 관리** | 등록/수정 후 리스트 자동 새로고침 |
| **⚡ 성능 최적화** | Deprecated API 제거, 메모리 최적화 |
| **🧹 코드 품질** | TODO 정리, 미사용 코드 제거 |
| **🔒 보안 강화** | 입력 검증, 에러 처리 개선 |

---

## 🔴 Phase 1: 상태 관리 개선 (우선순위: 높음)

### 1.1 등록/수정 후 리스트 자동 새로고침 문제

**현황:**
- 커뮤니티 글 등록 후 리스트 화면으로 돌아가도 새 글이 보이지 않음
- 다른 메뉴(마켓, 데이팅, 소모임 등)에서도 동일 현상 발생 가능

**원인 분석:**
- `pop(true)` 후 리스트 Provider를 `invalidate`하지 않음
- 페이지네이션 Provider가 캐시된 데이터를 유지

**영향 범위:**
| 화면 | 등록/수정 화면 | 리스트 화면 | 상태 |
|------|--------------|------------|:----:|
| 커뮤니티 | `community_write_screen.dart` | `community_screen.dart` | 🔴 수정 필요 |
| 마켓플레이스 | `product_write_screen.dart` | `marketplace_screen.dart` | 🔴 수정 필요 |
| 데이팅 교배 | `breeding_write_screen.dart` | `dating_screen.dart` | 🔴 수정 필요 |
| 소모임 | `group_write_screen.dart` | `group_list_screen.dart` | 🔴 수정 필요 |
| 반려동물 | `pet_edit_screen.dart` | `profile_screen.dart` | 🟡 확인 필요 |

**해결 방안:**

```dart
// 방법 1: pop 결과로 새로고침 트리거
// write_screen.dart
context.pop(true);

// list_screen.dart
final result = await context.push('/write');
if (result == true) {
  ref.invalidate(paginatedProvider);
}

// 방법 2: 글로벌 이벤트 버스 패턴
// 등록 성공 시 이벤트 발행 → 리스트 화면에서 구독하여 새로고침
```

**제안: `RefreshNotifier` 공통 패턴**

```dart
// lib/core/providers/refresh_notifier.dart
final communityRefreshProvider = StateProvider<int>((ref) => 0);
final marketRefreshProvider = StateProvider<int>((ref) => 0);
final datingRefreshProvider = StateProvider<int>((ref) => 0);
final groupRefreshProvider = StateProvider<int>((ref) => 0);

// 사용: 등록 성공 시
ref.read(communityRefreshProvider.notifier).state++;

// 리스트 화면에서 watch
ref.watch(communityRefreshProvider);
```

### 1.2 작업 항목

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 1-1 | RefreshNotifier 패턴 구현 | `refresh_notifier.dart` (신규) | 30분 | ⬜ 대기 |
| 1-2 | 커뮤니티 등록/수정 후 새로고침 | `community_write_screen.dart`, `community_screen.dart` | 30분 | ⬜ 대기 |
| 1-3 | 마켓플레이스 등록/수정 후 새로고침 | `product_write_screen.dart`, `marketplace_screen.dart` | 30분 | ⬜ 대기 |
| 1-4 | 데이팅 교배 등록 후 새로고침 | `breeding_write_screen.dart`, `dating_screen.dart` | 30분 | ⬜ 대기 |
| 1-5 | 소모임 등록/수정 후 새로고침 | `group_write_screen.dart`, `group_list_screen.dart` | 30분 | ⬜ 대기 |
| 1-6 | 반려동물 등록/수정 후 새로고침 | `pet_edit_screen.dart`, `profile_screen.dart` | 30분 | ⬜ 대기 |
| 1-7 | 상세 화면에서 삭제 후 리스트 새로고침 | 5개 상세 화면 | 1시간 | ⬜ 대기 |

---

## 🎨 Phase 2: 대규모 디자인 리팩토링 (우선순위: 높음)

> **핵심 목표**: 전체 앱의 UI 요소(padding, fontSize, 입력 폼, 카드 등) 크기를 **컴팩트하게 통일**하고,  
> 모든 디자인 값을 **상수화**하여 일관된 사용자 경험 제공

### 2.1 현재 문제점 상세 분석

#### 2.1.1 핵심 문제: 요소 크기가 너무 큼

| 문제 | 현황 | 영향 |
|------|------|------|
| **padding 과다** | 대부분 `24px` 사용 | 콘텐츠 영역 축소, 답답한 느낌 |
| **fontSize 과다** | 제목 18-20px, 본문 14-16px | 한 화면에 정보량 감소 |
| **카드 높이 과다** | 상품 카드 100px 이미지 | 스크롤 많이 필요 |
| **입력 필드 과다** | 높이 52px, 패딩 16px | 폼 화면이 길어짐 |
| **간격 과다** | 섹션 간 24-32px | 화면 낭비 |

#### 2.1.2 핵심 문제: 요소 크기가 제각각

| 영역 | 발견된 불일치 |
|------|-------------|
| **카드 패딩** | 10px, 12px, 14px, 16px, 20px 혼용 |
| **카드 이미지** | 60px, 70px, 80px, 100px 혼용 |
| **폰트 크기** | 같은 역할인데 10px, 11px, 12px, 13px 혼용 |
| **BorderRadius** | 4px, 6px, 8px, 10px, 12px, 16px, 20px 혼용 |
| **섹션 간격** | 12px, 16px, 20px, 24px, 32px 혼용 |

#### 2.1.3 기준 모델: 커뮤니티 카드 ✅

`_CommunityPostCard`가 컴팩트하고 정보 밀도가 높아 **기준 모델**로 삼음:

```dart
// 커뮤니티 카드 디자인 값 (기준)
- 카드 패딩: horizontal 12px, vertical 10px
- 카드 마진: bottom 8px
- 썸네일 크기: 70px
- 제목 폰트: 14px, w600
- 본문 폰트: 12px
- 캡션 폰트: 10px
- BorderRadius: 10px (카드), 6px (썸네일)
```

---

### 2.2 디자인 토큰 시스템 설계

#### 2.2.1 AppSizes 확장 (컴팩트 버전)

```dart
// lib/core/constants/app_sizes.dart 추가

class AppSizes {
  // ===== 컴팩트 패딩 (기존보다 작게) =====
  static const double paddingCompactXS = 4.0;
  static const double paddingCompactS = 8.0;
  static const double paddingCompactM = 12.0;  // 기존 16 → 12
  static const double paddingCompactL = 16.0;  // 기존 24 → 16
  
  // ===== 카드 전용 =====
  static const double cardPaddingH = 12.0;     // 카드 좌우 패딩
  static const double cardPaddingV = 10.0;     // 카드 상하 패딩
  static const double cardMarginBottom = 8.0;  // 카드 간 간격
  static const double cardRadius = 10.0;       // 카드 모서리
  
  // ===== 카드 이미지 크기 =====
  static const double cardImageXS = 40.0;      // 아바타 (채팅)
  static const double cardImageS = 56.0;       // 소형 썸네일
  static const double cardImageM = 70.0;       // 기본 썸네일 (커뮤니티 기준)
  static const double cardImageL = 80.0;       // 상품 썸네일 (기존 100 → 80)
  
  // ===== 폼 전용 =====
  static const double formInputHeight = 44.0;  // 기존 52 → 44
  static const double formInputPadding = 12.0; // 기존 16 → 12
  static const double formSectionGap = 16.0;   // 섹션 간격 (기존 24 → 16)
  static const double formFieldGap = 8.0;      // 필드 간격
  
  // ===== 상세 화면 전용 =====
  static const double detailPadding = 16.0;    // 기존 24 → 16
  static const double detailSectionGap = 16.0; // 섹션 간격
  static const double detailItemGap = 8.0;     // 아이템 간격
  
  // ===== 바텀시트/다이얼로그 =====
  static const double sheetPadding = 16.0;     // 기존 24 → 16
  static const double sheetTitleGap = 12.0;    // 제목-내용 간격
  static const double sheetButtonGap = 8.0;    // 버튼 간격
  
  // ===== 컴팩트 BorderRadius =====
  static const double radiusCompactXS = 4.0;
  static const double radiusCompactS = 6.0;
  static const double radiusCompactM = 8.0;
  static const double radiusCompactL = 10.0;
  static const double radiusCompactXL = 12.0;
}
```

#### 2.2.2 AppTextStyles 확장 (컴팩트 버전)

```dart
// lib/core/theme/app_text_styles.dart 추가

class AppTextStyles {
  // ===== 카드 텍스트 (컴팩트) =====
  /// 카드 제목: 14px, w600 (기존 15-16 → 14)
  static TextStyle cardTitle(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 카드 본문: 12px (기존 13-14 → 12)
  static TextStyle cardBody(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
  
  /// 카드 캡션: 10px (기존 11-12 → 10)
  static TextStyle cardCaption(BuildContext context) => TextStyle(
    fontSize: 10,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
  
  // ===== 상세 화면 텍스트 (컴팩트) =====
  /// 상세 제목: 16px, w600 (기존 18-20 → 16)
  static TextStyle detailTitle(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 상세 섹션 제목: 14px, w600 (기존 16 → 14)
  static TextStyle detailSectionTitle(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 상세 본문: 13px (기존 14-16 → 13)
  static TextStyle detailBody(BuildContext context) => TextStyle(
    fontSize: 13,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  // ===== 폼 텍스트 (컴팩트) =====
  /// 폼 라벨: 13px, w500 (기존 14 → 13)
  static TextStyle formLabel(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 폼 힌트: 13px (기존 14 → 13)
  static TextStyle formHint(BuildContext context) => TextStyle(
    fontSize: 13,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
  
  // ===== 바텀시트/다이얼로그 =====
  /// 시트 제목: 16px, w600 (기존 18 → 16)
  static TextStyle sheetTitle(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 시트 본문: 13px (기존 14 → 13)
  static TextStyle sheetBody(BuildContext context) => TextStyle(
    fontSize: 13,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
```

---

### 2.3 리팩토링 대상 전체 목록

#### 2.3.1 리스트 카드 (7개)

| # | 화면 | 카드 위젯 | 파일 | 현재 | 목표 | 상태 |
|:-:|------|----------|------|:----:|:----:|:----:|
| 1 | 커뮤니티 | `_CommunityPostCard` | `community_screen.dart` | 컴팩트 | 기준 | ✅ 완료 |
| 2 | 마켓 상품 | `ProductCard` | `product_card.dart` | 이미지 100px | 80px | ⬜ 대기 |
| 3 | 마켓 알바 | `_JobCard` | `marketplace_screen.dart` | 큼 | 컴팩트화 | ⬜ 대기 |
| 4 | 데이팅 추천 | `DatingRecommendCard` | `dating_card.dart` | 280px | 220px | ⬜ 대기 |
| 5 | 데이팅 근처 | `DatingNearbyCard` | `dating_card.dart` | 큼 | 컴팩트화 | ⬜ 대기 |
| 6 | 데이팅 교배 | `DatingBreedingCard` | `dating_card.dart` | 큼 | 컴팩트화 | ⬜ 대기 |
| 7 | 소모임 | `_GroupCard` | `group_list_screen.dart` | 큼 | 컴팩트화 | ⬜ 대기 |

#### 2.3.2 상세 화면 (6개)

| # | 화면 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 1 | 반려동물 상세 | `pet_detail_screen.dart` | padding 24→16, fontSize 축소 | ⬜ 대기 |
| 2 | 상품 상세 | `product_detail_screen.dart` | padding 24→16, fontSize 축소 | ⬜ 대기 |
| 3 | 알바 상세 | `job_detail_screen.dart` | padding 24→16, fontSize 축소 | ⬜ 대기 |
| 4 | 커뮤니티 상세 | `community_detail_screen.dart` | padding 24→16, fontSize 축소 | ⬜ 대기 |
| 5 | 소모임 상세 | `group_detail_screen.dart` | padding 24→16, fontSize 축소 | ⬜ 대기 |
| 6 | 건강기록 상세 | `health_record_detail_screens.dart` | padding 24→16, fontSize 축소 | ⬜ 대기 |

#### 2.3.3 등록/수정 화면 (8개)

| # | 화면 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 1 | 상품 등록 | `product_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 2 | 교배 등록 | `breeding_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3 | 커뮤니티 글쓰기 | `community_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 4 | 소모임 만들기 | `group_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 5 | 반려동물 수정 | `pet_edit_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 6 | 프로필 수정 | `profile_edit_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 7 | 건강기록 등록 | `health_record_add_screens.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 8 | 산책기록 상세 | `walk_record_detail_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |

#### 2.3.4 바텀시트 (12개)

| # | 위젯 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 1 | `MingrrBottomSheet` | `mingrr_bottom_sheet.dart` | padding 24→16, fontSize 18→16 | ⬜ 대기 |
| 2 | `MingrrBottomButtonBar` | `mingrr_bottom_sheet.dart` | 버튼 높이, 패딩 축소 | ⬜ 대기 |
| 3 | `MingrrSubmitButtonBar` | `mingrr_bottom_sheet.dart` | 버튼 높이, 패딩 축소 | ⬜ 대기 |
| 4 | `ConfirmSheet` | `confirm_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 5 | `ReportSheet` | `report_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 6 | `RequestSheet` | `request_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 7 | `ImagePickerSheet` | `image_picker_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 8 | `RatingSheet` | `rating_widgets.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 9 | `LocationSelector` | `location_selector.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 10 | `FilterComponents` | `filter_components.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 11 | `ChatOptionsModal` | `chat_options_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 12 | `PetProfileModal` | `pet_profile_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |

#### 2.3.5 다이얼로그 (9개)

| # | 위젯 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 1 | `AppDialog` | `app_dialog.dart` | padding 24→16, 아이콘 56→48 | ⬜ 대기 |
| 2 | `InfoDialog` | `info_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 3 | `InfoActionDialog` | `info_action_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 4 | `InputDialog` | `input_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 5 | `ErrorDialog` | `error_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 6 | `SelectionDialog` | `selection_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 7 | `ActionPromptDialog` | `action_prompt_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 8 | `GuardianProfileModal` | `guardian_profile_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 9 | `GroupProfileModal` | `group_profile_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |

#### 2.3.6 공통 위젯 (15개)

| # | 위젯 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 1 | `MingrrCard` | `common_widgets.dart` | 기본 padding 축소 | ⬜ 대기 |
| 2 | `MingrrButton` | `common_widgets.dart` | 높이 56→48, fontSize 16→14 | ⬜ 대기 |
| 3 | `MingrrSectionLabel` | `common_widgets.dart` | fontSize 14→13 | ⬜ 대기 |
| 4 | `MingrrTextField` | `form_components.dart` | 높이 52→44, padding 축소 | ⬜ 대기 |
| 5 | `MingrrDropdown` | `form_components.dart` | 높이, padding 축소 | ⬜ 대기 |
| 6 | `MingrrImagePicker` | `form_components.dart` | 이미지 크기, 간격 축소 | ⬜ 대기 |
| 7 | `InfoBadge` | `info_badge.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 8 | `TraitBadge` | `trait_badge.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 9 | `VerificationBadge` | `verification_badge.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 10 | `TopNavigation` | `top_navigation.dart` | 탭 높이, fontSize 축소 | ⬜ 대기 |
| 11 | `MingrrCategoryChips` | `filter_components.dart` | 칩 크기, fontSize 축소 | ⬜ 대기 |
| 12 | `LocationBubbleWidget` | `location_bubble_widget.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 13 | `HomeReminderBanner` | `home_reminder_banner.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 14 | `ProfileCards` | `profile_cards.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 15 | `CompatibilityWidgets` | `compatibility_widgets.dart` | padding, fontSize 축소 | ⬜ 대기 |

#### 2.3.7 기타 화면 (8개)

| # | 화면 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 1 | 홈 | `home_screen.dart` | 카드 padding, fontSize 축소 | ⬜ 대기 |
| 2 | 프로필 | `profile_screen.dart` | 섹션 padding, fontSize 축소 | ⬜ 대기 |
| 3 | 채팅 목록 | `chat_list_screen.dart` | 아이템 padding 축소 | ⬜ 대기 |
| 4 | 채팅 상세 | `chat_detail_screen.dart` | 메시지 버블 padding 축소 | ⬜ 대기 |
| 5 | 알림 | `notification_screen.dart` | 아이템 padding 축소 | ⬜ 대기 |
| 6 | 산책 | `walk_screen.dart` | 카드 padding, fontSize 축소 | ⬜ 대기 |
| 7 | 건강 | `health_screen.dart` | 카드 padding, fontSize 축소 | ⬜ 대기 |
| 8 | 설정 화면들 | `settings/*.dart` | 리스트 아이템 padding 축소 | ⬜ 대기 |

---

### 2.4 디자인 값 변경 요약

#### 2.4.1 Padding 변경

| 용도 | Before | After | 감소율 |
|------|:------:|:-----:|:------:|
| 카드 패딩 | 16-20px | 10-12px | **40%↓** |
| 상세 화면 패딩 | 24px | 16px | **33%↓** |
| 폼 화면 패딩 | 24px | 16px | **33%↓** |
| 바텀시트 패딩 | 24px | 16px | **33%↓** |
| 다이얼로그 패딩 | 24px | 16px | **33%↓** |
| 섹션 간격 | 24-32px | 16px | **40%↓** |

#### 2.4.2 FontSize 변경

| 용도 | Before | After | 감소율 |
|------|:------:|:-----:|:------:|
| 카드 제목 | 15-16px | 14px | **10%↓** |
| 카드 본문 | 13-14px | 12px | **10%↓** |
| 카드 캡션 | 11-12px | 10px | **10%↓** |
| 상세 제목 | 18-20px | 16px | **15%↓** |
| 상세 본문 | 14-16px | 13px | **15%↓** |
| 시트 제목 | 18px | 16px | **10%↓** |
| 버튼 텍스트 | 16px | 14px | **12%↓** |

#### 2.4.3 컴포넌트 크기 변경

| 컴포넌트 | Before | After | 감소율 |
|----------|:------:|:-----:|:------:|
| 버튼 높이 | 56px | 48px | **14%↓** |
| 입력 필드 높이 | 52px | 44px | **15%↓** |
| 카드 이미지 (상품) | 100px | 80px | **20%↓** |
| 추천 카드 높이 | 280px | 220px | **21%↓** |
| 다이얼로그 아이콘 | 56px | 48px | **14%↓** |

---

### 2.5 작업 순서 및 일정

#### Step 1: 디자인 토큰 정의 (1일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-1 | AppSizes 컴팩트 상수 추가 | `app_sizes.dart` | 1시간 | ⬜ 대기 |
| 2-2 | AppTextStyles 컴팩트 스타일 추가 | `app_text_styles.dart` | 1시간 | ⬜ 대기 |
| 2-3 | app_theme.dart 기본값 조정 | `app_theme.dart` | 1시간 | ⬜ 대기 |

#### Step 2: 공통 위젯 리팩토링 (2일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-4 | MingrrCard, MingrrButton 축소 | `common_widgets.dart` | 2시간 | ⬜ 대기 |
| 2-5 | MingrrTextField, 폼 컴포넌트 축소 | `form_components.dart` | 2시간 | ⬜ 대기 |
| 2-6 | 배지 위젯들 축소 | `info_badge.dart`, `trait_badge.dart` 등 | 2시간 | ⬜ 대기 |
| 2-7 | 탭/필터 위젯 축소 | `top_navigation.dart`, `filter_components.dart` | 2시간 | ⬜ 대기 |

#### Step 3: 바텀시트/다이얼로그 리팩토링 (2일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-8 | MingrrBottomSheet 계열 축소 | `mingrr_bottom_sheet.dart` | 2시간 | ⬜ 대기 |
| 2-9 | 기능별 시트 축소 | `confirm_sheet.dart`, `report_sheet.dart` 등 | 3시간 | ⬜ 대기 |
| 2-10 | 다이얼로그 9개 축소 | `dialogs/*.dart` | 3시간 | ⬜ 대기 |
| 2-11 | 프로필 모달 축소 | `*_profile_modal.dart` | 2시간 | ⬜ 대기 |

#### Step 4: 리스트 카드 리팩토링 (2일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-12 | ProductCard 컴팩트화 | `product_card.dart` | 1시간 | ⬜ 대기 |
| 2-13 | DatingCard 3종 컴팩트화 | `dating_card.dart` | 2시간 | ⬜ 대기 |
| 2-14 | GroupCard 컴팩트화 | `group_list_screen.dart` | 1시간 | ⬜ 대기 |
| 2-15 | JobCard 컴팩트화 | `marketplace_screen.dart` | 1시간 | ⬜ 대기 |

#### Step 5: 상세 화면 리팩토링 (2일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-16 | 반려동물/상품/알바 상세 | 3개 파일 | 3시간 | ⬜ 대기 |
| 2-17 | 커뮤니티/소모임 상세 | 2개 파일 | 2시간 | ⬜ 대기 |
| 2-18 | 건강기록 상세 | 1개 파일 | 1시간 | ⬜ 대기 |

#### Step 6: 등록/수정 화면 리팩토링 (2일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-19 | 상품/교배/커뮤니티 등록 | 3개 파일 | 3시간 | ⬜ 대기 |
| 2-20 | 소모임/반려동물/프로필 수정 | 3개 파일 | 3시간 | ⬜ 대기 |
| 2-21 | 건강기록/산책기록 | 2개 파일 | 2시간 | ⬜ 대기 |

#### Step 7: 기타 화면 리팩토링 (2일)

| # | 작업 | 파일 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-22 | 홈/프로필 화면 | 2개 파일 | 2시간 | ⬜ 대기 |
| 2-23 | 채팅 목록/상세 | 2개 파일 | 2시간 | ⬜ 대기 |
| 2-24 | 알림/산책/건강 | 3개 파일 | 2시간 | ⬜ 대기 |
| 2-25 | 설정 화면들 | 5개 파일 | 2시간 | ⬜ 대기 |

#### Step 8: 테스트 및 미세 조정 (1일)

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-26 | 전체 화면 시각적 검토 | 전체 | 3시간 | ⬜ 대기 |
| 2-27 | 불일치 요소 미세 조정 | 발견된 항목 | 2시간 | ⬜ 대기 |
| 2-28 | 다크 모드 검증 | 전체 | 1시간 | ⬜ 대기 |

---

### 2.6 Phase 2 진행 현황

| Step | 작업 수 | 완료 | 진행률 |
|:----:|:------:|:----:|:------:|
| Step 1: 디자인 토큰 | 3 | 0 | **0%** |
| Step 2: 공통 위젯 | 4 | 0 | **0%** |
| Step 3: 시트/다이얼로그 | 4 | 0 | **0%** |
| Step 4: 리스트 카드 | 4 | 0 | **0%** |
| Step 5: 상세 화면 | 3 | 0 | **0%** |
| Step 6: 등록/수정 화면 | 3 | 0 | **0%** |
| Step 7: 기타 화면 | 4 | 0 | **0%** |
| Step 8: 테스트 | 3 | 0 | **0%** |
| **전체** | **28** | **0** | **0%** |

**예상 소요 기간**: 약 2주 (14일)

---

## ⚡ Phase 3: 성능 최적화 (우선순위: 중간)

### 3.1 Deprecated API 제거

**발견된 Deprecated 사용:**

| API | 사용 횟수 | 대체 API | 영향 파일 |
|-----|:--------:|----------|----------|
| `withOpacity()` | 266개 | `withValues(alpha: x)` | 60개 파일 |
| `dogsCollection` | 1개 | `petsCollection` | `firebase_service.dart` |
| `likesCollection` | 1개 | 제거 | `firebase_service.dart` |
| `NotificationIconButton` | 0개 | `AppBarActionButton.notification()` | 제거 가능 |
| `CategoryFilterChips` | 0개 | `MingrrCategoryChips` | 제거 가능 |
| `DistanceBottomSheet` | 0개 | `LocationDistanceBar` | 제거 가능 |

### 3.2 TODO 항목 정리 (59개)

**우선순위별 분류:**

| 우선순위 | 파일 | TODO 내용 | 상태 |
|:-------:|------|----------|:----:|
| 🔴 높음 | `chat_detail_screen.dart` | 6개 TODO | ⬜ 대기 |
| 🔴 높음 | `customer_service_screen.dart` | 4개 TODO (고객센터 기능) | ⬜ 대기 |
| 🟡 중간 | `image_picker_sheet.dart` | 4개 TODO | ⬜ 대기 |
| 🟡 중간 | `pet_edit_screen.dart` | 4개 TODO | ⬜ 대기 |
| 🟡 중간 | `health_model.dart` | 4개 TODO | ⬜ 대기 |
| 🟢 낮음 | 기타 24개 파일 | 37개 TODO | ⬜ 대기 |

### 3.3 미사용 코드 정리

| 영역 | 현황 | 조치 |
|------|------|------|
| `skeleton_widgets.dart` | 스켈레톤 → LoadingState 전환 완료 | 파일 삭제 검토 |
| `filter_widgets.dart` | Deprecated 컴포넌트 포함 | 정리 필요 |
| Mock 데이터 | `seed_data.dart` 등 | 개발 모드 분리 |

### 3.4 작업 항목

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 3-1 | withOpacity → withValues 교체 | 60개 파일 | 3시간 | ⬜ 대기 |
| 3-2 | Deprecated 컴포넌트 제거 | `firebase_service.dart`, `filter_widgets.dart` | 1시간 | ⬜ 대기 |
| 3-3 | TODO 항목 해결 (높음) | 10개 TODO | 2시간 | ⬜ 대기 |
| 3-4 | skeleton_widgets.dart 정리 | `skeleton_widgets.dart` | 30분 | ⬜ 대기 |
| 3-5 | Mock 데이터 분리 | `seed_data.dart` | 1시간 | ⬜ 대기 |

---

## 🧹 Phase 4: 코드 품질 개선 (우선순위: 중간)

### 4.1 하드코딩된 값 상수화

**발견된 하드코딩:**

| 유형 | 발견 횟수 | 조치 |
|------|:--------:|------|
| `fontSize:` | 768개 | `AppTextStyles` 사용 |
| `padding:` / `margin:` | 670개 | `AppSizes` 사용 |
| `SizedBox(height:)` / `SizedBox(width:)` | 939개 | `AppSizes.gap*` 사용 |
| `BorderRadius.circular()` | 374개 | `AppSizes.radius*` 상수화 |

### 4.2 BorderRadius 상수화

```dart
// lib/core/constants/app_sizes.dart 추가
class AppSizes {
  // BorderRadius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 999.0;  // 완전 둥근 모서리
}
```

### 4.3 작업 항목

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 4-1 | BorderRadius 상수 추가 | `app_sizes.dart` | 30분 | ⬜ 대기 |
| 4-2 | 주요 화면 fontSize 상수화 | 10개 주요 화면 | 2시간 | ⬜ 대기 |
| 4-3 | 주요 화면 padding/margin 상수화 | 10개 주요 화면 | 2시간 | ⬜ 대기 |
| 4-4 | 주요 화면 BorderRadius 상수화 | 10개 주요 화면 | 1시간 | ⬜ 대기 |

---

## 🔒 Phase 5: 보안 및 안정성 (우선순위: 중간)

### 5.1 입력 검증 강화

| 화면 | 현재 | 개선 |
|------|------|------|
| 폼 화면 | 제출 시 검증 | 실시간 검증 + 에러 메시지 |
| 채팅 | 기본 검증 | XSS 방지, 길이 제한 |
| 검색 | 기본 검증 | SQL Injection 방지 (Firestore는 안전하지만 습관화) |

### 5.2 에러 처리 개선

| 영역 | 현재 | 개선 |
|------|------|------|
| 네트워크 에러 | 일반 메시지 | 구체적 안내 + 재시도 버튼 |
| 권한 에러 | 일반 메시지 | 설정 화면 이동 유도 |
| Firestore 에러 | 콘솔 로그 | 사용자 친화적 메시지 |

### 5.3 작업 항목

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 5-1 | 폼 실시간 검증 추가 | 6개 폼 화면 | 2시간 | ⬜ 대기 |
| 5-2 | 에러 메시지 개선 | 전체 | 2시간 | ⬜ 대기 |
| 5-3 | 네트워크 에러 재시도 UI | `MingrrErrorState` | 1시간 | ⬜ 대기 |

---

## 🎯 Phase 6: UX 개선 (우선순위: 낮음)

### 6.1 애니메이션 추가

| 영역 | 현재 | 개선 |
|------|------|------|
| 화면 전환 | 기본 | 커스텀 트랜지션 |
| 리스트 아이템 | 없음 | 페이드인/슬라이드 애니메이션 |
| 좋아요 버튼 | 없음 | 하트 애니메이션 |
| 탭 전환 | 기본 | 스무스 전환 |

### 6.2 접근성 개선

| 영역 | 현재 | 개선 |
|------|------|------|
| Semantics | 일부 적용 | 전체 적용 |
| 색상 대비 | 양호 | WCAG AA 기준 검증 |
| 터치 영역 | 대부분 48px | 전체 확인 |

### 6.3 작업 항목

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 6-1 | 리스트 아이템 애니메이션 | 주요 리스트 화면 | 2시간 | ⬜ 대기 |
| 6-2 | 좋아요 애니메이션 | `MingrrLikeButton` | 1시간 | ⬜ 대기 |
| 6-3 | Semantics 전체 적용 | 주요 화면 | 2시간 | ⬜ 대기 |

---

## 📋 리팩토링 로드맵 (작업별 체크리스트)

> 각 작업을 순서대로 진행하며 완료 시 ⬜ → ✅ 로 변경

---

### 🔄 Phase 1: 상태 관리 개선 ✅ 완료 (2025-01-20)

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 1-1 | RefreshNotifier 패턴 구현 | `refresh_notifier.dart` (신규) | 30분 | ✅ |
| 1-2 | 커뮤니티 등록/수정/삭제 후 새로고침 | `community_write_screen.dart`, `community_screen.dart`, `community_detail_screen.dart` | 30분 | ✅ |
| 1-3 | 마켓플레이스 등록/수정/삭제 후 새로고침 | `product_write_screen.dart`, `marketplace_screen.dart`, `product_detail_screen.dart` | 30분 | ✅ |
| 1-4 | 데이팅 교배 등록 후 새로고침 | `breeding_write_screen.dart`, `dating_screen.dart` | 30분 | ✅ |
| 1-5 | 소모임 등록/수정/삭제 후 새로고침 | `group_write_screen.dart`, `group_list_screen.dart`, `group_detail_screen.dart` | 30분 | ✅ |
| 1-6 | 반려동물 등록/수정/삭제 후 새로고침 | `pet_edit_screen.dart` | 30분 | ✅ |
| 1-7 | 상세 화면에서 삭제 후 리스트 새로고침 | `community_detail_screen.dart`, `product_detail_screen.dart`, `group_detail_screen.dart` | 1시간 | ✅ |

**구현 내용:**
- `lib/core/providers/refresh_notifier.dart` 신규 생성
- 5개 RefreshProvider 정의: `communityRefreshProvider`, `marketRefreshProvider`, `datingRefreshProvider`, `groupRefreshProvider`, `petRefreshProvider`
- 등록/수정/삭제 성공 시 `ref.read(xxxRefreshProvider.notifier).state++` 호출
- 리스트 화면에서 `ref.listen(xxxRefreshProvider, ...)` 로 변경 감지 후 자동 새로고침

**추가 버그 수정 (2025-01-20):**
- `walk_record_detail_screen.dart`: 산책 기록 삭제 시 실제 DB 삭제 미연동 버그 수정
  - `StatefulWidget` → `ConsumerStatefulWidget` 변경
  - `HealthService.deleteWalkRecord()` 호출로 Firestore 삭제 연동
  - `walkRecordsProvider`가 `StreamProvider`이므로 삭제 후 자동 반영

---

### 🎨 Phase 2: 디자인 리팩토링

#### Step 1: 디자인 토큰 정의

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-1 | AppSizes 컴팩트 상수 추가 | `app_sizes.dart` | 1시간 | ⬜ |
| 2-2 | AppTextStyles 컴팩트 스타일 추가 | `app_text_styles.dart` | 1시간 | ⬜ |
| 2-3 | app_theme.dart 기본값 조정 | `app_theme.dart` | 1시간 | ⬜ |

#### Step 2: 공통 위젯 리팩토링

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-4 | MingrrCard, MingrrButton 축소 | `common_widgets.dart` | 2시간 | ⬜ |
| 2-5 | MingrrTextField, 폼 컴포넌트 축소 | `form_components.dart` | 2시간 | ⬜ |
| 2-6 | 배지 위젯들 축소 | `info_badge.dart`, `trait_badge.dart` 등 | 2시간 | ⬜ |
| 2-7 | 탭/필터 위젯 축소 | `top_navigation.dart`, `filter_components.dart` | 2시간 | ⬜ |

#### Step 3: 바텀시트/다이얼로그 리팩토링

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-8 | MingrrBottomSheet 계열 축소 | `mingrr_bottom_sheet.dart` | 2시간 | ⬜ |
| 2-9 | 기능별 시트 축소 | `confirm_sheet.dart`, `report_sheet.dart` 등 | 3시간 | ⬜ |
| 2-10 | 다이얼로그 9개 축소 | `dialogs/*.dart` | 3시간 | ⬜ |
| 2-11 | 프로필 모달 축소 | `*_profile_modal.dart` | 2시간 | ⬜ |

#### Step 4: 리스트 카드 리팩토링

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-12 | ProductCard 컴팩트화 | `product_card.dart` | 1시간 | ⬜ |
| 2-13 | DatingCard 3종 컴팩트화 | `dating_card.dart` | 2시간 | ⬜ |
| 2-14 | GroupCard 컴팩트화 | `group_list_screen.dart` | 1시간 | ⬜ |
| 2-15 | JobCard 컴팩트화 | `marketplace_screen.dart` | 1시간 | ⬜ |

#### Step 5: 상세 화면 리팩토링

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-16 | 반려동물/상품/알바 상세 | `pet_detail_screen.dart`, `product_detail_screen.dart`, `job_detail_screen.dart` | 3시간 | ⬜ |
| 2-17 | 커뮤니티/소모임 상세 | `community_detail_screen.dart`, `group_detail_screen.dart` | 2시간 | ⬜ |
| 2-18 | 건강기록 상세 | `health_record_detail_screens.dart` | 1시간 | ⬜ |

#### Step 6: 등록/수정 화면 리팩토링

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-19 | 상품/교배/커뮤니티 등록 | `product_write_screen.dart`, `breeding_write_screen.dart`, `community_write_screen.dart` | 3시간 | ⬜ |
| 2-20 | 소모임/반려동물/프로필 수정 | `group_write_screen.dart`, `pet_edit_screen.dart`, `profile_edit_screen.dart` | 3시간 | ⬜ |
| 2-21 | 건강기록/산책기록 | `health_record_add_screens.dart`, `walk_record_detail_screen.dart` | 2시간 | ⬜ |

#### Step 7: 기타 화면 리팩토링

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-22 | 홈/프로필 화면 | `home_screen.dart`, `profile_screen.dart` | 2시간 | ⬜ |
| 2-23 | 채팅 목록/상세 | `chat_list_screen.dart`, `chat_detail_screen.dart` | 2시간 | ⬜ |
| 2-24 | 알림/산책/건강 | `notification_screen.dart`, `walk_screen.dart`, `health_screen.dart` | 2시간 | ⬜ |
| 2-25 | 설정 화면들 | `settings/*.dart` | 2시간 | ⬜ |

#### Step 8: 테스트 및 미세 조정

| # | 작업 | 대상 | 예상 시간 | 상태 |
|:-:|------|------|:--------:|:----:|
| 2-26 | 전체 화면 시각적 검토 | 전체 | 3시간 | ⬜ |
| 2-27 | 불일치 요소 미세 조정 | 발견된 항목 | 2시간 | ⬜ |
| 2-28 | 다크 모드 검증 | 전체 | 1시간 | ⬜ |

---

### ⚡ Phase 3: 성능 최적화

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 3-1 | withOpacity → withValues 교체 | 60개 파일 | 3시간 | ⬜ |
| 3-2 | Deprecated 컴포넌트 제거 | `firebase_service.dart`, `filter_widgets.dart` | 1시간 | ⬜ |
| 3-3 | TODO 항목 해결 (높음) | 10개 TODO | 2시간 | ⬜ |
| 3-4 | skeleton_widgets.dart 정리 | `skeleton_widgets.dart` | 30분 | ⬜ |
| 3-5 | Mock 데이터 분리 | `seed_data.dart` | 1시간 | ⬜ |

---

### 🧹 Phase 4: 코드 품질 개선

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 4-1 | BorderRadius 상수 추가 | `app_sizes.dart` | 30분 | ⬜ |
| 4-2 | 주요 화면 fontSize 상수화 | 10개 주요 화면 | 2시간 | ⬜ |
| 4-3 | 주요 화면 padding/margin 상수화 | 10개 주요 화면 | 2시간 | ⬜ |
| 4-4 | 주요 화면 BorderRadius 상수화 | 10개 주요 화면 | 1시간 | ⬜ |

---

### 🔒 Phase 5: 보안 및 안정성

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 5-1 | 폼 실시간 검증 추가 | 6개 폼 화면 | 2시간 | ⬜ |
| 5-2 | 에러 메시지 개선 | 전체 | 2시간 | ⬜ |
| 5-3 | 네트워크 에러 재시도 UI | `MingrrErrorState` | 1시간 | ⬜ |

---

### 🎯 Phase 6: UX 개선

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 6-1 | 리스트 아이템 애니메이션 | 주요 리스트 화면 | 2시간 | ⬜ |
| 6-2 | 좋아요 애니메이션 | `MingrrLikeButton` | 1시간 | ⬜ |
| 6-3 | Semantics 전체 적용 | 주요 화면 | 2시간 | ⬜ |

---

### 📊 전체 작업 요약

| Phase | 작업 수 | 완료 | 진행률 |
|:-----:|:------:|:----:|:------:|
| Phase 1: 상태 관리 | 7 | 0 | **0%** |
| Phase 2: 디자인 리팩토링 | 28 | 0 | **0%** |
| Phase 3: 성능 최적화 | 5 | 0 | **0%** |
| Phase 4: 코드 품질 | 4 | 0 | **0%** |
| Phase 5: 보안/안정성 | 3 | 0 | **0%** |
| Phase 6: UX 개선 | 3 | 0 | **0%** |
| **전체** | **50** | **0** | **0%** |

---

## 📊 진행 현황 요약

| Phase | 전체 | 완료 | 진행률 |
|:-----:|:----:|:----:|:------:|
| Phase 1: 상태 관리 | 7 | 0 | **0%** |
| Phase 2: 디자인 리팩토링 | 28 | 0 | **0%** |
| Phase 3: 성능 최적화 | 5 | 0 | **0%** |
| Phase 4: 코드 품질 | 4 | 0 | **0%** |
| Phase 5: 보안/안정성 | 3 | 0 | **0%** |
| Phase 6: UX 개선 | 3 | 0 | **0%** |
| **전체** | **50** | **0** | **0%** |

---

## 📊 리팩토링 대상 요약

| 카테고리 | 대상 수 | 주요 변경 |
|----------|:------:|----------|
| 리스트 카드 | 7개 | 이미지/패딩 축소, 폰트 통일 |
| 상세 화면 | 6개 | padding 24→16, fontSize 축소 |
| 등록/수정 화면 | 8개 | 입력 필드 높이, 섹션 간격 축소 |
| 바텀시트 | 12개 | padding 24→16, fontSize 축소 |
| 다이얼로그 | 9개 | padding 24→16, 아이콘 축소 |
| 공통 위젯 | 15개 | 버튼 높이, 배지 크기 축소 |
| 기타 화면 | 8개 | 카드/아이템 padding 축소 |
| **총계** | **65개** | - |

---

## 📊 예상 효과

| 항목 | Before | After |
|------|--------|-------|
| 등록 후 새로고침 | 수동 필요 | 자동 |
| 카드 크기 통일성 | 60% | 100% |
| 상세/폼 화면 통일성 | 70% | 100% |
| 바텀시트/다이얼로그 통일성 | 65% | 100% |
| 디자인 값 상수화율 | 30% | 90% |
| Deprecated API | 266개 | 0개 |
| TODO 항목 | 59개 | 10개 이하 |
| 하드코딩 값 | 2,000+ | 300 이하 |
| UX 완성도 | 85% | 98% |
| 화면당 정보 밀도 | 낮음 | **30%↑** |

---

## 🔗 관련 문서

- [REFACTORING_V1.md](./REFACTORING_V1.md) - 1차 리팩토링 (완료)
- [REFACTORING_V2.md](./REFACTORING_V2.md) - 2차 리팩토링 (완료)
- [GUIDE_FILE_PLANNING.md](./GUIDE_FILE_PLANNING.md) - 가이드 파일 계획
- [FIRESTORE_STRUCTURE.md](../FIRESTORE_STRUCTURE.md) - DB 구조

---

*최종 업데이트: 2026-01-20*
