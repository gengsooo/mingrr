# MINGRR 색상 팔레트 가이드

> **버전**: 2.0  
> **최종 업데이트**: 2026-01-21  
> **작성자**: MINGRR 개발팀

---

## 📋 목차

1. [개요](#1-개요)
2. [기능별 색상 (FeatureColors)](#2-기능별-색상-featurecolors)
3. [상태 색상](#3-상태-색상)
4. [Material ColorScheme](#4-material-colorscheme)
5. [그라데이션](#5-그라데이션)
6. [라이트/다크 모드](#6-라이트다크-모드)
7. [사용 가이드](#7-사용-가이드)

---

## 1. 개요

### 1.1 색상 시스템 구조

MINGRR은 **Material 3 ColorScheme**을 기반으로 하며, **FeatureColors** ThemeExtension을 통해 기능별 색상을 확장합니다.

```
┌─────────────────────────────────────────────┐
│  Material 3 ColorScheme (기본)              │
│  - primary, secondary, surface, error 등   │
├─────────────────────────────────────────────┤
│  FeatureColors (확장)                       │
│  - dating, market, social, health 등       │
└─────────────────────────────────────────────┘
```

### 1.2 색상 접근 방법

```dart
// Material ColorScheme
final colorScheme = Theme.of(context).colorScheme;
color: colorScheme.primary;
color: colorScheme.surface;

// FeatureColors
final features = Theme.of(context).extension<FeatureColors>()!;
color: features.dating;
color: features.datingContainer;
```

---

## 2. 기능별 색상 (FeatureColors)

### 2.1 데이팅 (Dating) - 핑크/코랄

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `dating` | `#FF8A80` | `#FF8A80` | 메인 아이콘, 텍스트 |
| `datingContainer` | `#FFEBEE` | `#1E1E1E` | 배경, 카드 |
| `onDating` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

```dart
// 사용 예시
Container(
  color: features.datingContainer,
  child: Icon(Icons.favorite, color: features.dating),
)
```

### 2.2 마켓 (Market) - 인디고

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `market` | `#5C6BC0` | `#7986CB` | 메인 아이콘, 텍스트 |
| `marketContainer` | `#E8EAF6` | `#1E1E1E` | 배경, 카드 |
| `onMarket` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

### 2.3 소셜 (Social) - 틸

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `social` | `#4DB6AC` | `#4DB6AC` | 메인 아이콘, 텍스트 |
| `socialContainer` | `#E0F2F1` | `#1E1E1E` | 배경, 카드 |
| `onSocial` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

> **참고**: 소셜 색상은 소모임과 커뮤니티 게시판에서 공통으로 사용됩니다.

### 2.4 건강 (Health) - 블루

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `health` | `#64B5F6` | `#64B5F6` | 메인 아이콘, 텍스트 |
| `healthContainer` | `#E3F2FD` | `#1E1E1E` | 배경, 카드 |
| `onHealth` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

### 2.5 산책 (Walk) - 그린

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `walk` | `#81C784` | `#81C784` | 메인 아이콘, 텍스트 |
| `walkContainer` | `#E8F5E9` | `#1E1E1E` | 배경, 카드 |
| `onWalk` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

### 2.6 채팅 (Chat) - 앰버/오렌지

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `chat` | `#FF9800` | `#FFB74D` | 메인 아이콘, 텍스트 |
| `chatContainer` | `#FFF3E0` | `#1E1E1E` | 배경, 카드 |
| `onChat` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

### 2.7 교배 (Breeding) - 퍼플

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `breeding` | `#CE93D8` | `#CE93D8` | 메인 아이콘, 텍스트 |
| `breedingContainer` | `#F3E5F5` | `#1E1E1E` | 배경, 카드 |
| `onBreeding` | `#FFFFFF` | `#FFFFFF` | 버튼 내 텍스트 |

---

## 3. 상태 색상

### 3.1 성공 (Success)

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `success` | `#81C784` | `#81C784` | 성공 아이콘, 텍스트 |
| `successContainer` | `#E8F5E9` | `#1D3D1F` | 성공 배경 |

```dart
// 사용 예시
Container(
  color: features.successContainer,
  child: Icon(Icons.check_circle, color: features.success),
)
```

### 3.2 경고 (Warning)

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `warning` | `#FFB74D` | `#FFB74D` | 경고 아이콘, 텍스트 |
| `warningContainer` | `#FFF3E0` | `#5D3A1A` | 경고 배경 |

### 3.3 정보 (Info)

| 속성 | 라이트 모드 | 다크 모드 | 용도 |
|------|:-----------:|:---------:|------|
| `info` | `#64B5F6` | `#64B5F6` | 정보 아이콘, 텍스트 |
| `infoContainer` | `#E3F2FD` | `#1A3A5C` | 정보 배경 |

---

## 4. Material ColorScheme

### 4.1 주요 색상

| 속성 | 용도 |
|------|------|
| `primary` | 앱 메인 색상 (노란색/금색) |
| `onPrimary` | primary 위의 텍스트/아이콘 |
| `secondary` | 보조 색상 |
| `surface` | 카드, 시트 배경 |
| `onSurface` | surface 위의 텍스트 |
| `onSurfaceVariant` | 보조 텍스트 (회색) |
| `error` | 에러 색상 |
| `outline` | 테두리 색상 |

```dart
// 사용 예시
final colorScheme = Theme.of(context).colorScheme;

Container(
  color: colorScheme.surface,
  child: Text(
    '텍스트',
    style: TextStyle(color: colorScheme.onSurface),
  ),
)
```

---

## 5. 그라데이션

### 5.1 Warm Gradient

프로필 상단 배경에 사용되는 따뜻한 그라데이션입니다.

| 모드 | 색상 |
|------|------|
| 라이트 | `#FFFBF5` → `#FFF8E8` |
| 다크 | `#2C2C2C` → `#1E1E1E` |

```dart
Container(
  decoration: BoxDecoration(
    gradient: features.warmGradient,
  ),
)
```

### 5.2 Primary Gradient

버튼, 강조 영역에 사용되는 메인 그라데이션입니다.

| 모드 | 색상 |
|------|------|
| 라이트 | `#FFD54F` → `#FFC107` |
| 다크 | `#5D4A00` → `#3D3D00` |

```dart
Container(
  decoration: BoxDecoration(
    gradient: features.primaryGradient,
  ),
)
```

---

## 6. 라이트/다크 모드

### 6.1 자동 대응

FeatureColors는 ThemeExtension으로 구현되어 있어 라이트/다크 모드에서 자동으로 적절한 색상이 적용됩니다.

```dart
// app_theme.dart에서 설정
ThemeData(
  extensions: [FeatureColors.light],  // 라이트 모드
)

ThemeData(
  extensions: [FeatureColors.dark],   // 다크 모드
)
```

### 6.2 다크 모드 특징

- **Container 색상**: 라이트 모드에서는 연한 색상, 다크 모드에서는 `#1E1E1E` (다크 서피스)로 통일
- **메인 색상**: 대부분 동일하게 유지하여 브랜드 일관성 확보
- **그라데이션**: 다크 모드에 맞게 어두운 톤으로 조정

---

## 7. 사용 가이드

### 7.1 기본 패턴

```dart
@override
Widget build(BuildContext context) {
  // 1. FeatureColors 가져오기
  final features = Theme.of(context).extension<FeatureColors>()!;
  
  // 2. ColorScheme 가져오기
  final colorScheme = Theme.of(context).colorScheme;
  
  return Container(
    // 기능별 배경색
    color: features.datingContainer,
    child: Column(
      children: [
        // 기능별 아이콘 색상
        Icon(Icons.favorite, color: features.dating),
        
        // 기본 텍스트 색상
        Text('제목', style: TextStyle(color: colorScheme.onSurface)),
        
        // 보조 텍스트 색상
        Text('설명', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      ],
    ),
  );
}
```

### 7.2 투명도 적용

```dart
// AppOpacity 사용 권장
Container(
  color: features.dating.withValues(alpha: AppOpacity.o10),
  border: Border.all(
    color: features.dating.withValues(alpha: AppOpacity.o30),
  ),
)
```

### 7.3 화면별 색상 선택

| 화면 | 사용 색상 |
|------|----------|
| 데이팅 화면 | `features.dating` |
| 마켓 화면 | `features.market` |
| 소모임/커뮤니티 | `features.social` |
| 건강수첩 | `features.health` |
| 산책 화면 | `features.walk` |
| 채팅 화면 | `features.chat` |
| 교배 화면 | `features.breeding` |

---

## 색상 코드 빠른 참조

### 라이트 모드

| 기능 | 메인 | Container |
|------|------|-----------|
| Dating | `#FF8A80` | `#FFEBEE` |
| Market | `#5C6BC0` | `#E8EAF6` |
| Social | `#4DB6AC` | `#E0F2F1` |
| Health | `#64B5F6` | `#E3F2FD` |
| Walk | `#81C784` | `#E8F5E9` |
| Chat | `#FF9800` | `#FFF3E0` |
| Breeding | `#CE93D8` | `#F3E5F5` |

### 상태 색상

| 상태 | 색상 | Container |
|------|------|-----------|
| Success | `#81C784` | `#E8F5E9` |
| Warning | `#FFB74D` | `#FFF3E0` |
| Info | `#64B5F6` | `#E3F2FD` |

---

> **참고**: 색상 값은 `lib/core/theme/feature_colors.dart`에서 관리됩니다.
