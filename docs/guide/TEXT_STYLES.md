# MINGRR 텍스트 스타일 가이드

> **버전**: 2.0  
> **최종 업데이트**: 2026-01-21  
> **작성자**: MINGRR 개발팀

---

## 📋 목차

1. [개요](#1-개요)
2. [스타일 계층](#2-스타일-계층)
3. [스타일 선택 가이드](#3-스타일-선택-가이드)
4. [확장 메서드](#4-확장-메서드)
5. [사용 예시](#5-사용-예시)
6. [FAQ](#6-faq)

---

## 1. 개요

### 1.1 AppTextStyles란?

`AppTextStyles`는 앱 전체에서 일관된 텍스트 스타일을 제공하는 유틸리티 클래스입니다.

**특징:**
- **17개 핵심 스타일**로 단순화
- **BuildContext 기반**으로 테마 색상 자동 적용
- **라이트/다크 모드** 자동 대응
- **확장 메서드**로 유연한 커스터마이징

### 1.2 기본 사용법

```dart
import 'package:mingrr/core/theme/app_text_styles.dart';

Text('제목', style: AppTextStyles.headlineSmall(context));
Text('본문', style: AppTextStyles.bodyMedium(context));
```

---

## 2. 스타일 계층

### 2.1 전체 스타일 맵

```
Display (22-36px) - 대형 숫자, 점수
├── displayLarge   : 36px, Bold
├── displayMedium  : 28px, Bold
└── displaySmall   : 22px, Bold

Headline (16-20px) - 화면/섹션 제목
├── headlineLarge  : 20px, SemiBold
├── headlineMedium : 18px, SemiBold
└── headlineSmall  : 16px, SemiBold

Title (13-15px) - 카드/리스트 제목, 버튼
├── titleLarge     : 15px, SemiBold
├── titleMedium    : 14px, Medium
└── titleSmall     : 13px, Medium

Body (12-14px) - 일반 텍스트
├── bodyLarge      : 14px, Regular
├── bodyMedium     : 13px, Regular  ← 기본 본문
└── bodySmall      : 12px, Regular

Label (10-12px) - 태그, 배지, 메타
├── labelLarge     : 12px, Medium
├── labelMedium    : 11px, Medium
└── labelSmall     : 10px, Medium

Caption (10-11px) - 보조 텍스트
├── caption        : 11px, Regular, 보조색상
└── captionSmall   : 10px, Regular, 보조색상
```

### 2.2 상세 스펙

| 스타일 | 크기 | 굵기 | 색상 | 용도 |
|--------|:----:|:----:|:----:|------|
| `displayLarge` | 36px | w700 | onSurface | 대형 점수, 앱 타이틀 |
| `displayMedium` | 28px | w700 | onSurface | 중형 점수 |
| `displaySmall` | 22px | w700 | onSurface | 소형 점수, 대형 숫자 |
| `headlineLarge` | 20px | w600 | onSurface | 화면 타이틀 |
| `headlineMedium` | 18px | w600 | onSurface | 중형 제목 |
| `headlineSmall` | 16px | w600 | onSurface | 섹션 타이틀 |
| `titleLarge` | 15px | w600 | onSurface | 버튼, 카드 가격 |
| `titleMedium` | 14px | w500 | onSurface | 카드 제목, 리스트 제목 |
| `titleSmall` | 13px | w500 | onSurface | 소형 타이틀 |
| `bodyLarge` | 14px | w400 | onSurface | 대형 본문 |
| `bodyMedium` | 13px | w400 | onSurface | **기본 본문** |
| `bodySmall` | 12px | w400 | onSurface | 소형 본문 |
| `labelLarge` | 12px | w500 | onSurface | 대형 라벨 |
| `labelMedium` | 11px | w500 | onSurface | 중형 라벨 |
| `labelSmall` | 10px | w500 | onSurface | 배지, 메타 정보 |
| `caption` | 11px | w400 | onSurfaceVariant | 캡션, 타임스탬프 |
| `captionSmall` | 10px | w400 | onSurfaceVariant | 소형 캡션 |

---

## 3. 스타일 선택 가이드

### 3.1 화면 제목

| 상황 | 권장 스타일 |
|------|------------|
| 화면 최상단 타이틀 | `headlineLarge` |
| 섹션 제목 | `headlineSmall` |
| 다이얼로그 제목 | `headlineMedium` |

```dart
// 화면 타이틀
Text('프로필', style: AppTextStyles.headlineLarge(context));

// 섹션 제목
Text('기본 정보', style: AppTextStyles.headlineSmall(context));
```

### 3.2 카드/리스트

| 상황 | 권장 스타일 |
|------|------------|
| 카드 제목 | `titleMedium` |
| 카드 가격/강조 | `titleLarge` |
| 카드 설명 | `bodyMedium` |
| 카드 메타 정보 | `caption` |

```dart
// 카드 예시
Column(
  children: [
    Text('상품명', style: AppTextStyles.titleMedium(context)),
    Text('50,000원', style: AppTextStyles.titleLarge(context)),
    Text('설명 텍스트', style: AppTextStyles.bodyMedium(context)),
    Text('3시간 전', style: AppTextStyles.caption(context)),
  ],
)
```

### 3.3 버튼

| 상황 | 권장 스타일 |
|------|------------|
| 주요 버튼 | `titleLarge` |
| 보조 버튼 | `titleMedium` |
| 작은 버튼 | `labelLarge` |

```dart
ElevatedButton(
  child: Text('확인', style: AppTextStyles.titleLarge(context).withColor(Colors.white)),
)
```

### 3.4 배지/태그

| 상황 | 권장 스타일 |
|------|------------|
| 일반 배지 | `labelSmall` |
| 강조 배지 | `labelMedium` |
| 큰 배지 | `labelLarge` |

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: Text('NEW', style: AppTextStyles.labelSmall(context).withColor(Colors.white)),
)
```

### 3.5 점수/숫자

| 상황 | 권장 스타일 |
|------|------------|
| 대형 점수 (호환성 등) | `displayLarge` |
| 중형 점수 | `displayMedium` |
| 소형 점수/숫자 | `displaySmall` |

```dart
// 호환성 점수
Text('95', style: AppTextStyles.displayLarge(context).withColor(features.dating));
```

### 3.6 보조 텍스트

| 상황 | 권장 스타일 |
|------|------------|
| 타임스탬프 | `caption` |
| 힌트 텍스트 | `caption` |
| 작은 메타 정보 | `captionSmall` |

```dart
Text('2시간 전', style: AppTextStyles.caption(context));
```

---

## 4. 확장 메서드

### 4.1 사용 가능한 확장 메서드

| 메서드 | 용도 | 예시 |
|--------|------|------|
| `.withColor(Color)` | 색상 변경 | `.withColor(Colors.red)` |
| `.withWeight(FontWeight)` | 굵기 변경 | `.withWeight(FontWeight.w600)` |
| `.withSize(double)` | 크기 변경 | `.withSize(16)` |
| `.withHeight(double)` | 줄 높이 설정 | `.withHeight(1.5)` |
| `.withUnderline()` | 밑줄 추가 | `.withUnderline()` |

### 4.2 체이닝

확장 메서드는 체이닝이 가능합니다.

```dart
Text(
  '강조 텍스트',
  style: AppTextStyles.bodyMedium(context)
      .withWeight(FontWeight.w600)
      .withColor(features.dating),
);
```

### 4.3 주의사항

```dart
// ✅ 좋은 예 - 확장 메서드 사용
style: AppTextStyles.bodyMedium(context).withColor(Colors.red)

// ❌ 나쁜 예 - copyWith 직접 사용 (가능하지만 권장하지 않음)
style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.red)

// ❌ 나쁜 예 - 인라인 TextStyle 사용
style: TextStyle(fontSize: 13, color: Colors.red)
```

---

## 5. 사용 예시

### 5.1 프로필 카드

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 이름
    Text(
      '멍이',
      style: AppTextStyles.headlineMedium(context),
    ),
    SizedBox(height: AppSizes.gapXS),
    
    // 품종/나이
    Text(
      '골든 리트리버 · 3살',
      style: AppTextStyles.bodyMedium(context)
          .withColor(colorScheme.onSurfaceVariant),
    ),
    SizedBox(height: AppSizes.gapS),
    
    // 거리
    Text(
      '500m',
      style: AppTextStyles.caption(context),
    ),
  ],
)
```

### 5.2 상품 카드

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 상품명
    Text(
      '강아지 사료 10kg',
      style: AppTextStyles.titleMedium(context),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    SizedBox(height: AppSizes.gapXS),
    
    // 가격
    Text(
      '45,000원',
      style: AppTextStyles.titleLarge(context)
          .withColor(features.market),
    ),
    SizedBox(height: AppSizes.gapXS),
    
    // 메타 정보
    Text(
      '강남구 · 3시간 전',
      style: AppTextStyles.caption(context),
    ),
  ],
)
```

### 5.3 채팅 메시지

```dart
// 메시지 내용
Text(
  message.content,
  style: AppTextStyles.bodyMedium(context),
),

// 시간
Text(
  '오후 3:42',
  style: AppTextStyles.captionSmall(context),
),
```

### 5.4 빈 상태

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.inbox, size: AppSizes.iconXXL, color: colorScheme.outline),
    SizedBox(height: AppSizes.gapM),
    Text(
      '아직 데이터가 없어요',
      style: AppTextStyles.titleMedium(context)
          .withColor(colorScheme.onSurfaceVariant),
    ),
    SizedBox(height: AppSizes.gapXS),
    Text(
      '새로운 항목을 추가해보세요',
      style: AppTextStyles.bodySmall(context)
          .withColor(colorScheme.outline),
    ),
  ],
)
```

---

## 6. FAQ

### Q1. 어떤 스타일을 선택해야 할지 모르겠어요.

**A:** 다음 순서로 결정하세요:
1. **용도 확인**: 제목? 본문? 배지?
2. **크기 확인**: 크게? 중간? 작게?
3. **기본 스타일 선택** 후 확장 메서드로 조정

### Q2. 기존 TextStyle을 사용해도 되나요?

**A:** 가능하지만 권장하지 않습니다. `AppTextStyles`를 사용하면:
- 일관된 디자인 유지
- 다크 모드 자동 대응
- 유지보수 용이

### Q3. 색상만 다른 경우 새 스타일을 만들어야 하나요?

**A:** 아니요. 확장 메서드를 사용하세요:
```dart
AppTextStyles.bodyMedium(context).withColor(customColor)
```

### Q4. const를 사용할 수 없나요?

**A:** `AppTextStyles`는 `BuildContext`를 통해 테마 색상에 접근하므로 `const`를 사용할 수 없습니다. 이는 라이트/다크 모드 자동 대응을 위한 의도적인 설계입니다.

### Q5. 폰트 패밀리를 변경하려면?

**A:** `app_theme.dart`에서 전역 폰트를 설정하세요:
```dart
ThemeData(
  fontFamily: 'Pretendard',
)
```

---

## 빠른 참조 표

| 용도 | 스타일 |
|------|--------|
| 화면 타이틀 | `headlineLarge` |
| 섹션 제목 | `headlineSmall` |
| 카드 제목 | `titleMedium` |
| 버튼 텍스트 | `titleLarge` |
| 기본 본문 | `bodyMedium` |
| 배지/태그 | `labelSmall` |
| 타임스탬프 | `caption` |
| 대형 점수 | `displayLarge` |

---

> **참고**: 스타일 정의는 `lib/core/theme/app_text_styles.dart`에서 관리됩니다.
