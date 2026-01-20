# MINGRR 4차 리팩토링 가이드 (V4)

> 작성일: 2026-01-20  
> 상태: 🚧 **계획 수립 완료**  
> 목적: 전체 앱 디자인 컴팩트화, 반응형 대응, 상수화 완성, 디자인 통일성 100% 달성

---

## 📊 V4 리팩토링 개요

V1~V3에서 공통 컴포넌트화, 백엔드 연동, 상태 관리 개선을 완료했습니다.  
V4에서는 **전체 앱 디자인 컴팩트화** 및 **반응형 대응**을 집중적으로 진행합니다.

| 영역 | 목표 |
|------|------|
| **📐 컴팩트 디자인** | 전체 화면 요소 크기 축소, 정보 밀도 향상 |
| **🎨 디자인 통일성** | 상수화 미적용 영역 완전 적용 |
| **📱 반응형 대응** | 다양한 기기에서 overflow 없이 동작 |
| **🧹 코드 품질** | 인라인 스타일 제거, 상수 참조로 전환 |

---

## 📊 현재 상황 분석

### 상수화 적용 현황

| 항목 | 사용 횟수 | 파일 수 | 상태 |
|------|:--------:|:------:|:----:|
| `AppSizes.` 사용 | 1,944회 | 95개 | ✅ 양호 |
| `AppTextStyles.` 사용 | 403회 | 50개 | 🟡 부분 적용 |
| 인라인 `fontSize:` | 405회 | 70개 | 🔴 상수화 필요 |
| 인라인 `SizedBox(height/width:)` | 117회 | 46개 | 🟡 일부 상수화 필요 |

### 인라인 스타일 주요 발생 파일

| 파일 | fontSize 횟수 | 우선순위 |
|------|:------------:|:--------:|
| `walk_record_detail_screen.dart` | 15회 | 🔴 높음 |
| `walk_screen.dart` | 14회 | 🔴 높음 |
| `kkosunnae_widgets.dart` | 13회 | 🟡 중간 |
| `filter_widgets.dart` | 11회 | 🟡 중간 |
| `rating_widgets.dart` | 11회 | 🟡 중간 |
| `profile_screen.dart` | 11회 | 🔴 높음 |
| `home_screen.dart` | 9회 | 🔴 높음 |
| `compatibility_widgets.dart` | 8회 | 🟡 중간 |
| `form_components.dart` | 8회 | 🟡 중간 |
| `chat_list_screen.dart` | 8회 | 🔴 높음 |

---

## 🔴 Phase 1: 컴팩트 디자인 시스템 정립 (우선순위: 높음)

### 1.1 컴팩트 디자인 토큰 추가

현재 `AppSizes`와 `AppTextStyles`에 컴팩트 버전 상수를 추가합니다.

#### 1.1.1 AppSizes 컴팩트 상수 추가

```dart
// lib/core/constants/app_sizes.dart 추가

class AppSizes {
  // ===== 컴팩트 패딩 (기존보다 작게) =====
  static const double paddingCompactXS = 4.0;   // 기존 paddingXS
  static const double paddingCompactS = 6.0;    // 기존 paddingS(8) → 6
  static const double paddingCompactM = 10.0;   // 기존 paddingM(16) → 10
  static const double paddingCompactL = 12.0;   // 기존 paddingL(24) → 12
  
  // ===== 컴팩트 카드 전용 =====
  static const double cardPaddingH = 12.0;      // 카드 좌우 패딩
  static const double cardPaddingV = 10.0;      // 카드 상하 패딩
  static const double cardMarginBottom = 8.0;   // 카드 간 간격
  static const double cardImageS = 56.0;        // 소형 썸네일
  static const double cardImageM = 70.0;        // 기본 썸네일 (커뮤니티 기준)
  static const double cardImageL = 80.0;        // 상품 썸네일 (기존 100 → 80)
  
  // ===== 컴팩트 폼 전용 =====
  static const double formInputHeightCompact = 44.0;  // 기존 52 → 44
  static const double formInputPaddingCompact = 10.0; // 기존 16 → 10
  static const double formSectionGapCompact = 12.0;   // 섹션 간격 (기존 24 → 12)
  static const double formFieldGapCompact = 6.0;      // 필드 간격 (기존 8 → 6)
  
  // ===== 컴팩트 상세 화면 전용 =====
  static const double detailPaddingCompact = 12.0;    // 기존 24 → 12
  static const double detailSectionGapCompact = 12.0; // 섹션 간격
  static const double detailItemGapCompact = 6.0;     // 아이템 간격
  
  // ===== 컴팩트 바텀시트/다이얼로그 =====
  static const double sheetPaddingCompact = 12.0;     // 기존 24 → 12
  static const double sheetTitleGapCompact = 10.0;    // 제목-내용 간격
  static const double sheetButtonGapCompact = 6.0;    // 버튼 간격
  
  // ===== 컴팩트 버튼 =====
  static const double buttonHeightCompact = 40.0;     // 기존 48 → 40
  static const double buttonHeightCompactS = 32.0;    // 소형 버튼
}
```

#### 1.1.2 AppTextStyles 컴팩트 스타일 추가

```dart
// lib/core/theme/app_text_styles.dart 추가

class AppTextStyles {
  // ===== 컴팩트 카드 텍스트 =====
  /// 카드 제목: 14px, w600 (기존 15 → 14)
  static TextStyle cardTitleCompact(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 카드 본문: 12px (기존 13 → 12)
  static TextStyle cardBodyCompact(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
  
  /// 카드 캡션: 10px (기존 11 → 10)
  static TextStyle cardCaptionCompact(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
  
  // ===== 컴팩트 상세 화면 텍스트 =====
  /// 상세 제목: 16px, w600 (기존 18-20 → 16)
  static TextStyle detailTitleCompact(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 상세 섹션 제목: 14px, w600 (기존 16 → 14)
  static TextStyle detailSectionTitleCompact(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 상세 본문: 13px (기존 14-16 → 13)
  static TextStyle detailBodyCompact(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  // ===== 컴팩트 바텀시트/다이얼로그 =====
  /// 시트 제목: 16px, w600 (기존 18 → 16)
  static TextStyle sheetTitleCompact(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
  
  /// 시트 본문: 13px (기존 14 → 13)
  static TextStyle sheetBodyCompact(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
```

### 1.2 작업 항목

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 1-1 | AppSizes 컴팩트 상수 추가 | `app_sizes.dart` | 30분 | ⬜ 대기 |
| 1-2 | AppTextStyles 컴팩트 스타일 추가 | `app_text_styles.dart` | 30분 | ⬜ 대기 |
| 1-3 | 컴팩트 상수 문서화 | `app_sizes.dart`, `app_text_styles.dart` | 15분 | ⬜ 대기 |

---

## 🎨 Phase 2: 인라인 스타일 상수화 (우선순위: 높음)

### 2.1 인라인 fontSize 상수화

인라인 `fontSize:` 사용을 `AppTextStyles` 참조로 전환합니다.

#### 2.1.1 우선순위 높음 (화면 파일)

| # | 파일 | fontSize 횟수 | 예상 시간 | 상태 |
|:-:|------|:------------:|:--------:|:----:|
| 2-1 | `walk_record_detail_screen.dart` | 15회 | 30분 | ⬜ 대기 |
| 2-2 | `walk_screen.dart` | 14회 | 30분 | ⬜ 대기 |
| 2-3 | `profile_screen.dart` | 11회 | 25분 | ⬜ 대기 |
| 2-4 | `home_screen.dart` | 9회 | 20분 | ⬜ 대기 |
| 2-5 | `chat_list_screen.dart` | 8회 | 20분 | ⬜ 대기 |
| 2-6 | `login_screen.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-7 | `received_dating_requests_screen.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-8 | `health_record_detail_screens.dart` | 5회 | 15분 | ⬜ 대기 |
| 2-9 | `notification_screen.dart` | 5회 | 15분 | ⬜ 대기 |
| 2-10 | `marketplace_screen.dart` | 4회 | 10분 | ⬜ 대기 |

#### 2.1.2 우선순위 중간 (공통 위젯)

| # | 파일 | fontSize 횟수 | 예상 시간 | 상태 |
|:-:|------|:------------:|:--------:|:----:|
| 2-11 | `kkosunnae_widgets.dart` | 13회 | 25분 | ⬜ 대기 |
| 2-12 | `filter_widgets.dart` | 11회 | 25분 | ⬜ 대기 |
| 2-13 | `rating_widgets.dart` | 11회 | 25분 | ⬜ 대기 |
| 2-14 | `compatibility_widgets.dart` | 8회 | 20분 | ⬜ 대기 |
| 2-15 | `form_components.dart` | 8회 | 20분 | ⬜ 대기 |
| 2-16 | `location_bubble_widget.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-17 | `location_selector.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-18 | `map/location_display_card.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-19 | `profile_modal_components.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-20 | `top_navigation.dart` | 5회 | 15분 | ⬜ 대기 |

#### 2.1.3 우선순위 낮음 (다이얼로그/기타)

| # | 파일 | fontSize 횟수 | 예상 시간 | 상태 |
|:-:|------|:------------:|:--------:|:----:|
| 2-21 | `dialogs/info_dialog.dart` | 6회 | 15분 | ⬜ 대기 |
| 2-22 | `dialogs/info_action_dialog.dart` | 5회 | 15분 | ⬜ 대기 |
| 2-23 | `platform_map_widget.dart` | 5회 | 15분 | ⬜ 대기 |
| 2-24 | `dating_card.dart` | 4회 | 10분 | ⬜ 대기 |
| 2-25 | `dialogs/error_dialog.dart` | 4회 | 10분 | ⬜ 대기 |
| 2-26 | `home_reminder_banner.dart` | 4회 | 10분 | ⬜ 대기 |
| 2-27 | `loading_widgets.dart` | 4회 | 10분 | ⬜ 대기 |
| 2-28 | `map/map_location_picker.dart` | 4회 | 10분 | ⬜ 대기 |
| 2-29 | `pet_profile_modal.dart` | 4회 | 10분 | ⬜ 대기 |
| 2-30 | 기타 40개 파일 | 1-3회씩 | 2시간 | ⬜ 대기 |

---

## 📐 Phase 3: 컴팩트 디자인 적용 (우선순위: 높음)

### 3.1 리스트 카드 컴팩트화

커뮤니티 카드(`_CommunityPostCard`)를 기준으로 모든 리스트 카드를 컴팩트화합니다.

#### 기준 모델: 커뮤니티 카드

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

| # | 카드 | 파일 | 현재 | 목표 | 상태 |
|:-:|------|------|:----:|:----:|:----:|
| 3-1 | `ProductCard` | `product_card.dart` | 이미지 100px | 80px | ⬜ 대기 |
| 3-2 | `JobCard` | `product_card.dart` | 패딩 16px | 12px | ⬜ 대기 |
| 3-3 | `DatingRecommendCard` | `dating_card.dart` | 높이 280px | 220px | ⬜ 대기 |
| 3-4 | `DatingNearbyCard` | `dating_card.dart` | 패딩 16px | 12px | ⬜ 대기 |
| 3-5 | `DatingBreedingCard` | `dating_card.dart` | 패딩 16px | 12px | ⬜ 대기 |
| 3-6 | `_GroupCard` | `group_list_screen.dart` | 패딩 16px | 12px | ⬜ 대기 |
| 3-7 | 채팅 리스트 아이템 | `chat_list_screen.dart` | 패딩 16px | 12px | ⬜ 대기 |
| 3-8 | 알림 리스트 아이템 | `notification_screen.dart` | 패딩 16px | 12px | ⬜ 대기 |

### 3.2 상세 화면 컴팩트화

| # | 화면 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 3-9 | 반려동물 상세 | `pet_detail_screen.dart` | padding 24→12, fontSize 축소 | ⬜ 대기 |
| 3-10 | 상품 상세 | `product_detail_screen.dart` | padding 24→12, fontSize 축소 | ⬜ 대기 |
| 3-11 | 알바 상세 | `job_detail_screen.dart` | padding 24→12, fontSize 축소 | ⬜ 대기 |
| 3-12 | 커뮤니티 상세 | `community_detail_screen.dart` | padding 24→12, fontSize 축소 | ⬜ 대기 |
| 3-13 | 소모임 상세 | `group_detail_screen.dart` | padding 24→12, fontSize 축소 | ⬜ 대기 |
| 3-14 | 건강기록 상세 | `health_record_detail_screens.dart` | padding 24→12, fontSize 축소 | ⬜ 대기 |

### 3.3 등록/수정 화면 컴팩트화

| # | 화면 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 3-15 | 상품 등록 | `product_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3-16 | 교배 등록 | `breeding_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3-17 | 커뮤니티 글쓰기 | `community_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3-18 | 소모임 만들기 | `group_write_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3-19 | 반려동물 수정 | `pet_edit_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3-20 | 프로필 수정 | `profile_edit_screen.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |
| 3-21 | 건강기록 등록 | `health_record_add_screens.dart` | 입력 필드 높이, 섹션 간격 축소 | ⬜ 대기 |

### 3.4 바텀시트/다이얼로그 컴팩트화

| # | 위젯 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 3-22 | `MingrrBottomSheet` | `mingrr_bottom_sheet.dart` | padding 24→12, fontSize 18→16 | ⬜ 대기 |
| 3-23 | `MingrrBottomButtonBar` | `mingrr_bottom_sheet.dart` | 버튼 높이, 패딩 축소 | ⬜ 대기 |
| 3-24 | `ConfirmSheet` | `confirm_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 3-25 | `ReportSheet` | `report_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 3-26 | `RequestSheet` | `request_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 3-27 | `ImagePickerSheet` | `image_picker_sheet.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 3-28 | `AppDialog` | `app_dialog.dart` | padding 24→16, 아이콘 56→48 | ⬜ 대기 |
| 3-29 | `InfoDialog` | `info_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 3-30 | `InputDialog` | `input_dialog.dart` | padding, fontSize 축소 | ⬜ 대기 |

### 3.5 기타 화면 컴팩트화

| # | 화면 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 3-31 | 홈 | `home_screen.dart` | 카드 padding, fontSize 축소 | ⬜ 대기 |
| 3-32 | 프로필 | `profile_screen.dart` | 섹션 padding, fontSize 축소 | ⬜ 대기 |
| 3-33 | 채팅 상세 | `chat_detail_screen.dart` | 메시지 버블 padding 축소 | ⬜ 대기 |
| 3-34 | 산책 | `walk_screen.dart` | 카드 padding, fontSize 축소 | ⬜ 대기 |
| 3-35 | 건강 | `health_screen.dart` | 카드 padding, fontSize 축소 | ⬜ 대기 |
| 3-36 | 설정 화면들 | `settings/*.dart` | 리스트 아이템 padding 축소 | ⬜ 대기 |

---

## 📱 Phase 4: 반응형 대응 (우선순위: 높음)

### 4.1 Overflow 방지

다양한 화면 크기에서 overflow가 발생하지 않도록 수정합니다.

#### 4.1.1 반응형 유틸리티 추가

```dart
// lib/core/utils/responsive_utils.dart (신규)

class ResponsiveUtils {
  /// 화면 너비에 따른 패딩 계산
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 8.0;   // 소형 기기
    if (width < 400) return 12.0;  // 중형 기기
    return 16.0;                    // 대형 기기
  }
  
  /// 화면 너비에 따른 카드 이미지 크기
  static double getCardImageSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 56.0;
    if (width < 400) return 64.0;
    return 70.0;
  }
  
  /// 화면 너비에 따른 폰트 스케일
  static double getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.9;
    if (width < 400) return 0.95;
    return 1.0;
  }
  
  /// 소형 기기 여부
  static bool isSmallDevice(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// 중형 기기 여부
  static bool isMediumDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 400;
  }
}
```

#### 4.1.2 Overflow 발생 가능 영역 점검

| # | 화면/위젯 | 문제 영역 | 해결 방안 | 상태 |
|:-:|----------|----------|----------|:----:|
| 4-1 | 카드 제목 | 긴 텍스트 | `maxLines`, `overflow: ellipsis` | ⬜ 대기 |
| 4-2 | 필터 칩 | 좁은 화면 | `Wrap` 또는 가로 스크롤 | ⬜ 대기 |
| 4-3 | 버튼 Row | 좁은 화면 | `Flexible` 또는 세로 배치 | ⬜ 대기 |
| 4-4 | 탭 바 | 탭 많을 때 | 스크롤 가능 탭 바 | ⬜ 대기 |
| 4-5 | 배지 Row | 배지 많을 때 | `Wrap` 또는 `+N` 표시 | ⬜ 대기 |
| 4-6 | 가격/거리 정보 | 긴 텍스트 | `Flexible`, `FittedBox` | ⬜ 대기 |

### 4.2 작업 항목

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 4-7 | ResponsiveUtils 생성 | `responsive_utils.dart` (신규) | 30분 | ⬜ 대기 |
| 4-8 | 카드 위젯 반응형 적용 | `product_card.dart`, `dating_card.dart` | 1시간 | ⬜ 대기 |
| 4-9 | 상세 화면 반응형 적용 | 6개 상세 화면 | 1시간 | ⬜ 대기 |
| 4-10 | 폼 화면 반응형 적용 | 7개 폼 화면 | 1시간 | ⬜ 대기 |
| 4-11 | 바텀시트 반응형 적용 | `mingrr_bottom_sheet.dart` 등 | 30분 | ⬜ 대기 |

---

## 🧹 Phase 5: 공통 위젯 컴팩트화 (우선순위: 중간)

### 5.1 공통 위젯 크기 조정

| # | 위젯 | 파일 | 현재 | 목표 | 상태 |
|:-:|------|------|:----:|:----:|:----:|
| 5-1 | `MingrrButton` | `common_widgets.dart` | 높이 48px | 40px (compact) | ⬜ 대기 |
| 5-2 | `MingrrTextField` | `form_components.dart` | 높이 52px | 44px | ⬜ 대기 |
| 5-3 | `MingrrSectionLabel` | `form_components.dart` | fontSize 14px | 13px | ⬜ 대기 |
| 5-4 | `InfoBadge` | `info_badge.dart` | padding 8px | 6px | ⬜ 대기 |
| 5-5 | `TraitBadge` | `trait_badge.dart` | padding 8px | 6px | ⬜ 대기 |
| 5-6 | `MingrrCategoryChips` | `filter_components.dart` | 칩 높이 32px | 28px | ⬜ 대기 |
| 5-7 | `LocationBubbleWidget` | `location_bubble_widget.dart` | padding 12px | 10px | ⬜ 대기 |
| 5-8 | `HomeReminderBanner` | `home_reminder_banner.dart` | padding 16px | 12px | ⬜ 대기 |

### 5.2 프로필 모달 컴팩트화

| # | 위젯 | 파일 | 주요 수정 | 상태 |
|:-:|------|------|----------|:----:|
| 5-9 | `PetProfileModal` | `pet_profile_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 5-10 | `GuardianProfileModal` | `guardian_profile_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |
| 5-11 | `GroupProfileModal` | `group_profile_modal.dart` | padding, fontSize 축소 | ⬜ 대기 |

---

## ⚡ Phase 6: 성능 및 코드 품질 (우선순위: 중간)

### 6.1 남은 Deprecated API 제거

| # | API | 사용 횟수 | 대체 API | 상태 |
|:-:|-----|:--------:|----------|:----:|
| 6-1 | `dogsCollection` | 1개 | `petsCollection` | ⬜ 대기 |
| 6-2 | `likesCollection` | 1개 | 제거 | ⬜ 대기 |
| 6-3 | `NotificationIconButton` | 0개 | 제거 가능 | ⬜ 대기 |
| 6-4 | `CategoryFilterChips` | 0개 | 제거 가능 | ⬜ 대기 |
| 6-5 | `DistanceBottomSheet` | 0개 | 제거 가능 | ⬜ 대기 |

### 6.2 TODO 항목 정리

| 우선순위 | 파일 | TODO 수 | 상태 |
|:-------:|------|:------:|:----:|
| 🔴 높음 | `chat_detail_screen.dart` | 6개 | ⬜ 대기 |
| 🔴 높음 | `customer_service_screen.dart` | 4개 | ⬜ 대기 |
| 🟡 중간 | `image_picker_sheet.dart` | 4개 | ⬜ 대기 |
| 🟡 중간 | `pet_edit_screen.dart` | 4개 | ⬜ 대기 |
| 🟢 낮음 | 기타 파일들 | 37개 | ⬜ 대기 |

---

## 📋 리팩토링 로드맵 (작업별 체크리스트)

### 📅 Week 1: 디자인 토큰 및 상수화

| 일차 | 작업 | 예상 시간 |
|:---:|------|:--------:|
| Day 1 | Phase 1: 컴팩트 디자인 토큰 추가 | 1.5시간 |
| Day 2 | Phase 2-1: 화면 파일 fontSize 상수화 (10개) | 3시간 |
| Day 3 | Phase 2-2: 공통 위젯 fontSize 상수화 (10개) | 3시간 |
| Day 4 | Phase 2-3: 다이얼로그/기타 fontSize 상수화 | 2시간 |
| Day 5 | Phase 4-7: ResponsiveUtils 생성 | 30분 |

### 📅 Week 2: 컴팩트 디자인 적용

| 일차 | 작업 | 예상 시간 |
|:---:|------|:--------:|
| Day 1 | Phase 3-1~8: 리스트 카드 컴팩트화 | 3시간 |
| Day 2 | Phase 3-9~14: 상세 화면 컴팩트화 | 3시간 |
| Day 3 | Phase 3-15~21: 등록/수정 화면 컴팩트화 | 3시간 |
| Day 4 | Phase 3-22~30: 바텀시트/다이얼로그 컴팩트화 | 2시간 |
| Day 5 | Phase 3-31~36: 기타 화면 컴팩트화 | 2시간 |

### 📅 Week 3: 반응형 및 마무리

| 일차 | 작업 | 예상 시간 |
|:---:|------|:--------:|
| Day 1 | Phase 4-1~6: Overflow 방지 점검 | 2시간 |
| Day 2 | Phase 4-8~11: 반응형 적용 | 3.5시간 |
| Day 3 | Phase 5: 공통 위젯 컴팩트화 | 3시간 |
| Day 4 | Phase 6: Deprecated 제거 및 TODO 정리 | 2시간 |
| Day 5 | 전체 테스트 및 미세 조정 | 3시간 |

---

## 📊 전체 작업 요약

| Phase | 작업 수 | 완료 | 진행률 |
|:-----:|:------:|:----:|:------:|
| Phase 1: 디자인 토큰 | 3 | 0 | **0%** |
| Phase 2: 인라인 상수화 | 30 | 0 | **0%** |
| Phase 3: 컴팩트 적용 | 36 | 0 | **0%** |
| Phase 4: 반응형 대응 | 11 | 0 | **0%** |
| Phase 5: 공통 위젯 | 11 | 0 | **0%** |
| Phase 6: 코드 품질 | 10 | 0 | **0%** |
| **전체** | **101** | **0** | **0%** |

**예상 소요 기간**: 약 3주 (15일)

---

## 📊 예상 효과

| 항목 | Before | After |
|------|--------|-------|
| 인라인 fontSize | 405회 | 50회 이하 |
| 인라인 SizedBox | 117회 | 30회 이하 |
| 카드 크기 통일성 | 70% | 100% |
| 상세/폼 화면 통일성 | 80% | 100% |
| 바텀시트/다이얼로그 통일성 | 75% | 100% |
| 디자인 값 상수화율 | 70% | 95% |
| 화면당 정보 밀도 | 낮음 | **30%↑** |
| Overflow 발생 | 일부 | **0건** |
| 반응형 대응 | 부분 | **100%** |

---

## 📐 디자인 값 변경 요약

### Padding 변경

| 용도 | Before | After | 감소율 |
|------|:------:|:-----:|:------:|
| 카드 패딩 | 16px | 10-12px | **30%↓** |
| 상세 화면 패딩 | 24px | 12px | **50%↓** |
| 폼 화면 패딩 | 24px | 12px | **50%↓** |
| 바텀시트 패딩 | 24px | 12px | **50%↓** |
| 다이얼로그 패딩 | 24px | 16px | **33%↓** |
| 섹션 간격 | 24px | 12px | **50%↓** |

### FontSize 변경

| 용도 | Before | After | 감소율 |
|------|:------:|:-----:|:------:|
| 카드 제목 | 15px | 14px | **7%↓** |
| 카드 본문 | 13px | 12px | **8%↓** |
| 카드 캡션 | 11px | 10px | **9%↓** |
| 상세 제목 | 18-20px | 16px | **15%↓** |
| 상세 본문 | 14-16px | 13px | **15%↓** |
| 시트 제목 | 18px | 16px | **11%↓** |

### 컴포넌트 크기 변경

| 컴포넌트 | Before | After | 감소율 |
|----------|:------:|:-----:|:------:|
| 버튼 높이 | 48px | 40px | **17%↓** |
| 입력 필드 높이 | 52px | 44px | **15%↓** |
| 카드 이미지 (상품) | 100px | 80px | **20%↓** |
| 추천 카드 높이 | 280px | 220px | **21%↓** |
| 다이얼로그 아이콘 | 56px | 48px | **14%↓** |

---

## 🔗 관련 문서

- [REFACTORING_V1.md](./REFACTORING_V1.md) - 1차 리팩토링 (완료)
- [REFACTORING_V2.md](./REFACTORING_V2.md) - 2차 리팩토링 (완료)
- [REFACTORING_V3.md](./REFACTORING_V3.md) - 3차 리팩토링 (완료)
- [GUIDE_FILE_PLANNING.md](./GUIDE_FILE_PLANNING.md) - 가이드 파일 계획
- [FIRESTORE_STRUCTURE.md](../FIRESTORE_STRUCTURE.md) - DB 구조

---

*최종 업데이트: 2026-01-20*
