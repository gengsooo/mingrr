# MINGRR 공통 컴포넌트 가이드

> **버전**: 2.0  
> **최종 업데이트**: 2026-01-21  
> **작성자**: MINGRR 개발팀

---

## 📋 목차

1. [개요](#1-개요)
2. [구분선 (Dividers)](#2-구분선-dividers)
3. [배지 (Badges)](#3-배지-badges)
4. [버튼](#4-버튼)
5. [카드](#5-카드)
6. [바텀시트](#6-바텀시트)
7. [다이얼로그](#7-다이얼로그)
8. [로딩](#8-로딩)

---

## 1. 개요

### 1.1 공통 컴포넌트란?

MINGRR 공통 컴포넌트는 앱 전체에서 재사용되는 UI 위젯들입니다. 일관된 디자인과 동작을 보장합니다.

### 1.2 파일 구조

```
lib/core/widgets/
├── badges/
│   ├── info_badge.dart         # 정보 배지
│   ├── trait_badge.dart        # 특성 배지
│   ├── distance_badge.dart     # 거리 배지
│   └── verification_badge.dart # 인증 배지
├── dividers/
│   ├── dividers.dart           # export 파일
│   └── app_dividers.dart       # 구분선 컴포넌트
├── dialogs/
│   ├── dialogs.dart            # export 파일
│   ├── info_dialog.dart        # 정보 다이얼로그
│   └── confirm_dialog.dart     # 확인 다이얼로그
├── sheets/
│   ├── mingrr_bottom_sheet.dart # 바텀시트
│   └── confirm_sheet.dart       # 확인 시트
├── loading/
│   └── loading_widgets.dart    # 로딩 위젯
└── common_widgets.dart         # 기타 공통 위젯
```

---

## 2. 구분선 (Dividers)

### 2.1 MingrrDivider - 가로 구분선

```dart
import 'package:mingrr/core/widgets/dividers/dividers.dart';
```

#### 기본 구분선

```dart
MingrrDivider()
```

| 속성 | 기본값 | 설명 |
|------|:------:|------|
| `height` | 1 | 구분선 높이 |
| `indent` | null | 왼쪽 들여쓰기 |
| `endIndent` | null | 오른쪽 들여쓰기 |
| `color` | dividerColor | 색상 |

#### 섹션 구분선

섹션 간 여백이 포함된 구분선입니다.

```dart
MingrrDivider.section()
```

#### 들여쓰기 구분선

리스트 아이템용 구분선입니다 (indent: 56).

```dart
MingrrDivider.indented()
```

#### 사용 예시

```dart
Column(
  children: [
    ListTile(title: Text('항목 1')),
    MingrrDivider.indented(),
    ListTile(title: Text('항목 2')),
    MingrrDivider.section(),
    Text('새 섹션'),
  ],
)
```

### 2.2 MingrrVerticalDivider - 세로 구분선

```dart
MingrrVerticalDivider()
MingrrVerticalDivider(height: 30)
MingrrVerticalDivider(height: 40, color: Colors.white30)
```

| 속성 | 기본값 | 설명 |
|------|:------:|------|
| `width` | 1 | 구분선 너비 |
| `height` | 24 | 구분선 높이 |
| `color` | outline (30%) | 색상 |

---

## 3. 배지 (Badges)

### 3.1 InfoBadge - 정보 배지

범용 정보 표시 배지입니다.

```dart
import 'package:mingrr/core/widgets/badges/info_badge.dart';

InfoBadge(
  text: '새로운',
  icon: Icons.star,
  size: InfoBadgeSize.medium,
)
```

#### 크기 옵션

| 크기 | 폰트 | 패딩 | 용도 |
|------|:----:|:----:|------|
| `small` | 10px | 6x2 | 작은 태그 |
| `medium` | 12px | 8x4 | 일반 배지 |
| `large` | 14px | 8x4 | 큰 배지 |

#### 커스터마이징

```dart
InfoBadge(
  text: '인기',
  icon: Icons.local_fire_department,
  backgroundColor: Colors.red.shade100,
  textColor: Colors.red,
  iconColor: Colors.red,
  size: InfoBadgeSize.small,
)
```

### 3.2 TraitBadge - 특성 배지

반려동물 특성을 표시하는 배지입니다.

```dart
import 'package:mingrr/core/widgets/badges/trait_badge.dart';

TraitBadge(
  trait: '활발함',
  size: TraitBadgeSize.medium,
)
```

#### 특성 배지 목록

```dart
TraitBadgeList(
  traits: ['활발함', '친화적', '장난꾸러기'],
  size: TraitBadgeSize.small,
)
```

### 3.3 DistanceBadge - 거리 배지

거리 정보를 표시하는 배지입니다.

```dart
import 'package:mingrr/core/widgets/badges/distance_badge.dart';

DistanceBadge(
  distance: 500,  // 미터 단위
  size: DistanceBadgeSize.medium,
)
```

### 3.4 VerificationBadge - 인증 배지

인증 상태를 표시하는 배지입니다.

```dart
import 'package:mingrr/core/widgets/badges/verification_badge.dart';

VerificationBadge(
  type: VerificationBadgeType.identity,
  isVerified: true,
)
```

#### 인증 타입

| 타입 | 설명 |
|------|------|
| `identity` | 본인인증 |
| `pet` | 동물등록 |
| `location` | 위치인증 |

---

## 4. 버튼

### 4.1 MingrrButton - 공통 버튼

```dart
import 'package:mingrr/core/widgets/common_widgets.dart';

MingrrButton(
  text: '확인',
  onPressed: () {},
)
```

#### 버튼 스타일

```dart
// 주요 버튼 (filled)
MingrrButton(
  text: '확인',
  onPressed: () {},
)

// 보조 버튼 (outlined)
MingrrButton.outlined(
  text: '취소',
  onPressed: () {},
)

// 텍스트 버튼
MingrrButton.text(
  text: '건너뛰기',
  onPressed: () {},
)
```

#### 버튼 크기

| 크기 | 높이 | 용도 |
|------|:----:|------|
| `small` | 32px | 작은 버튼 |
| `medium` | 44px | 기본 버튼 |
| `large` | 48px | 큰 버튼 |

### 4.2 MingrrIconButton - 아이콘 버튼

```dart
MingrrIconButton(
  icon: Icons.favorite,
  onPressed: () {},
)
```

---

## 5. 카드

### 5.1 기본 카드 스타일

```dart
Container(
  padding: const EdgeInsets.all(AppSizes.paddingM),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    boxShadow: AppShadows.shadowS(isDark),
  ),
  child: ...,
)
```

### 5.2 카드 패턴

```dart
// 기본 카드
Card(
  elevation: AppSizes.elevationS,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
  ),
  child: Padding(
    padding: const EdgeInsets.all(AppSizes.paddingM),
    child: ...,
  ),
)
```

---

## 6. 바텀시트

### 6.1 MingrrBottomSheet

기본 바텀시트 컴포넌트입니다.

```dart
import 'package:mingrr/core/widgets/sheets/mingrr_bottom_sheet.dart';

showMingrrBottomSheet(
  context: context,
  builder: (context) => MingrrBottomSheet(
    title: '옵션 선택',
    children: [
      ListTile(title: Text('옵션 1')),
      ListTile(title: Text('옵션 2')),
    ],
  ),
);
```

### 6.2 ConfirmSheet

확인/취소 액션이 있는 바텀시트입니다.

```dart
import 'package:mingrr/core/widgets/sheets/confirm_sheet.dart';

showConfirmSheet(
  context: context,
  type: ConfirmSheetType.warning,
  title: '삭제하시겠습니까?',
  message: '이 작업은 되돌릴 수 없습니다.',
  confirmText: '삭제',
  onConfirm: () {
    // 삭제 로직
  },
);
```

#### 시트 타입

| 타입 | 색상 | 용도 |
|------|------|------|
| `info` | 블루 | 정보 안내 |
| `warning` | 앰버 | 경고 |
| `danger` | 레드 | 위험 액션 |
| `success` | 그린 | 성공 확인 |

---

## 7. 다이얼로그

### 7.1 MingrrInfoDialog

정보 표시 다이얼로그입니다.

```dart
import 'package:mingrr/core/widgets/dialogs/dialogs.dart';

showMingrrInfoDialog(
  context: context,
  title: '호환성 점수란?',
  content: '두 반려동물의 성격, 크기, 활동량 등을 분석하여...',
);
```

### 7.2 MingrrConfirmDialog

확인/취소 다이얼로그입니다.

```dart
final result = await showMingrrConfirmDialog(
  context: context,
  title: '로그아웃',
  message: '정말 로그아웃 하시겠습니까?',
  confirmText: '로그아웃',
  cancelText: '취소',
);

if (result == true) {
  // 로그아웃 처리
}
```

---

## 8. 로딩

### 8.1 MingrrLoadingIndicator

로딩 인디케이터입니다.

```dart
import 'package:mingrr/core/widgets/loading/loading_widgets.dart';

MingrrLoadingIndicator()
MingrrLoadingIndicator(size: 24)
```

### 8.2 MingrrLoadingOverlay

전체 화면 로딩 오버레이입니다.

```dart
MingrrLoadingOverlay(
  isLoading: _isLoading,
  child: YourContent(),
)
```

### 8.3 MingrrShimmer

스켈레톤 로딩 효과입니다.

```dart
MingrrShimmer(
  child: Container(
    width: 100,
    height: 100,
    color: Colors.white,
  ),
)
```

---

## 빠른 참조

### Import 문

```dart
// 구분선
import 'package:mingrr/core/widgets/dividers/dividers.dart';

// 배지
import 'package:mingrr/core/widgets/badges/info_badge.dart';
import 'package:mingrr/core/widgets/badges/trait_badge.dart';

// 바텀시트
import 'package:mingrr/core/widgets/sheets/mingrr_bottom_sheet.dart';

// 다이얼로그
import 'package:mingrr/core/widgets/dialogs/dialogs.dart';

// 로딩
import 'package:mingrr/core/widgets/loading/loading_widgets.dart';

// 공통 위젯
import 'package:mingrr/core/widgets/common_widgets.dart';
```

### 자주 사용하는 패턴

```dart
// 1. 구분선
MingrrDivider()
MingrrDivider.section()

// 2. 배지
InfoBadge(text: '새로운', icon: Icons.star)
TraitBadge(trait: '활발함')

// 3. 바텀시트
showMingrrBottomSheet(context: context, builder: ...)

// 4. 다이얼로그
showMingrrConfirmDialog(context: context, title: '확인', ...)

// 5. 로딩
MingrrLoadingIndicator()
```

---

> **참고**: 각 컴포넌트의 상세 구현은 해당 파일을 참조하세요.
