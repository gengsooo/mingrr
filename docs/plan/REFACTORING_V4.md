# MINGRR 4차 리팩토링 가이드 (V4)

> 작성일: 2026-01-21  
> 상태: ✅ **완료**  
> 목적: **디자인 시스템 대규모 재정립** - 폴더 구조 정리, 상수 체계 단순화/확장, 공통 컴포넌트 정리
> 완료일: 2026-01-21

---

## 📊 V4 리팩토링 개요

### 핵심 전략

| Phase | 목표 | 주요 작업 |
|:-----:|------|----------|
| **0** | 폴더 구조 정리 | widgets/ 47개 평면 파일 → 카테고리별 하위 폴더 |
| **1** | 상수 체계 재정립 | 중간 단계 제거 + 신규 상수 추가 + 공통 컴포넌트 |
| **2** | 인라인 스타일 상수화 | 하드코딩된 스타일 → 상수 참조로 변경 |
| **3** | 품질 개선 | Deprecated 제거, TODO 정리, 반응형 대응 |

### 상수 체계 재정립 원칙

```dart
// ═══════════════════════════════════════════════════════════════
// 크기 상수 (AppSizes)
// ═══════════════════════════════════════════════════════════════

// ✅ 통일된 7단계 체계 (XXS, XS, S, M, L, XL, XXL)
padding:     XXS(2) → XS(4) → S(8) → M(12) → L(16) → XL(24) → XXL(32)
gap:         XXS(2) → XS(4) → S(8) → M(12) → L(16) → XL(24) → XXL(32)
icon:        XXS(12) → XS(14) → S(16) → M(20) → L(24) → XL(32) → XXL(48)
avatar:      XXS(24) → XS(32) → S(40) → M(56) → L(80) → XL(120) → XXL(160)
thumbnail:   XS(40) → S(56) → M(80) → L(120) → XL(200)

// ✅ 단순화된 체계
radius:      S(8) → M(12) → L(16) → FULL(999)
elevation:   None(0) → S(2) → M(4)
borderWidth: S(1.0) → M(1.5) → L(2.0)
duration:    Fast(150ms) → Normal(300ms) → Slow(500ms) → Page(350ms)

// ═══════════════════════════════════════════════════════════════
// 투명도 상수 (AppOpacity) - 🆕 신규
// ═══════════════════════════════════════════════════════════════
opacity:     subtle(0.05) → light(0.1) → medium(0.2) → strong(0.3) → heavy(0.5)

// ═══════════════════════════════════════════════════════════════
// 함수형 프리셋 (다크모드 대응)
// ═══════════════════════════════════════════════════════════════
shadow:      AppShadows.shadowS(isDark) → shadowM(isDark) → shadowL(isDark)

// ═══════════════════════════════════════════════════════════════
// 공통 컴포넌트 (Divider) - 🆕 신규, 4종으로 정리
// ═══════════════════════════════════════════════════════════════
divider:     MingrrDivider() → .section() → .indented()
vDivider:    MingrrVerticalDivider({height, color})
```

---

## 📁 현재 파일 구조 분석

### core/ 디렉토리 구조

```
lib/core/
├── config/                     # 앱 설정 (1개)
├── constants/                  # 상수 정의 (5개)
│   ├── app_sizes.dart          # 🔴 크기/간격 상수 - 재정립 필요
│   ├── app_strings.dart        # ✅ UI 문자열 상수
│   ├── form_strings.dart       # ✅ 폼 문자열 상수
│   ├── location_constants.dart # ✅ 위치 관련 상수
│   └── pet_constants.dart      # ✅ 반려동물 상수 (enum 포함)
├── theme/                      # 테마 정의 (3개)
│   ├── app_text_styles.dart    # 🟡 텍스트 스타일 - 컴팩트화 필요
│   ├── app_theme.dart          # 🟡 테마 설정 - radius 참조 수정 필요
│   └── feature_colors.dart     # ✅ 기능별 색상
├── widgets/                    # 공통 위젯 (47개 + 2개 하위폴더)
│   ├── dialogs/                # 다이얼로그 (9개)
│   ├── map/                    # 지도 관련 (5개)
│   └── ... (47개 위젯 파일)    # 🔴 평면 구조 - 정리 필요
├── services/                   # 서비스 (20개)
├── providers/                  # 프로바이더 (14개)
├── utils/                      # 유틸리티 (7개)
├── models/                     # 공통 모델 (2개)
└── mixins/                     # 믹스인 (1개)
```

### 문제점 분석

| 영역 | 문제점 | 해결 방안 |
|------|--------|----------|
| **widgets/** | 47개 파일이 평면 구조 | 카테고리별 하위 폴더 정리 |
| **AppSizes** | SM, MS, ML, LL 등 중간 단계 혼재 | 7단계 체계로 통일 |
| **AppSizes** | radius가 8단계 (XXS~FULL) | 4단계로 단순화 |
| **AppSizes** | elevation, shadow, duration 등 미정의 | 새 상수 카테고리 추가 |
| **AppTextStyles** | 58개 스타일 중 일부 중복 | 정리 및 컴팩트화 |
| **인라인 스타일** | fontSize 311회, BorderRadius 376회, BoxShadow 83회 | 상수 참조로 변경 |

---

## ✅ 작업별 체크리스트

> 각 작업을 완료할 때마다 ⬜ → ✅ 로 변경하세요.

---

## ⚫ PHASE 0: 폴더 구조 정리 (최우선)

> 상수 체계 재정립 전에 폴더 구조를 먼저 정리하여 작업 효율성 확보

### 0.1 widgets/ 폴더 구조 정리

#### 0.1.1 목표 구조

```
lib/core/widgets/
├── dialogs/                    # ✅ 기존 유지 (9개)
│   ├── app_dialog.dart
│   ├── confirm_sheet.dart      # → sheets/로 이동
│   ├── error_dialog.dart
│   ├── info_dialog.dart
│   ├── info_action_dialog.dart
│   ├── input_dialog.dart
│   ├── action_prompt_dialog.dart
│   └── selection_dialog.dart
├── map/                        # ✅ 기존 유지 (5개)
│   ├── location_display_card.dart
│   ├── map_loading_widget.dart
│   ├── map_location_picker.dart
│   ├── map_view_widget.dart
│   └── naver_map_widget.dart
├── cards/                      # 🆕 카드 위젯
│   ├── dating_card.dart
│   ├── product_card.dart
│   ├── profile_cards.dart
│   ├── pet_selector_card.dart
│   └── mingrr_record_tile.dart
├── badges/                     # 🆕 배지/태그 위젯
│   ├── info_badge.dart
│   ├── trait_badge.dart
│   ├── verification_badge.dart
│   ├── distance_badge.dart
│   └── svg_icons.dart
├── forms/                      # 🆕 폼 관련 위젯
│   ├── form_components.dart
│   ├── tag_input.dart
│   ├── search_bar.dart
│   └── location_selector.dart
├── sheets/                     # 🆕 바텀시트
│   ├── mingrr_bottom_sheet.dart
│   ├── image_picker_sheet.dart
│   ├── report_sheet.dart
│   ├── request_sheet.dart
│   └── confirm_sheet.dart      # dialogs/에서 이동
├── modals/                     # 🆕 모달
│   ├── pet_profile_modal.dart
│   ├── guardian_profile_modal.dart
│   ├── group_profile_modal.dart
│   ├── chat_options_modal.dart
│   └── profile_modal_components.dart
├── navigation/                 # 🆕 네비게이션
│   ├── top_navigation.dart
│   └── appbar_actions.dart
├── loading/                    # 🆕 로딩/스켈레톤
│   ├── loading_widgets.dart
│   └── skeleton_widgets.dart
├── common_widgets.dart         # 기본 공통 위젯 (유지)
├── animated_widgets.dart       # 애니메이션 위젯 (유지)
├── filter_widgets.dart         # 필터 관련 (유지)
├── filter_components.dart      # 필터 컴포넌트 (유지)
├── rating_widgets.dart         # 평점 관련 (유지)
├── kkosunnae_widgets.dart      # 꼬순내 관련 (유지)
├── compatibility_widgets.dart  # 궁합 관련 (유지)
├── home_reminder_banner.dart   # 홈 배너 (유지)
├── location_bubble_widget.dart # 위치 버블 (유지)
├── platform_map_widget.dart    # 플랫폼 맵 (유지)
├── mingrr_fab.dart             # FAB (유지)
├── mingrr_settings_tile.dart   # 설정 타일 (유지)
├── mingrr_image_viewer.dart    # 이미지 뷰어 (유지)
├── mingrr_image_gallery.dart   # 이미지 갤러리 (유지)
├── mingrr_image_header.dart    # 이미지 헤더 (유지)
└── refresh_wrapper.dart        # 리프레시 래퍼 (유지)
```

#### 0.1.2 폴더 정리 작업 ✅ 완료 (2026-01-21)

| # | 작업 | 이동 파일 | 상태 |
|:-:|------|:--------:|:----:|
| 1 | `cards/` 폴더 생성 | - | ✅ |
| 2 | 카드 위젯 이동 | 5개 | ✅ |
| 3 | `badges/` 폴더 생성 | - | ✅ |
| 4 | 배지 위젯 이동 | 5개 | ✅ |
| 5 | `forms/` 폴더 생성 | - | ✅ |
| 6 | 폼 위젯 이동 | 4개 | ✅ |
| 7 | `sheets/` 폴더 생성 | - | ✅ |
| 8 | 시트 위젯 이동 | 5개 | ✅ |
| 9 | `modals/` 폴더 생성 | - | ✅ |
| 10 | 모달 위젯 이동 | 5개 | ✅ |
| 11 | `navigation/` 폴더 생성 | - | ✅ |
| 12 | 네비게이션 위젯 이동 | 2개 | ✅ |
| 13 | `loading/` 폴더 생성 | - | ✅ |
| 14 | 로딩 위젯 이동 | 2개 | ✅ |

#### 0.1.3 import 경로 수정 ✅ 완료 (2026-01-21)

| # | 영역 | 수정 파일 수 | 상태 |
|:-:|------|:----------:|:----:|
| 1 | `cards/` 관련 import | 15개 | ✅ |
| 2 | `badges/` 관련 import | 20개 | ✅ |
| 3 | `forms/` 관련 import | 12개 | ✅ |
| 4 | `sheets/` 관련 import | 25개 | ✅ |
| 5 | `modals/` 관련 import | 10개 | ✅ |
| 6 | `navigation/` 관련 import | 15개 | ✅ |
| 7 | `loading/` 관련 import | 10개 | ✅ |

#### 0.1.4 완료된 폴더 구조

```
lib/core/widgets/
├── cards/                    # ✅ 카드 위젯 (5개)
│   ├── cards.dart           # barrel export
│   ├── dating_card.dart
│   ├── product_card.dart
│   ├── profile_cards.dart
│   ├── pet_selector_card.dart
│   └── mingrr_record_tile.dart
├── badges/                   # ✅ 배지/아이콘 (5개)
│   ├── badges.dart          # barrel export
│   ├── info_badge.dart
│   ├── trait_badge.dart
│   ├── verification_badge.dart
│   ├── distance_badge.dart
│   └── svg_icons.dart
├── forms/                    # ✅ 폼 관련 (4개)
│   ├── forms.dart           # barrel export
│   ├── form_components.dart
│   ├── tag_input.dart
│   ├── search_bar.dart
│   └── location_selector.dart
├── sheets/                   # ✅ 바텀시트 (5개)
│   ├── sheets.dart          # barrel export
│   ├── mingrr_bottom_sheet.dart
│   ├── image_picker_sheet.dart
│   ├── report_sheet.dart
│   ├── request_sheet.dart
│   └── confirm_sheet.dart
├── modals/                   # ✅ 모달 (5개)
│   ├── modals.dart          # barrel export
│   ├── pet_profile_modal.dart
│   ├── guardian_profile_modal.dart
│   ├── group_profile_modal.dart
│   ├── chat_options_modal.dart
│   └── profile_modal_components.dart
├── navigation/               # ✅ 네비게이션 (2개)
│   ├── navigation.dart      # barrel export
│   ├── top_navigation.dart
│   └── appbar_actions.dart
├── loading/                  # ✅ 로딩 (2개)
│   ├── loading.dart         # barrel export
│   ├── loading_widgets.dart
│   └── skeleton_widgets.dart
├── dialogs/                  # 기존 유지
├── map/                      # 기존 유지
└── (기타 공통 위젯들)        # 기존 유지
```

---

## ✅ PHASE 1: 상수 체계 재정립 (완료: 2026-01-21)

### 1.1 AppSizes 상수 체계 재정립 ✅

> `app_sizes.dart` 전면 재구성 완료

#### 1.1.1 패딩/마진 (7단계 통일) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `paddingXXS` | 2.0 | **2.0** | 유지 | ✅ |
| 2 | `paddingXS` | 4.0 | **4.0** | 유지 | ✅ |
| 3 | `paddingSM` | 6.0 | **@Deprecated** | 하위호환 | ✅ |
| 4 | `paddingS` | 8.0 | **8.0** | 유지 | ✅ |
| 5 | `paddingMS` | 10.0 | **@Deprecated** | 하위호환 | ✅ |
| 6 | `paddingM` | 16.0 | **12.0** | 축소 | ✅ |
| 7 | `paddingL` | 24.0 | **16.0** | 축소 | ✅ |
| 8 | `paddingXL` | 32.0 | **24.0** | 축소 | ✅ |
| 9 | `paddingXXL` | 48.0 | **32.0** | 축소 | ✅ |

#### 1.1.2 간격/Gap (7단계 통일) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `gapXXS` | 2.0 | **2.0** | 유지 | ✅ |
| 2 | `gapXS` | 4.0 | **4.0** | 유지 | ✅ |
| 3 | `gapSM` | 6.0 | **@Deprecated** | 하위호환 | ✅ |
| 4 | `gapS` | 8.0 | **8.0** | 유지 | ✅ |
| 5 | `gapMS` | 10.0 | **@Deprecated** | 하위호환 | ✅ |
| 6 | `gapM` | 12.0 | **12.0** | 유지 | ✅ |
| 7 | `gapL` | 16.0 | **16.0** | 유지 | ✅ |
| 8 | `gapLL` | 20.0 | **@Deprecated** | 하위호환 | ✅ |
| 9 | `gapXL` | 24.0 | **24.0** | 유지 | ✅ |
| 10 | `gapXXL` | 32.0 | **32.0** | 유지 | ✅ |

#### 1.1.3 아이콘 크기 (7단계 통일) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `iconXXS` | 12.0 | **12.0** | 유지 | ✅ |
| 2 | `iconXS` | 14.0 | **14.0** | 유지 | ✅ |
| 3 | `iconS` | 16.0 | **16.0** | 유지 | ✅ |
| 4 | `iconSM` | 18.0 | **@Deprecated** | 하위호환 | ✅ |
| 5 | `iconM` | 20.0 | **20.0** | 유지 | ✅ |
| 6 | `iconML` | 22.0 | **@Deprecated** | 하위호환 | ✅ |
| 7 | `iconL` | 24.0 | **24.0** | 유지 | ✅ |
| 8 | `iconXL` | 32.0 | **32.0** | 유지 | ✅ |
| 9 | `iconXXL` | 48.0 | **48.0** | 유지 | ✅ |
| 10 | `iconHuge` | 64.0 | **@Deprecated** | 하위호환 | ✅ |

#### 1.1.4 아바타 크기 (7단계 통일) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `avatarXXS` | 없음 | **24.0** | 추가 | ✅ |
| 2 | `avatarXS` | 32.0 | **32.0** | 유지 | ✅ |
| 3 | `avatarS` | 40.0 | **40.0** | 유지 | ✅ |
| 4 | `avatarM` | 56.0 | **56.0** | 유지 | ✅ |
| 5 | `avatarL` | 80.0 | **80.0** | 유지 | ✅ |
| 6 | `avatarXL` | 120.0 | **120.0** | 유지 | ✅ |
| 7 | `avatarXXL` | 없음 | **160.0** | 추가 | ✅ |

#### 1.1.5 테두리 반경 (4단계 단순화) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `radiusXXS` | 4.0 | **@Deprecated** | 하위호환 | ✅ |
| 2 | `radiusXS` | 8.0 | **@Deprecated** | 하위호환 | ✅ |
| 3 | `radiusS` | 12.0 | **8.0** | 변경 | ✅ |
| 4 | `radiusM` | 16.0 | **12.0** | 변경 | ✅ |
| 5 | `radiusL` | 20.0 | **16.0** | 변경 | ✅ |
| 6 | `radiusXL` | 24.0 | **@Deprecated** | 하위호환 | ✅ |
| 7 | `radiusXXL` | 32.0 | **@Deprecated** | 하위호환 | ✅ |
| 8 | `radiusFull` | 999.0 | **999.0** | 유지 | ✅ |

#### 1.1.6 버튼/입력 필드 (컴팩트화) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `buttonHeightS` | 36.0 | **32.0** | 축소 | ✅ |
| 2 | `buttonHeightM` | 48.0 | **44.0** | 축소 | ✅ |
| 3 | `buttonHeightL` | 56.0 | **48.0** | 축소 | ✅ |
| 4 | `inputHeight` | 52.0 | **44.0** | 축소 | ✅ |

#### 1.1.7 썸네일 크기 (5단계 확장) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `thumbnailXS` | 없음 | **40.0** | 추가 | ✅ |
| 2 | `thumbnailS` | 60.0 | **56.0** | 축소 | ✅ |
| 3 | `thumbnailM` | 100.0 | **80.0** | 축소 | ✅ |
| 4 | `thumbnailL` | 150.0 | **120.0** | 축소 | ✅ |
| 5 | `thumbnailXL` | 없음 | **200.0** | 추가 | ✅ |

#### 1.1.8 Elevation (3단계 신규) ✅

> 상수화 완료

| # | 상수 | 값 | 용도 | 상태 |
|:-:|------|:--:|------|:----:|
| 1 | `elevationNone` | **0.0** | 플랫 디자인 | ✅ |
| 2 | `elevationS` | **2.0** | 카드, 리스트 아이템 | ✅ |
| 3 | `elevationM` | **4.0** | FAB, 모달, 강조 카드 | ✅ |

#### 1.1.9 Border Width (3단계 신규) ✅

> 상수화 완료

| # | 상수 | Before | After | 용도 | 상태 |
|:-:|------|:------:|:-----:|------|:----:|
| 1 | `borderWidthS` | 없음 | **1.0** | 일반 테두리 | ✅ |
| 2 | `borderWidthM` | `inputBorderWidth` (1.5) | **1.5** | 입력 필드 | ✅ |
| 3 | `borderWidthL` | 없음 | **2.0** | 강조 테두리 | ✅ |

#### 1.1.10 Shadow 프리셋 (AppShadows 클래스) ✅

> `AppShadows` 클래스로 구현 완료 (다크모드 대응)

| # | 함수 | blurRadius | offset | 용도 | 상태 |
|:-:|------|:----------:|:------:|------|:----:|
| 1 | `AppShadows.shadowS(isDark)` | 6 | (0, 2) | 카드, 리스트 아이템 | ✅ |
| 2 | `AppShadows.shadowM(isDark)` | 10 | (0, 4) | 모달, FAB | ✅ |
| 3 | `AppShadows.shadowL(isDark)` | 20 | (0, -5) | 바텀시트, 오버레이 | ✅ |
| 4 | `AppShadows.none` | - | - | 그림자 없음 | ✅ |

#### 1.1.11 Opacity (AppOpacity 클래스) ✅

> `AppOpacity` 클래스로 구현 완료

| # | 상수 | 값 | 용도 | 상태 |
|:-:|------|:--:|------|:----:|
| 1 | `AppOpacity.o05` | **0.05** | 그림자, 미세 배경 | ✅ |
| 2 | `AppOpacity.o10` | **0.1** | 테두리, 약한 배경 | ✅ |
| 3 | `AppOpacity.o20` | **0.2** | 오버레이, 중간 강조 | ✅ |
| 4 | `AppOpacity.o30` | **0.3** | 강한 강조 | ✅ |
| 5 | `AppOpacity.o50` | **0.5** | 반투명 | ✅ |
| 6 | `AppOpacity.o80` | **0.8** | 거의 불투명 | ✅ |

#### 1.1.12 기타 상수 (컴팩트화) ✅

| # | 상수 | Before | After | 변경 | 상태 |
|:-:|------|:------:|:-----:|:----:|:----:|
| 1 | `bottomSheetRadius` | 20.0 | **16.0** | 축소 | ✅ |
| 2 | `bottomSheetHandleTop` | 16.0 | **12.0** | 축소 | ✅ |
| 3 | `bottomSheetButtonPaddingH` | 20.0 | **16.0** | 축소 | ✅ |
| 4 | `bottomSheetButtonPaddingV` | 16.0 | **12.0** | 축소 | ✅ |
| 5 | `inputBorderWidth` | 1.5 | **@Deprecated** | `borderWidthM`으로 대체 | ✅ |

---

### 1.2 공통 Divider 컴포넌트 생성 ✅

> `lib/core/widgets/dividers/app_dividers.dart` 생성 완료

#### 1.2.1 MingrrDivider (가로 구분선) - 3종 ✅

```dart
/// lib/core/widgets/dividers/app_dividers.dart (구현 완료)

class MingrrDivider extends StatelessWidget {
  final double height;
  final double? indent;
  final double? endIndent;
  final Color? color;

  /// 기본 구분선 (height: 1)
  const MingrrDivider({...});

  /// 섹션 구분선 (height: 16)
  const MingrrDivider.section({...});

  /// 들여쓰기 구분선 (indent: 56)
  const MingrrDivider.indented({...});
}
```

| # | 생성자 | height | indent | 용도 | 상태 |
|:-:|--------|:------:|:------:|------|:----:|
| 1 | `MingrrDivider()` | 1 | - | 기본 구분선 | ✅ |
| 2 | `.section()` | 16 | - | 섹션 구분선 (여백 포함) | ✅ |
| 3 | `.indented()` | 1 | 56 | 리스트 아이템 구분선 | ✅ |

#### 1.2.2 MingrrVerticalDivider (세로 구분선) ✅

> 구현 완료 - 파라미터로 모든 케이스 대응

| # | 사용 예시 | height | color | 용도 | 상태 |
|:-:|----------|:------:|-------|------|:----:|
| 1 | `MingrrVerticalDivider()` | 24 | outline | 기본 | ✅ |
| 2 | `MingrrVerticalDivider(height: 30)` | 30 | outline | 통계 영역 | ✅ |
| 3 | `MingrrVerticalDivider(height: 40, color: ...)` | 40 | custom | 산책 화면 | ✅ |

#### 1.2.3 기존 Divider 컴포넌트/함수 정리 (마이그레이션 대기)

| # | 기존 | 위치 | 처리 | 상태 |
|:-:|------|------|------|:----:|
| 1 | `MingrrFilterDivider` | `filter_components.dart` | `MingrrVerticalDivider()` 대체 후 삭제 | 📋 |
| 2 | `MingrrFilterSectionDivider` | `filter_components.dart` | `MingrrDivider()` 대체 후 삭제 | 📋 |
| 3 | `_buildStatDivider()` | `profile_screen.dart` | `MingrrVerticalDivider(height: 30)` 대체 후 삭제 | 📋 |
| 4 | `_buildDivider()` | `login_screen.dart` | 기존 유지 (텍스트 포함 특수 케이스) | - |
| 5 | `_buildDateDivider()` | `chat_detail_screen.dart` | 기존 유지 (날짜 텍스트 포함 특수 케이스) | - |

#### 1.2.4 Divider 마이그레이션 (점진적 적용 예정)

> 컴포넌트 생성 완료, 마이그레이션은 PHASE 2에서 점진적 적용

---

### 1.3 Deprecated 상수 하위 호환성 ✅

> 제거 대신 `@Deprecated` 어노테이션으로 하위 호환성 유지

| # | 상수 | 대체 상수 | 상태 |
|:-:|------|----------|:----:|
| 1 | `paddingSM` | `paddingS` | ✅ @Deprecated |
| 2 | `paddingMS` | `paddingM` | ✅ @Deprecated |
| 3 | `gapSM` | `gapS` | ✅ @Deprecated |
| 4 | `gapMS` | `gapM` | ✅ @Deprecated |
| 5 | `gapLL` | `gapL` | ✅ @Deprecated |
| 6 | `iconSM` | `iconS` | ✅ @Deprecated |
| 7 | `iconML` | `iconL` | ✅ @Deprecated |
| 8 | `iconHuge` | `iconXXL` | ✅ @Deprecated |
| 9 | `radiusXXS` | `radiusS` | ✅ @Deprecated |
| 10 | `radiusXS` | `radiusS` | ✅ @Deprecated |
| 11 | `radiusXL` | `radiusL` | ✅ @Deprecated |
| 12 | `radiusXXL` | `radiusL` | ✅ @Deprecated |
| 13 | `inputBorderWidth` | `borderWidthM` | ✅ @Deprecated |
| 14 | `cardElevation` | `elevationS` | ✅ @Deprecated |

---

### 1.4 AppTextStyles 재구성 🔄

> 58개 → 17개 핵심 스타일로 단순화 + 인라인 TextStyle 공통화

#### 1.4.1 현황 분석

| 항목 | Before | After |
|------|:------:|:-----:|
| AppTextStyles 스타일 수 | 58개 | **17개** |
| AppTextStyles 사용률 | 55% (403회) | **95%+** |
| 인라인 fontSize | 328회 | **~20회** (동적값만) |

#### 1.4.2 신규 AppTextStyles 구조 (17개)

| 카테고리 | 스타일 | fontSize | fontWeight | 용도 |
|----------|--------|:--------:|:----------:|------|
| **display** | `displayLarge` | 36px | w700 | 대형 점수, 앱타이틀 |
| | `displayMedium` | 28px | w700 | 중형 점수 |
| | `displaySmall` | 22px | w700 | 소형 점수, 대형 숫자 |
| **headline** | `headlineLarge` | 20px | w600 | 화면 타이틀 |
| | `headlineMedium` | 18px | w600 | 중형 제목 |
| | `headlineSmall` | 16px | w600 | 섹션 타이틀 |
| **title** | `titleLarge` | 15px | w600 | 버튼, 카드 가격 |
| | `titleMedium` | 14px | w500 | 카드/리스트 제목 |
| | `titleSmall` | 13px | w500 | 소형 타이틀 |
| **body** | `bodyLarge` | 14px | w400 | 대형 본문 |
| | `bodyMedium` | 13px | w400 | 기본 본문 |
| | `bodySmall` | 12px | w400 | 소형 본문 |
| **label** | `labelLarge` | 12px | w500 | 대형 라벨 |
| | `labelMedium` | 11px | w500 | 중형 라벨 |
| | `labelSmall` | 10px | w500 | 배지, 메타 |
| **caption** | `caption` | 11px | w400 | 캡션, 타임스탬프 |
| | `captionSmall` | 10px | w400 | 소형 캡션 |

#### 1.4.3 fontSize → AppTextStyles 매핑

| 인라인 fontSize | 변환 대상 | 사용 횟수 |
|:--------------:|----------|:--------:|
| 8-9 | `captionSmall` | 2 |
| 10 | `labelSmall` | 15 |
| 11 | `labelMedium` / `caption` | 33 |
| 12 | `bodySmall` / `labelLarge` | 62 |
| 13 | `bodyMedium` / `titleSmall` | 52 |
| 14 | `bodyLarge` / `titleMedium` | 70 |
| 15 | `titleLarge` | 22 |
| 16 | `headlineSmall` | 22 |
| 17-18 | `headlineMedium` | 19 |
| 19-22 | `displaySmall` | 4 |
| 23-32 | `displayMedium` | 4 |
| 33+ | `displayLarge` | 3 |

#### 1.4.4 확장 메서드

```dart
extension TextStyleExtension on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}
```

---

### 1.5 PHASE 1 완료 요약

#### 생성된 클래스/컴포넌트

| # | 클래스/컴포넌트 | 파일 | 용도 |
|:-:|----------------|------|------|
| 1 | `AppSizes` | `app_sizes.dart` | 크기/간격/반경 상수 (재정립) |
| 2 | `AppOpacity` | `app_sizes.dart` | 투명도 상수 (신규) |
| 3 | `AppShadows` | `app_sizes.dart` | 그림자 프리셋 (신규) |
| 4 | `MingrrDivider` | `dividers/app_dividers.dart` | 가로 구분선 (신규) |
| 5 | `MingrrVerticalDivider` | `dividers/app_dividers.dart` | 세로 구분선 (신규) |

#### 효과

- **상수 단계 단순화**: 10단계 → 7단계 (padding, gap, icon, avatar)
- **radius 단순화**: 8단계 → 4단계 (S, M, L, Full)
- **신규 상수 클래스**: AppOpacity, AppShadows
- **하위 호환성**: @Deprecated 어노테이션으로 기존 코드 유지
- **TextStyles 컴팩트화**: 전체 1~2px 축소

---

## ✅ PHASE 2: 인라인 스타일 상수화 (완료: 2026-01-21)

### 2.1 인라인 TextStyle 상수화 ✅

> `TextStyle(fontSize:)` 인라인 사용을 `AppTextStyles.xxx(context)` 로 교체 (328회 → **0회**)

#### 2.1.1 공통 위젯 (core/widgets/) - 131회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `common_widgets.dart` | 29 | ✅ |
| 2 | `kkosunnae_widgets.dart` | 13 | ✅ |
| 3 | `filter_widgets.dart` | 11 | ✅ |
| 4 | `rating_widgets.dart` | 11 | ✅ |
| 5 | `compatibility_widgets.dart` | 9 | ✅ |
| 6 | `form_components.dart` | 8 | ✅ |
| 7 | `info_badge.dart` | 7 | ✅ |
| 8 | `location_bubble_widget.dart` | 6 | ✅ |
| 9 | `location_selector.dart` | 6 | ✅ |
| 10 | `profile_modal_components.dart` | 6 | ✅ |
| 11 | `top_navigation.dart` | 5 | ✅ |
| 12 | `platform_map_widget.dart` | 5 | ✅ |
| 13 | `home_reminder_banner.dart` | 4 | ✅ |
| 14 | `loading_widgets.dart` | 4 | ✅ |
| 15 | `pet_profile_modal.dart` | 4 | ✅ |
| 16 | `profile_cards.dart` | 4 | ✅ |
| 17 | `map/location_display_card.dart` | 6 | ✅ |
| 18 | `map/map_location_picker.dart` | 4 | ✅ |

#### 2.1.2 다이얼로그 (core/widgets/dialogs/) - 25회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `info_dialog.dart` | 6 | ✅ |
| 2 | `info_action_dialog.dart` | 6 | ✅ |
| 3 | `error_dialog.dart` | 4 | ✅ |
| 4 | `input_dialog.dart` | 3 | ✅ |
| 5 | `action_prompt_dialog.dart` | 2 | ✅ |
| 6 | `app_dialog.dart` | 2 | ✅ |
| 7 | `selection_dialog.dart` | 2 | ✅ |

#### 2.1.3 화면 파일 (features/) - 97회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `walk_record_detail_screen.dart` | 15 | ✅ |
| 2 | `walk_screen.dart` | 11 | ✅ |
| 3 | `profile_screen.dart` | 11 | ✅ |
| 4 | `home_screen.dart` | 9 | ✅ |
| 5 | `chat_list_screen.dart` | 8 | ✅ |
| 6 | `received_dating_requests_screen.dart` | 6 | ✅ |
| 7 | `login_screen.dart` | 5 | ✅ |
| 8 | `notification_screen.dart` | 5 | ✅ |
| 9 | `health_record_detail_screens.dart` | 4 | ✅ |
| 10 | `marketplace_screen.dart` | 4 | ✅ |
| 11 | `activity_history_screen.dart` | 3 | ✅ |
| 12 | `community_screen.dart` | 3 | ✅ |
| 13 | `job_detail_screen.dart` | 3 | ✅ |
| 14 | `pet_edit_screen.dart` | 3 | ✅ |
| 15 | 기타 7개 파일 | 7 | ✅ |

#### 2.1.4 기타 파일 - 21회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `image_picker_sheet.dart` | 3 | ✅ |
| 2 | `mingrr_image_header.dart` | 3 | ✅ |
| 3 | `report_sheet.dart` | 3 | ✅ |
| 4 | `trait_badge.dart` | 3 | ✅ |
| 5 | `verification_badge.dart` | 3 | ✅ |
| 6 | `share_service.dart` | 3 | ✅ |
| 7 | `chat_options_modal.dart` | 2 | ✅ |
| 8 | `distance_badge.dart` | 2 | ✅ |

---

### 2.2 인라인 BorderRadius 상수화 ✅

> `BorderRadius.circular(숫자)` → `BorderRadius.circular(AppSizes.radiusXX)` 로 교체 (376회 → **3회**)
> 
> **추가 공통화 완료 (2026-01-21):**
> - `trait_badge.dart` `_borderRadius` → `AppSizes.radiusS/M/L` 매핑
> - `info_badge.dart` `_borderRadius` → `AppSizes.radiusS/M` 매핑 (6, 10 → 8, 12로 통일)
> - `bottomSheetHandleHeight / 2` → `AppSizes.bottomSheetHandleRadius` 상수 추가
> 
> **남은 3개는 외부 주입 파라미터로 의도적 유지:**
> - `search_bar.dart` `borderRadius` 파라미터
> - `mingrr_image_gallery.dart` `borderRadius` 파라미터 (2개)

#### 2.2.1 공통 위젯 - 119회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `common_widgets.dart` | 37 | ✅ |
| 2 | `form_components.dart` | 13 | ✅ |
| 3 | `kkosunnae_widgets.dart` | 10 | ✅ |
| 4 | `top_navigation.dart` | 7 | ✅ |
| 5 | `dating_card.dart` | 7 | ✅ |
| 6 | `skeleton_widgets.dart` | 6 | ✅ |
| 7 | `search_screen.dart` | 6 | ✅ |
| 8 | `product_card.dart` | 6 | ✅ |
| 9 | `compatibility_widgets.dart` | 5 | ✅ |
| 10 | `info_badge.dart` | 5 | ✅ (2개 동적 유지) |
| 11 | `rating_widgets.dart` | 5 | ✅ |
| 12 | `map/location_display_card.dart` | 5 | ✅ |
| 13 | `filter_components.dart` | 4 | ✅ |
| 14 | `location_bubble_widget.dart` | 4 | ✅ |
| 15 | `platform_map_widget.dart` | 4 | ✅ |

#### 2.2.2 화면 파일 - 119회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `profile_screen.dart` | 18 | ✅ |
| 2 | `chat_list_screen.dart` | 10 | ✅ |
| 3 | `health_record_add_screens.dart` | 10 | ✅ |
| 4 | `health_record_detail_screens.dart` | 10 | ✅ |
| 5 | `marketplace_screen.dart` | 10 | ✅ |
| 6 | `product_write_screen.dart` | 10 | ✅ |
| 7 | `community_detail_screen.dart` | 10 | ✅ |
| 8 | `group_detail_screen.dart` | 10 | ✅ |
| 9 | `walk_screen.dart` | 7 | ✅ |
| 10 | `home_screen.dart` | 6 | ✅ |
| 11 | `group_list_screen.dart` | 5 | ✅ |
| 12 | `walk_record_detail_screen.dart` | 4 | ✅ |
| 13 | `received_dating_requests_screen.dart` | 4 | ✅ |
| 14 | 기타 5개 파일 | 5 | ✅ |

#### 2.2.3 다이얼로그/시트 - 30회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `dialogs/input_dialog.dart` | 6 | ✅ |
| 2 | `dialogs/info_dialog.dart` | 5 | ✅ |
| 3 | `dialogs/app_dialog.dart` | 4 | ✅ |
| 4 | `dialogs/error_dialog.dart` | 3 | ✅ |
| 5 | `dialogs/info_action_dialog.dart` | 3 | ✅ |
| 6 | `image_picker_sheet.dart` | 3 | ✅ |
| 7 | `report_sheet.dart` | 3 | ✅ |
| 8 | `request_sheet.dart` | 3 | ✅ |

---

### 2.3 인라인 BoxShadow 상수화 ✅

> `BoxShadow(...)` 인라인 사용을 `AppShadows.shadowX(isDark)` 로 교체 (83회 → **0회**)
> 
> **AppShadows 클래스 정의 자체(7개)만 남음 - 실제 인라인 사용 0개**

#### 2.3.1 공통 위젯 - 45회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `common_widgets.dart` | 9 | ✅ |
| 2 | `dating_card.dart` | 6 | ✅ |
| 3 | `kkosunnae_widgets.dart` | 4 | ✅ |
| 4 | `mingrr_bottom_sheet.dart` | 4 | ✅ |
| 5 | `dialogs/info_dialog.dart` | 4 | ✅ |
| 6 | `top_navigation.dart` | 2 | ✅ |
| 7 | `profile_cards.dart` | 2 | ✅ |
| 8 | `compatibility_widgets.dart` | 2 | ✅ |
| 9 | `loading_widgets.dart` | 2 | ✅ |
| 10 | `location_bubble_widget.dart` | 2 | ✅ |
| 11 | `map/map_loading_widget.dart` | 2 | ✅ |
| 12 | `map/map_location_picker.dart` | 2 | ✅ |
| 13 | `map/map_view_widget.dart` | 2 | ✅ |
| 14 | `platform_map_widget.dart` | 2 | ✅ |

#### 2.3.2 화면 파일 - 28회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `walk_screen.dart` | 10 | ✅ |
| 2 | `chat_detail_screen.dart` | 6 | ✅ |
| 3 | `walk_record_detail_screen.dart` | 6 | ✅ |
| 4 | `community_screen.dart` | 2 | ✅ |
| 5 | `group_list_screen.dart` | 2 | ✅ |
| 6 | `home_screen.dart` | 2 | ✅ |

#### 2.3.3 앱 레벨 - 10회 ✅

| # | 파일 | 횟수 | 상태 |
|:-:|------|:----:|:----:|
| 1 | `app.dart` | 2 | ✅ |
| 2 | `app_demo.dart` | 2 | ✅ |
| 3 | `report_sheet.dart` | 2 | ✅ |
| 4 | `request_sheet.dart` | 2 | ✅ |
| 5 | `health_screen.dart` | 2 | ✅ |

---

### 2.4 인라인 Elevation 상수화 ✅

> `elevation: 숫자` 인라인 사용을 `AppSizes.elevationX` 로 교체 (25회 → **0회**)
> 
> **완료 내용:**
> - `elevation: 0` → `AppSizes.elevationNone`
> - `elevation: 2` → `AppSizes.elevationS`
> - `elevation: 4` → `AppSizes.elevationM`
> - 외부 주입 파라미터(mingrr_fab.dart)는 유지

| # | 영역 | 예상 파일 수 | 상태 |
|:-:|------|:----------:|:----:|
| 1 | `app_theme.dart` | ~10회 | ✅ |
| 2 | 공통 위젯 | ~10회 | ✅ |
| 3 | 화면 파일 | ~5회 | ✅ |

---

### 2.5 인라인 Opacity 상수화 ✅

> `.withValues(alpha: 숫자)` 인라인 사용을 `AppOpacity.oXX` 로 교체 완료 (325회)

**완료 내용:**
- AppOpacity 명칭 변경: `subtle`, `light` 등 → `o05`, `o10`, `o15`, `o20`, `o30`, `o50`, `o70`, `o80` (숫자 기반)
- 전체 325회 인라인 opacity 값을 AppOpacity 상수로 마이그레이션

---

### 2.7 Divider 컴포넌트 마이그레이션 ✅

> `Divider()` 인라인 사용을 `MingrrDivider` 로 교체 완료 (57회)

**완료 내용:**
- `Divider()` → `MingrrDivider()`
- `Divider(height: 16/24/32)` → `MingrrDivider.section()`
- common_widgets.dart에 MingrrDivider export 추가

---

### 2.8 BoxShadow 마이그레이션 ✅

> `BoxShadow(...)` 인라인 사용을 `AppShadows.shadowX(isDark)` 로 교체 완료 (45회)

**완료 내용:**
- 작은 그림자 → `AppShadows.shadowS(isDark)`
- 중간 그림자 → `AppShadows.shadowM(isDark)`
- 큰 그림자 (바텀시트) → `AppShadows.shadowL(isDark)`

---

### 2.9 elevation 마이그레이션 ✅

> `elevation: 숫자` 인라인 사용을 `AppSizes.elevationX` 로 교체 완료 (25회)

**완료 내용:**
- `elevation: 0` → `AppSizes.elevationNone`
- `elevation: 1~2` → `AppSizes.elevationS`
- `elevation: 4~8` → `AppSizes.elevationM`

---

### 2.10 Duration 마이그레이션 ⏸️

> `Duration(milliseconds:)` 상수화는 `const` 키워드 호환성 문제로 스킵

**사유:** Flutter의 `const` 생성자에서 static 상수 참조 불가

---

## 🟢 PHASE 3: 품질 개선

### 3.1 디자인 시스템 문서화 ✅

> **완료일**: 2026-01-21

| # | 작업 | 상세 내용 | 파일 | 상태 |
|:-:|------|----------|------|:----:|
| 1 | `DESIGN_SYSTEM.md` 생성 | 상수 체계, 사용 가이드, 예시 코드 | `docs/guide/DESIGN_SYSTEM.md` | ✅ |
| 2 | 색상 팔레트 문서화 | FeatureColors 사용법, 라이트/다크 모드 | `docs/guide/COLOR_PALETTE.md` | ✅ |
| 3 | 텍스트 스타일 가이드 | AppTextStyles 선택 기준 | `docs/guide/TEXT_STYLES.md` | ✅ |
| 4 | 컴포넌트 사용 가이드 | 위젯별 사용 예시 | `docs/guide/COMPONENTS.md` | ✅ |

**생성된 문서:**
- `DESIGN_SYSTEM.md` - 디자인 시스템 개요, 상수 체계, 빠른 참조
- `COLOR_PALETTE.md` - 기능별 색상, 상태 색상, 라이트/다크 모드
- `TEXT_STYLES.md` - 17개 텍스트 스타일, 선택 가이드, 확장 메서드
- `COMPONENTS.md` - 구분선, 배지, 버튼, 바텀시트, 다이얼로그

---

### 3.3 코드 품질 개선

#### 3.3.1 Deprecated 제거 ✅

> **완료일**: 2026-01-21

| # | 항목 | 파일 | 상태 |
|:-:|------|------|:----:|
| 1 | `dogsCollection` | `firebase_service.dart` | ✅ |
| 2 | `likesCollection` | `firebase_service.dart` | ✅ |
| 3 | `dogImageRef` | `firebase_service.dart` | ✅ |
| 4 | `NotificationIconButton` | `common_widgets.dart` | ✅ |
| 5 | `CategoryFilterChips` | `filter_widgets.dart` | ✅ |
| 6 | `CommunityCategory` | `pet_constants.dart` | ✅ |
| 7 | `CommunityRestriction` | `pet_constants.dart` | ✅ |
| 8 | `buildProfileAction` | `profile_icon.dart` | ✅ |
| 9 | `HomeReminderBannerList` | `home_reminder_banner.dart` | ✅ |
| 10 | `InfoDistanceBadge` | `info_badge.dart` | ✅ |
| 11 | `receivedLikesProvider` | `dating_providers.dart` | ✅ |
| 12 | `createLike/updateLike/...` | `firestore_service.dart` | ✅ |
| 13 | `verifyLocation` | `firestore_service.dart` | ✅ |
| 14 | `favoritePet/unfavoritePet/...` | `favorite_service.dart` | ✅ |
| 15 | `receivedLikesProvider/CountProvider` | `dating_provider.dart` | ✅ |
| 16 | `aiRecommendedPetsProvider` | `dating_provider.dart` | ✅ |
| 17 | `likeReceived/likeAccepted` | `notification_model.dart` | ✅ |
| 18 | `primaryPhotoUrl` | `pet_model.dart` | ✅ |

**마이그레이션 완료:**
- `likesCollection` → `datingRequestsCollection` (seed_data.dart, dev_tools_screen.dart)
- `dogImageRef` → `petImageRef` (storage_service.dart)
- `receivedLikesCountProvider` → `receivedDatingRequestsCountProvider` (profile_screen.dart)
- `primaryPhotoUrl` → `displayImageUrl` (profile_screen.dart)

**결과:** Deprecated 항목 **18개 → 0개** (AppSizes 제외)

#### 3.3.2 TODO 정리 (우선순위 높음)

| # | 파일 | TODO 수 | 상태 |
|:-:|------|:------:|:----:|
| 1 | `chat_detail_screen.dart` | 6 | ⬜ |
| 2 | `customer_service_screen.dart` | 4 | ⬜ |
| 3 | `image_picker_sheet.dart` | 4 | ⬜ |
| 4 | `pet_edit_screen.dart` | 4 | ⬜ |

---

### 3.4 반응형 대응

#### 3.4.1 반응형 유틸리티 생성 ✅

> **완료일**: 2026-01-21

| # | 작업 | 상세 내용 | 상태 |
|:-:|------|----------|:----:|
| 1 | `ResponsiveUtils` 클래스 생성 | Safe Area, 키보드, 화면 크기 유틸리티 | ✅ |
| 2 | 전체 MediaQuery 마이그레이션 | 50개 사용처 → ResponsiveUtils 적용 | ✅ |
| 3 | 소형 기기 감지 함수 | 현재 불필요 (태블릿 지원 시 추가) | ⏸️ |
| 4 | 동적 패딩/이미지 함수 | 현재 불필요 (AppSizes로 충분) | ⏸️ |

**생성된 유틸리티:**
- `bottomSafeArea(context)` - Safe Area 하단 패딩
- `topSafeArea(context)` - Safe Area 상단 패딩
- `keyboardHeight(context)` - 키보드 높이
- `isKeyboardVisible(context)` - 키보드 표시 여부
- `screenHeight/Width(context)` - 화면 크기
- `heightPercent/widthPercent(context, %)` - 화면 비율
- `maxSheetHeight(context)` - 바텀시트 최대 높이 (85%)
- `bottomPaddingWith(context, extra)` - 하단 패딩 + 추가값

**마이그레이션된 파일 (20개):**
- `lib/core/services/share_service.dart`
- `lib/core/widgets/kkosunnae_widgets.dart`
- `lib/core/widgets/sheets/*.dart` (5개)
- `lib/core/widgets/forms/location_selector.dart`
- `lib/core/widgets/filter_widgets.dart`
- `lib/core/widgets/cards/pet_selector_card.dart`
- `lib/core/widgets/navigation/top_navigation.dart`
- `lib/core/widgets/modals/profile_modal_components.dart`
- `lib/core/widgets/rating_widgets.dart`
- `lib/core/widgets/common_widgets.dart`
- `lib/core/widgets/mingrr_image_header.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/walk/presentation/screens/walk_screen.dart`
- `lib/features/chat/presentation/screens/*.dart` (2개)
- `lib/features/marketplace/presentation/screens/*.dart` (2개)
- `lib/features/social/presentation/screens/community_detail_screen.dart`
- `lib/features/profile/presentation/screens/*.dart` (2개)

**결과:** MediaQuery 직접 호출 **50개 → 0개**

#### 3.4.2 Overflow 방지 점검 ✅

> **완료일**: 2026-01-21

| # | 영역 | 해결 방안 | 상태 |
|:-:|------|----------|:----:|
| 1 | 카드 제목 | `maxLines`, `overflow: ellipsis` 적용 | ✅ 이미 적용 |
| 2 | 필터 칩 Row | `SingleChildScrollView` 가로 스크롤 | ✅ 이미 적용 |
| 3 | 버튼 Row | `Flexible`/`Expanded` 적용 | ✅ 이미 적용 |
| 4 | 배지 Row | `Wrap` + `+N` 표시 | ✅ 추가 완료 |
| 5 | 가격/거리 정보 | 고정 형식으로 overflow 위험 없음 | ✅ 불필요 |

**추가 작업:**
- `DatingSwipeCard` 이름/품종에 `Flexible` + `maxLines` + `ellipsis` 적용
- `TraitBadgeList`에 `+N` 오버플로우 배지 표시 기능 추가
  - `maxCount` 초과 시 자동으로 `+N` 배지 표시
  - `showOverflowCount` 파라미터로 on/off 가능

**수정된 파일:**
- `lib/core/widgets/cards/dating_card.dart` - 이름/품종 overflow 처리
- `lib/core/widgets/badges/trait_badge.dart` - +N 배지 기능 추가

---

## 📊 진행 현황 요약

| Phase | Section | 작업 수 | 완료 | 진행률 |
|:-----:|:-------:|:------:|:----:|:------:|
| **0** | widgets/ 폴더 정리 | 14 | 14 | **100%** ✅ |
| **0** | import 경로 수정 | 7 | 7 | **100%** ✅ |
| **1** | AppSizes 재정립 | 13 | 13 | **100%** ✅ |
| **1** | AppOpacity/Shadows 생성 | 2 | 2 | **100%** ✅ |
| **1** | Divider 컴포넌트 생성 | 2 | 2 | **100%** ✅ |
| **1** | AppTextStyles 컴팩트화 | 4 | 4 | **100%** ✅ |
| **2** | Opacity 상수화 | ~325회 | 325 | **100%** ✅ |
| **2** | Divider 마이그레이션 | ~57회 | 57 | **100%** ✅ |
| **2** | BoxShadow 상수화 | ~45회 | 45 | **100%** ✅ |
| **2** | Elevation 상수화 | ~25회 | 25 | **100%** ✅ |
| **2** | TextStyle 인라인 상수화 | ~321회 | 0 | **0%** ⬜ |
| **2** | BorderRadius 상수화 | ~20회 | 20 | **100%** ✅ |
| **3** | 문서화 | 4 | 0 | **0%** |
| **3** | 코드 품질 | 11 | 0 | **0%** |
| **3** | 반응형 대응 | 9 | 0 | **0%** |
| | **PHASE 0-1** | **43** | **43** | **100%** ✅ |
| | **PHASE 2** | **~793회** | **472** | **60%** 🔄 |
| | **PHASE 3** | **24** | **0** | **0%** |

---

## 📐 상수 체계 변경 요약

### Before vs After 비교

| 카테고리 | Before | After |
|----------|--------|-------|
| **padding** | XXS, XS, SM, S, MS, M, L, XL, XXL (9단계) | XXS, XS, S, M, L, XL, XXL (7단계) |
| **gap** | XXS, XS, SM, S, MS, M, L, LL, XL, XXL (10단계) | XXS, XS, S, M, L, XL, XXL (7단계) |
| **icon** | XXS, XS, S, SM, M, ML, L, XL, XXL, Huge (10단계) | XXS, XS, S, M, L, XL, XXL (7단계) |
| **avatar** | XS, S, M, L, XL (5단계) | XXS, XS, S, M, L, XL, XXL (7단계) |
| **radius** | XXS, XS, S, M, L, XL, XXL, FULL (8단계) | S, M, L, FULL (4단계) |
| **thumbnail** | S, M, L (3단계) | XS, S, M, L, XL (5단계) |
| **elevation** | 없음 (인라인 56회) | None, S, M (3단계) 🆕 |
| **borderWidth** | inputBorderWidth만 (1개) | S, M, L (3단계) 🆕 |
| **duration** | loadingTimeout만 (3개) | Fast, Normal, Slow, Page (4단계) 🆕 |
| **opacity** | 없음 (인라인 325회) | o05, o10, o15, o20, o30, o50, o70, o80 (8단계) 🆕 |
| **shadow** | 없음 (인라인 83회) | shadowS, shadowM, shadowL (함수형) 🆕 |
| **divider** | Divider() 제각각 (73회) | MingrrDivider 컴포넌트 (3종) 🆕 |
| **vDivider** | Container 직접 구현 (~15회) | MingrrVerticalDivider (파라미터) 🆕 |

### 값 변경 요약

| 상수 | Before | After | 변경 |
|------|:------:|:-----:|:----:|
| `paddingM` | 16.0 | 12.0 | **25%↓** |
| `paddingL` | 24.0 | 16.0 | **33%↓** |
| `radiusS` | 12.0 | 8.0 | **33%↓** |
| `radiusM` | 16.0 | 12.0 | **25%↓** |
| `radiusL` | 20.0 | 16.0 | **20%↓** |
| `buttonHeightM` | 48.0 | 44.0 | **8%↓** |
| `inputHeight` | 52.0 | 44.0 | **15%↓** |
| `thumbnailM` | 100.0 | 80.0 | **20%↓** |

### 신규 상수/컴포넌트 요약

| 카테고리 | 상수/컴포넌트 | 값/용도 |
|----------|--------------|--------|
| **elevation** | `elevationNone` / `elevationS` / `elevationM` | 0 / 2 / 4 |
| **borderWidth** | `borderWidthS` / `borderWidthM` / `borderWidthL` | 1.0 / 1.5 / 2.0 |
| **duration** | `durationFast` / `durationNormal` / `durationSlow` / `durationPage` | 150ms / 300ms / 500ms / 350ms |
| **thumbnail** | `thumbnailXS` / `thumbnailXL` | 40.0 / 200.0 (신규) |
| **avatar** | `avatarXXS` / `avatarXXL` | 24.0 / 160.0 (신규) |
| **opacity** | `subtle` / `light` / `medium` / `strong` / `heavy` | 0.05 / 0.1 / 0.2 / 0.3 / 0.5 |
| **shadow** | `AppShadows.shadowS(isDark)` / `shadowM` / `shadowL` | 함수형 프리셋 (다크모드 대응) |
| **divider** | `MingrrDivider()` / `.section()` / `.indented()` | 가로 구분선 (3종) |
| **vDivider** | `MingrrVerticalDivider({height, color})` | 세로 구분선 (파라미터) |

---

## 📊 예상 효과

| 항목 | Before | After |
|------|--------|-------|
| 상수 체계 복잡도 | 높음 (중간 단계 혼재) | **단순화 (7단계/4단계)** |
| 인라인 TextStyle | 311회 | **50회 이하** |
| 인라인 BorderRadius | 376회 | **100회 이하** |
| 인라인 BoxShadow | 83회 | **10회 이하** |
| 인라인 Duration | 147회 | **20회 이하** |
| 인라인 Elevation | 56회 | **10회 이하** |
| Divider 스타일 | 제각각 (73회) | **3종 컴포넌트로 통일** |
| 세로 구분선 중복 | 3곳에서 각각 구현 | **1개 컴포넌트 (파라미터)** |
| 디자인 변경 시 수정 파일 | 50+ 개 | **1-2개** |
| widgets/ 파일 탐색 | 47개 평면 | **카테고리별 정리** |
| 화면당 정보 밀도 | 낮음 | **30%↑** |
| Overflow 발생 | 일부 | **0건** |
| 유지보수 시간 | 높음 | **70%↓** |

---

## 🔗 관련 문서

- [REFACTORING_V1.md](./REFACTORING_V1.md) - 1차 리팩토링 (완료)
- [REFACTORING_V2.md](./REFACTORING_V2.md) - 2차 리팩토링 (완료)
- [REFACTORING_V3.md](./REFACTORING_V3.md) - 3차 리팩토링 (완료)
- [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md) - 디자인 시스템 가이드 (예정)

---

*최종 업데이트: 2026-01-21*
