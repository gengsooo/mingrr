# 🐾 데이팅 궁합 알고리즘 기획서

## 📋 목차
1. [현재 상태 분석](#1-현재-상태-분석)
2. [개선 완료 사항](#2-개선-완료-사항)
3. [향후 개선 방향](#3-향후-개선-방향)

---

## 1. 현재 상태 분석

### 1.1 점수 배분 (총 100%)

| 항목 | 배점 | 세부 항목 | 상태 |
|-----|-----|---------|-----|
| **체형 궁합** | 20% | 크기 12% + 체중 8% | ✅ 구현 완료 |
| **성격 궁합** | 20% | 보완 8% + 동일 7% + 에너지 5% | ✅ 구현 완료 |
| **거리** | 15% | 거리 기반 점수 | ✅ 구현 완료 |
| **보호자 신뢰도** | 15% | 인증 9% + 꼬순내지수 6% | ✅ 구현 완료 |
| **인기도** | 10% | 상대적 인기도 7% + 신규 부스트 3% | ✅ 구현 완료 |
| **앱 활성도** | 10% | 마지막 접속 시간 | ✅ 구현 완료 |
| **나이 궁합** | 5% | 나이차 3% + 생애단계 2% | ✅ 구현 완료 |
| **품종 궁합** | 5% | 품종 3% + 털타입 2% | ✅ 구현 완료 |

### 1.2 등급 체계

| 점수 | 등급 | 설명 |
|-----|-----|-----|
| 85~100% | 최고 | 환상의 궁합이에요! 🎉 |
| 70~84% | 좋음 | 잘 맞는 친구예요! 😊 |
| 55~69% | 보통 | 괜찮은 친구가 될 수 있어요 🙂 |
| 40~54% | 낮음 | 조금 맞춰가야 할 수 있어요 😐 |
| 0~39% | 매우 낮음 | 서로 다른 점이 많아요 🤔 |

---

## 2. 개선 완료 사항

### 2.1 ✅ 점수 배분 재조정

**변경 전 → 변경 후:**

| 항목 | 변경 전 | 변경 후 | 변경 사유 |
|-----|--------|--------|---------|
| 체형 궁합 | 18% | **20%** | 체형 중요도 상향 |
| 성격 궁합 | 15% | **20%** | 성격 중요도 대폭 상향 |
| 거리 | 14% | **15%** | 거리 중요도 상향 |
| 보호자 인증 | 12% | - | 신뢰도로 통합 |
| 꼬순내 지수 | 10% | - | 신뢰도로 통합 |
| **보호자 신뢰도** | - | **15%** | 인증 9% + 꼬순내 6% 통합 |
| 인기도 | 6% | **10%** | 부익부 방지 로직 추가 |
| 앱 활성도 | 4% | **10%** | 활성 유저 중요도 대폭 상향 |
| 나이 궁합 | 15% | **5%** | 나이보다 성격 중요 |
| 품종 궁합 | 6% | **5%** | 품종 중요도 하향 |
| **합계** | 100% | **100%** | - |

### 2.2 ✅ 꼬순내 지수 직접 연동

**변경 전:** 활동 카운트 기반 임시 계산
```dart
// 기존 (문제)
final activityPoints = 
    (user.matchCount * 4) + 
    (user.walkCount * 2) + 
    (user.transactionCount * 3) + 
    (user.groupCount * 1);
```

**변경 후:** `KkosunnaeService`의 실제 점수 직접 사용
```dart
// 개선 (보호자 신뢰도 15% = 인증 9% + 꼬순내 6%)
static double _calculateTrustScore(UserModel? user) {
  if (user == null) return 0;
  double score = 0;
  
  // A. 인증 점수 (9%)
  if (user.isIdentityVerified) score += 4;  // 본인인증
  if (user.isLocationVerified) score += 3;  // 위치인증
  if (user.isVerified) score += 2;          // 동물등록 인증
  
  // B. 꼬순내 지수 (6%) - 실제 점수 직접 사용
  final kkosunnaeScore = user.kkosunnaeScore ?? 50;
  score += (kkosunnaeScore / 100) * 6;
  
  return min(15, score);
}
```

### 2.3 ✅ 인기도 점수 개선 (부익부 방지)

**변경 전:** 절대적 좋아요 수 기반 (부익부 문제)
```dart
// 기존 (문제)
if (likes >= 100) return 6;
if (likes >= 50) return 5;
// ...
```

**변경 후:** 상대적 인기도 + 신규 가입자 부스트
```dart
// 개선 (인기도 10%)
static double _calculatePopularityScore(PetModel pet) {
  double score = 0;
  final likes = pet.likeCount;
  
  // A. 상대적 인기도 (7%) - 일평균 좋아요 기준
  final daysActive = DateTime.now().difference(pet.createdAt).inDays + 1;
  final likesPerDay = likes / daysActive;
  
  if (likesPerDay >= 3) score += 7;
  else if (likesPerDay >= 2) score += 6;
  else if (likesPerDay >= 1) score += 5;
  else if (likesPerDay >= 0.5) score += 4;
  else if (likesPerDay >= 0.2) score += 3;
  else if (likes >= 1) score += 2;
  else score += 1;
  
  // B. 신규 가입자 부스트 (3%) - 가입 30일 이내
  if (daysActive <= 30) {
    score += 3;
  } else if (daysActive <= 60) {
    score += 1.5;
  }
  
  return min(10, score);
}
```

### 2.4 ✅ 궁합 안내 팝업 추가

- **위치**: 데이팅 화면 탭 바 우측 `?` 버튼
- **표시 탭**: 추천친구, 근처 검색 탭에서만 표시
- **내용**: 등급 안내 + 점수 구성 요소 (8개 항목)
- **다크모드**: 지원
- **파일**: `lib/core/widgets/compatibility_widgets.dart`

---

## 3. 향후 개선 방향

### 3.1 🔲 성격 특성 확장 (Phase 2)

```dart
// 추가 제안 특성
enum PetTrait {
  // 기존 유지...
  
  // 사회성 관련
  friendlyToDogs,      // 다른 강아지와 친함
  friendlyToPeople,    // 사람과 친함
  needsWarmup,         // 적응 시간 필요
  
  // 놀이 스타일
  lovesChasing,        // 쫓기 놀이 좋아함
  lovesTugOfWar,       // 줄다리기 좋아함
  lovesWater,          // 물놀이 좋아함
}
```

### 3.2 🔲 매칭 히스토리 활용 (Phase 3)

- 이전 좋아요/패스 데이터 반영
- 비슷한 유형 반복 추천 방지

### 3.3 🔲 A/B 테스트 시스템 (Phase 3)

- 점수 배분 최적화를 위한 테스트 시스템

---

## 📝 관련 파일

| 파일 | 설명 |
|-----|-----|
| `lib/core/services/matching_service.dart` | 매칭 알고리즘 핵심 |
| `lib/core/widgets/compatibility_widgets.dart` | 궁합 안내 팝업 위젯 |
| `lib/features/dating/presentation/screens/dating_screen.dart` | 데이팅 화면 |
| `lib/features/dating/presentation/providers/dating_provider.dart` | 데이팅 프로바이더 |

---

*작성일: 2026-01-16*
*버전: 2.0 (V4 알고리즘 적용)*
