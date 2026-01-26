# MINGRR 디자인 시스템 가이드

> **버전**: 2.0  
> **최종 업데이트**: 2026-01-21  
> **작성자**: MINGRR 개발팀

---

## 📋 목차

1. [개요](#1-개요)
2. [상수 체계](#2-상수-체계)
3. [파일 구조](#3-파일-구조)
4. [빠른 참조](#4-빠른-참조)
5. [관련 문서](#5-관련-문서)

---

## 1. 개요

### 1.1 디자인 시스템이란?

MINGRR 디자인 시스템은 앱 전체에서 **일관된 UI/UX**를 제공하기 위한 상수, 스타일, 컴포넌트의 집합입니다.

### 1.2 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **Single Source of Truth** | 모든 스타일 값은 한 곳에서 정의 |
| **DRY (Don't Repeat Yourself)** | 중복 코드 제거 |
| **Semantic Naming** | 용도 기반 명명 (숫자 대신 의미) |
| **Theme Aware** | 라이트/다크 모드 자동 대응 |

### 1.3 주요 클래스

| 클래스 | 파일 | 용도 |
|--------|------|------|
| `AppSizes` | `app_sizes.dart` | 크기, 간격, 반경, elevation |
| `AppOpacity` | `app_sizes.dart` | 투명도 상수 (8단계) |
| `AppShadows` | `app_sizes.dart` | 그림자 프리셋 (3단계) |
| `AppTextStyles` | `app_text_styles.dart` | 텍스트 스타일 (17종) |
| `FeatureColors` | `feature_colors.dart` | 기능별 색상 (7개 기능) |
| `MingrrDivider` | `dividers.dart` | 구분선 컴포넌트 |

---

## 2. 상수 체계

### 2.1 AppSizes - 크기/간격 상수

#### 패딩/마진 (7단계)

| 상수 | 값 | 용도 |
|------|:--:|------|
| `paddingXXS` | 2px | 최소 패딩 |
| `paddingXS` | 4px | 아이콘 내부 |
| `paddingS` | 8px | 기본 패딩 |
| `paddingM` | 12px | 중간 패딩 |
| `paddingL` | 16px | 큰 패딩 |
| `paddingXL` | 24px | 섹션 패딩 |
| `paddingXXL` | 32px | 대형 패딩 |

```dart
// 사용 예시
Container(
  padding: const EdgeInsets.all(AppSizes.paddingM),
  margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
)
```

#### 간격/Gap (7단계)

| 상수 | 값 | 용도 |
|------|:--:|------|
| `gapXXS` | 2px | 최소 간격 |
| `gapXS` | 4px | 아이콘-텍스트 간격 |
| `gapS` | 8px | 기본 간격 |
| `gapM` | 12px | 중간 간격 |
| `gapL` | 16px | 큰 간격 |
| `gapXL` | 24px | 섹션 간격 |
| `gapXXL` | 32px | 대형 간격 |

```dart
// 사용 예시
Column(
  children: [
    Text('제목'),
    SizedBox(height: AppSizes.gapS),
    Text('내용'),
  ],
)
```

#### 테두리 반경 (4단계)

| 상수 | 값 | 용도 |
|------|:--:|------|
| `radiusS` | 8px | 태그, 칩, 작은 카드 |
| `radiusM` | 12px | 일반 카드, 버튼 |
| `radiusL` | 16px | 큰 카드, 바텀시트 |
| `radiusFull` | 999px | 완전 원형 |

```dart
// 사용 예시
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
  ),
)
```

#### 아이콘 크기 (7단계)

| 상수 | 값 | 용도 |
|------|:--:|------|
| `iconXXS` | 12px | 배지 내 아이콘 |
| `iconXS` | 14px | 필터 칩 아이콘 |
| `iconS` | 16px | 작은 아이콘 |
| `iconM` | 20px | 기본 아이콘 |
| `iconL` | 24px | 큰 아이콘 |
| `iconXL` | 32px | 대형 아이콘 |
| `iconXXL` | 48px | 특대 아이콘 |

#### 아바타 크기 (7단계)

| 상수 | 값 | 용도 |
|------|:--:|------|
| `avatarXXS` | 24px | 최소 아바타 |
| `avatarXS` | 32px | 채팅 리스트 |
| `avatarS` | 40px | 댓글, 리스트 |
| `avatarM` | 56px | 카드, 프로필 |
| `avatarL` | 80px | 상세 화면 |
| `avatarXL` | 120px | 프로필 편집 |
| `avatarXXL` | 160px | 대형 프로필 |

#### Elevation (3단계)

| 상수 | 값 | 용도 |
|------|:--:|------|
| `elevationNone` | 0 | 플랫 디자인 |
| `elevationS` | 2 | 카드, 리스트 아이템 |
| `elevationM` | 4 | FAB, 모달 |

---

### 2.2 AppOpacity - 투명도 상수

| 상수 | 값 | 용도 |
|------|:--:|------|
| `o05` | 5% | 그림자, 미세 배경 |
| `o10` | 10% | 테두리, 약한 배경 |
| `o15` | 15% | 약한 강조 |
| `o20` | 20% | 오버레이, 중간 강조 |
| `o30` | 30% | 강한 강조 |
| `o50` | 50% | 반투명 오버레이 |
| `o70` | 70% | 진한 오버레이 |
| `o80` | 80% | 거의 불투명 |

```dart
// 사용 예시
Container(
  color: Colors.black.withValues(alpha: AppOpacity.o50),
)

// 색상에 투명도 적용
border: Border.all(
  color: primaryColor.withValues(alpha: AppOpacity.o20),
)
```

---

### 2.3 AppShadows - 그림자 프리셋

| 메서드 | 용도 | 다크모드 대응 |
|--------|------|:------------:|
| `shadowS(isDark)` | 카드, 리스트 아이템 | ✅ |
| `shadowM(isDark)` | 모달, FAB | ✅ |
| `shadowL(isDark)` | 바텀시트, 오버레이 | ✅ |
| `none` | 그림자 없음 | - |

```dart
// 사용 예시
final isDark = Theme.of(context).brightness == Brightness.dark;

Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.shadowS(isDark),
  ),
)
```

---

### 2.4 AppTextStyles - 텍스트 스타일

#### 스타일 계층 (17종)

| 카테고리 | 스타일 | 크기 | 굵기 | 용도 |
|----------|--------|:----:|:----:|------|
| **Display** | `displayLarge` | 36px | Bold | 대형 점수, 앱 타이틀 |
| | `displayMedium` | 28px | Bold | 중형 점수 |
| | `displaySmall` | 22px | Bold | 소형 점수, 대형 숫자 |
| **Headline** | `headlineLarge` | 20px | SemiBold | 화면 타이틀 |
| | `headlineMedium` | 18px | SemiBold | 중형 제목 |
| | `headlineSmall` | 16px | SemiBold | 섹션 타이틀 |
| **Title** | `titleLarge` | 15px | SemiBold | 버튼, 카드 가격 |
| | `titleMedium` | 14px | Medium | 카드 제목, 리스트 제목 |
| | `titleSmall` | 13px | Medium | 소형 타이틀 |
| **Body** | `bodyLarge` | 14px | Regular | 대형 본문 |
| | `bodyMedium` | 13px | Regular | 기본 본문 |
| | `bodySmall` | 12px | Regular | 소형 본문 |
| **Label** | `labelLarge` | 12px | Medium | 대형 라벨 |
| | `labelMedium` | 11px | Medium | 중형 라벨 |
| | `labelSmall` | 10px | Medium | 배지, 메타 |
| **Caption** | `caption` | 11px | Regular | 캡션, 타임스탬프 |
| | `captionSmall` | 10px | Regular | 소형 캡션 |

```dart
// 기본 사용
Text('제목', style: AppTextStyles.headlineSmall(context));

// 확장 메서드 사용
Text(
  '강조 텍스트',
  style: AppTextStyles.bodyMedium(context)
      .withWeight(FontWeight.w600)
      .withColor(Colors.red),
);
```

#### 확장 메서드

| 메서드 | 용도 |
|--------|------|
| `.withColor(Color)` | 색상 변경 |
| `.withWeight(FontWeight)` | 굵기 변경 |
| `.withSize(double)` | 크기 변경 |
| `.withHeight(double)` | 줄 높이 설정 |
| `.withUnderline()` | 밑줄 추가 |

---

### 2.5 FeatureColors - 기능별 색상

#### 기능별 색상 (7개)

| 기능 | 메인 색상 | Container | 용도 |
|------|----------|-----------|------|
| `dating` | 핑크/코랄 | 연한 핑크 | 데이팅 기능 |
| `market` | 인디고 | 연한 인디고 | 마켓 기능 |
| `social` | 틸 | 연한 틸 | 소모임/커뮤니티 |
| `health` | 블루 | 연한 블루 | 건강수첩 |
| `walk` | 그린 | 연한 그린 | 산책 기능 |
| `chat` | 앰버/오렌지 | 연한 앰버 | 채팅 기능 |
| `breeding` | 퍼플 | 연한 퍼플 | 교배 기능 |

#### 상태 색상

| 상태 | 색상 | 용도 |
|------|------|------|
| `success` | 그린 | 성공, 완료 |
| `warning` | 앰버 | 경고, 주의 |
| `info` | 블루 | 정보, 안내 |

```dart
// 사용 예시
final features = Theme.of(context).extension<FeatureColors>()!;

Container(
  color: features.datingContainer,
  child: Icon(Icons.favorite, color: features.dating),
)
```

---

## 3. 파일 구조

```
lib/core/
├── constants/
│   └── app_sizes.dart          # AppSizes, AppOpacity, AppShadows
├── theme/
│   ├── app_text_styles.dart    # AppTextStyles + 확장 메서드
│   ├── app_theme.dart          # 테마 설정
│   └── feature_colors.dart     # FeatureColors (ThemeExtension)
└── widgets/
    └── dividers/
        ├── dividers.dart       # export 파일
        └── app_dividers.dart   # MingrrDivider, MingrrVerticalDivider
```

---

## 4. 빠른 참조

### 자주 사용하는 패턴

```dart
// 1. 패딩/마진
padding: const EdgeInsets.all(AppSizes.paddingM),
margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),

// 2. 간격
SizedBox(height: AppSizes.gapS),
SizedBox(width: AppSizes.gapXS),

// 3. 테두리 반경
borderRadius: BorderRadius.circular(AppSizes.radiusM),

// 4. 텍스트 스타일
style: AppTextStyles.bodyMedium(context),
style: AppTextStyles.titleLarge(context).withColor(primaryColor),

// 5. 그림자
boxShadow: AppShadows.shadowS(isDark),

// 6. 투명도
color: primaryColor.withValues(alpha: AppOpacity.o20),

// 7. 기능별 색상
final features = Theme.of(context).extension<FeatureColors>()!;
color: features.dating,

// 8. 구분선
MingrrDivider(),
MingrrDivider.section(),
```

### Import 문

```dart
// 상수
import 'package:mingrr/core/constants/app_sizes.dart';

// 텍스트 스타일
import 'package:mingrr/core/theme/app_text_styles.dart';

// 기능별 색상
import 'package:mingrr/core/theme/feature_colors.dart';

// 구분선
import 'package:mingrr/core/widgets/dividers/dividers.dart';
```

---

## 5. 관련 문서

| 문서 | 설명 |
|------|------|
| [COLOR_PALETTE.md](./COLOR_PALETTE.md) | 색상 팔레트 상세 가이드 |
| [TEXT_STYLES.md](./TEXT_STYLES.md) | 텍스트 스타일 선택 가이드 |
| [COMPONENTS.md](./COMPONENTS.md) | 공통 컴포넌트 사용 가이드 |

---

> **참고**: 이 문서는 MINGRR 디자인 시스템의 개요입니다. 각 항목의 상세 사용법은 관련 문서를 참조하세요.
