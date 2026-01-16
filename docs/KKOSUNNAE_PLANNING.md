# 🐾 꼬순내지수 활용방안 종합 기획안

## 📊 1. 현재 시스템 분석

### 1.1 현재 점수 산정 방식 (100점 만점)

| 카테고리 | 배점 | 세부 항목 |
|---------|------|----------|
| **평판 점수** | 40점 | 평균 평점 30점 + 평가 개수 보너스 10점 |
| **활동 점수** | 25점 | 매칭 10점 + 산책 6점 + 거래 6점 + 소모임 3점 |
| **신뢰도 점수** | 20점 | 인증 12점 + 프로필 완성도 5점 + 계정 연령 3점 |
| **앱 활성도** | 15점 | 접속 빈도 10점 + 응답률 5점 |
| **감점 요소** | -15점 | 신고 이력 + 노쇼 이력 |

### 1.2 현재 등급 체계

```
90점 이상: 꼬순내 마스터 (금색 배지)
75~89점: 꼬순내 베테랑 (코랄색)
55~74점: 꼬순내 친구 (민트색)
35~54점: 꼬순내 성장중 (연민트색)
35점 미만: 꼬순내 새싹 (회색)
```

### 1.3 현재 평가 화면 위치

| 화면 | 파일 | 평가 방식 |
|-----|------|----------|
| **보호자 프로필 모달** | `guardian_profile_modal.dart` | 4단계 평가 (최고/좋음/보통/나쁨) |
| **채팅 상세 화면** | `chat_detail_screen.dart` | 거래 완료 후 평가 |
| **반려동물 상세** | `pet_detail_screen.dart` | 보호자 프로필 통해 평가 |
| **마켓 상품 상세** | `product_detail_screen.dart` | 판매자 프로필 통해 평가 |

### 1.4 현재 표시 위젯

| 위젯 | 용도 | 크기 |
|-----|------|-----|
| `KkosunnaeScoreSmall` | 카드/리스트 | 16px 아이콘 |
| `KkosunnaeScoreMedium` | 프로필/상세 | 20px 아이콘 + 라벨 |
| `KkosunnaeScoreLarge` | 상세 페이지 | 32px 아이콘 + 바 |
| `KkosunnaeScoreBar` | 프로필 카드 | 프로그레스 바 포함 |

### 1.5 관련 파일 목록

```
lib/core/services/kkosunnae_service.dart    # 점수 계산 로직
lib/core/services/rating_service.dart       # 평가 관리
lib/core/widgets/warmth_score.dart          # 점수 표시 위젯
lib/core/widgets/kkosunnae_badge.dart       # 배지 위젯
lib/core/widgets/rating_modal.dart          # 평가 모달
lib/core/widgets/guardian_profile_modal.dart # 보호자 프로필
lib/models/rating_model.dart                # 평가 모델
lib/models/user_model.dart                  # 사용자 모델 (kkosunnaeScore 필드)
```

---

## 🔴 2. 현재 문제점

### 2.1 평가 트리거 미흡
- **문제**: 평가 UI는 있지만, 실제 활동 완료 시 자동으로 평가를 요청하는 로직이 부족
- **현황**: 보호자 프로필 모달에서만 수동 평가 가능

### 2.2 활동 카운트 미연동
- **문제**: `matchCount`, `walkCount`, `transactionCount`, `groupCount`가 실제 활동과 자동 연동되지 않음
- **영향**: 활동 점수(25점)가 정확하게 반영되지 않음

### 2.3 평가 시점 불명확
- **문제**: 언제 평가해야 하는지 사용자에게 명확하지 않음
- **결과**: 평가율 저조 → 꼬순내지수 신뢰도 하락

### 2.4 중복 평가 로직
- **문제**: `warmth_score.dart`와 `rating_modal.dart`에 유사한 평가 로직 존재
- **영향**: 코드 유지보수 어려움

---

## 🎯 3. 평가 방식 개선안

### 3.1 평가 트리거 시점 정의

```
┌─────────────────────────────────────────────────────────────┐
│                    평가 트리거 매트릭스                        │
├─────────────────┬───────────────────┬───────────────────────┤
│ 활동 유형        │ 트리거 시점         │ 평가 대상              │
├─────────────────┼───────────────────┼───────────────────────┤
│ 마켓 거래        │ 거래 완료 버튼 클릭  │ 판매자 ↔ 구매자 상호   │
│ 데이팅 만남      │ 만남 완료 버튼 클릭  │ 양쪽 보호자 상호       │
│ 교배 완료        │ 교배 완료 처리 시    │ 양쪽 보호자 상호       │
└─────────────────┴───────────────────┴───────────────────────┘
```

### 3.2 평가 화면별 진입점 설계

```dart
// 1. 마켓플레이스 - 채팅 상세 화면
// 위치: chat_detail_screen.dart
// 트리거: "거래 완료" 버튼 클릭 시
┌─────────────────────────────────────┐
│  [거래 완료하기] 버튼               │
│         ↓                          │
│  거래 결과 선택                     │
│  ○ 거래 완료  ○ 노쇼  ○ 취소       │
│         ↓                          │
│  평가 바텀시트 표시                 │
│  rating_modal.dart 활용              │
└─────────────────────────────────────┘

// 2. 데이팅 - 채팅 상세 화면
// 위치: chat_detail_screen.dart (type == 'dating')
// 트리거: "만남 완료" 버튼 클릭 시
┌─────────────────────────────────────┐
│  [만남 완료하기] 버튼               │
│         ↓                          │
│  만남 결과 선택                     │
│  ○ 만남 완료  ○ 노쇼  ○ 취소       │
│         ↓                          │
│  평가 바텀시트 표시                 │
│  rating_modal.dart 활용              │
└─────────────────────────────────────┘

```

### 3.3 평가 UI 통합 설계

```dart
rating_modal.dart 리펙토링하여 활용
xxx님에 대한 평가를 보내주세요!. 이런 문구가 있었으면 좋겠고(문구는 너가 판단해서 적절히 넣어줘)
현재 수정되는 로직에 맞게 팝업 형태나 디자인, 로직 모두 수정해도 좋아
디자인도 공통화나 사용자 편의성,UI/UX,디자인 등 종합적으로 고려해서 수정해도 좋아
```

---

## 📍 4. 꼬순내지수 활용처 확대

### 4.1 현재 활용처

| 위치 | 활용 방식 |
|-----|----------|
| 보호자 프로필 | 점수 + 등급 표시 |
| 채팅 리스트 | 상대방 점수 표시 |
| 마켓 상품 카드 | 판매자 점수 표시 |
| 데이팅 카드 | 보호자 점수 표시 |

### 4.2 추가 활용처 제안

```
┌─────────────────────────────────────────────────────────────┐
│                    신규 활용처 제안                          │
├─────────────────┼───────────────────────────────────────────┤
│ 1. 매칭 우선순위 │ 데이팅 알고리즘에서 가중치 상향 (10→15점)  │
├─────────────────┼───────────────────────────────────────────┤
│ 2. 소모임 가입   │ 모임장이 최소 점수 설정 가능               │
├─────────────────┼───────────────────────────────────────────┤
```

### 4.3 시각적 차별화

```dart
// 점수대별 시각적 차별화
┌─────────────────────────────────────────────────────────────┐
│ 90~100% (빅뱅)                                           │
│ - 금색 발바닥 아이콘 + 반짝임 효과
│ - "✨🐾우주 끝까지 퍼지는 향! 레전드🐾✨" 문구 + 마스터배지           |
│ - 프로필 테두리 금색 글로우                                  │
├─────────────────────────────────────────────────────────────┤
│ 80~89% (화산)                                         │
│ - 주황색 발바닥 아이콘                                        │
│ - "용암처럼 강렬한 냄새!🌋🐾" 문구                                 │
├─────────────────────────────────────────────────────────────┤
│ 70~79% (뜨끈)                                             │
│ - 빨간색 발바닥 아이콘                                      │
│ - "뜨끈뜨끈 따끈한 냄새!🔥🐾" 문구                                         │
├─────────────────────────────────────────────────────────────┤
│ 50~69% (솔솔)                                            │
│ - 파란색 발바닥 아이콘                                  │
│ - "은은한 냄새가 솔솔~💨🐾" 문구                                │
├─────────────────────────────────────────────────────────────┤
│ 0~49% (쑥쑥)                                               │
│ - 초록색 발바닥 아이콘    │
│ - "냄새가 자라는 중! 더 놀아줘요🌱🐾" 문구                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 5. 알고리즘 개선안

### 5.1 점수 배분 재조정

```
* 점수는 유동적으로 조정해도 됨.
* 빅뱅 - 상위 10%, 화산 - 상위 20%, 뜨끈 - 상위 30%, 솔솔 - 상위 50%, 쑥쑥 - 하위 50% 비율로 분포되도록 구현
[현재]                          [개선안]
평판 점수: 40점                 평판 점수: 40점 (유지)
활동 점수: 25점                 활동 점수: 20점 (-5)
신뢰도 점수: 20점               신뢰도 점수: 15점 (-5)
앱 활성도: 15점                 앱 활성도: 10점 (-5)
감점 요소: -15점                커뮤니티 점수: 10점 (신규)
                               응답률 점수: 5점 (신규)
                               감점 요소: -15점 (유지)
```

### 5.2 신규 점수 항목

```dart
// 커뮤니티 점수 (10점) - 신규
class CommunityScore {
  // 게시글 작성: 0.5점/개 (최대 3점)
  // 댓글 작성: 0.2점/개 (최대 2점)
  // 받은 좋아요: 0.1점/개 (최대 2점)
  // 도움이 됐어요: 0.5점/개 (최대 3점)
}

// 응답률 점수 (5점) - 신규
class ResponseScore {
  // 24시간 내 응답: 5점
  // 48시간 내 응답: 3점
  // 72시간 내 응답: 1점
  // 미응답: 0점
}
```

### 5.3 시간 가중치 도입

```dart
// 최근 평가에 더 높은 가중치 부여
double calculateWeightedRating(List<RatingModel> ratings) {
  double weightedSum = 0;
  double totalWeight = 0;
  
  for (final rating in ratings) {
    final daysSince = DateTime.now().difference(rating.createdAt).inDays;
    
    // 시간 가중치: 최근 평가일수록 높음
    double weight;
    if (daysSince <= 30) {
      weight = 1.0;      // 1개월 이내: 100%
    } else if (daysSince <= 90) {
      weight = 0.8;      // 3개월 이내: 80%
    } else if (daysSince <= 180) {
      weight = 0.5;      // 6개월 이내: 50%
    } else {
      weight = 0.3;      // 6개월 이상: 30%
    }
    
    weightedSum += rating.score * weight;
    totalWeight += weight;
  }
  
  return totalWeight > 0 ? weightedSum / totalWeight : 0;
}
```

### 5.4 이상치 필터링

```dart
// 악의적 평가 필터링
List<RatingModel> filterOutliers(List<RatingModel> ratings) {
  if (ratings.length < 5) return ratings;
  
  // 평균에서 2 표준편차 이상 벗어난 평가 제외
  final scores = ratings.map((r) => r.score.toDouble()).toList();
  final mean = scores.reduce((a, b) => a + b) / scores.length;
  final variance = scores.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
  final stdDev = sqrt(variance);
  
  return ratings.where((r) {
    return (r.score - mean).abs() <= 2 * stdDev;
  }).toList();
}
```

### 5.5 KkosunnaeService 개선 코드 예시

```dart
// lib/core/services/kkosunnae_service.dart 개선안

// 기존 KkosunnaeBreakdown에 추가
class KkosunnaeBreakdown {
  final ScoreDetail reputation;
  final ScoreDetail activity;
  final ScoreDetail trust;
  final ScoreDetail active;
  final ScoreDetail penalty;
  final ScoreDetail community;  // 신규
  final ScoreDetail response;   // 신규

  // ... 생성자 및 팩토리 메서드 수정
}

// 커뮤니티 점수 계산 메서드 추가
static ScoreDetail _calculateCommunityScore(UserModel user) {
  double score = 0;
  final details = <String>[];

  // 게시글 작성 (최대 3점)
  final postScore = min(3.0, user.postCount * 0.5);
  if (user.postCount > 0) {
    score += postScore;
    details.add('게시글 ${user.postCount}개 (+${postScore.toStringAsFixed(1)}점)');
  }

  // 댓글 작성 (최대 2점)
  final commentScore = min(2.0, user.commentCount * 0.2);
  if (user.commentCount > 0) {
    score += commentScore;
    details.add('댓글 ${user.commentCount}개 (+${commentScore.toStringAsFixed(1)}점)');
  }

  // 받은 좋아요 (최대 2점)
  final likeScore = min(2.0, user.receivedLikeCount * 0.1);
  if (user.receivedLikeCount > 0) {
    score += likeScore;
    details.add('받은 좋아요 ${user.receivedLikeCount}개 (+${likeScore.toStringAsFixed(1)}점)');
  }

  // 도움이 됐어요 (최대 3점)
  final helpfulScore = min(3.0, user.helpfulCount * 0.5);
  if (user.helpfulCount > 0) {
    score += helpfulScore;
    details.add('도움이 됐어요 ${user.helpfulCount}개 (+${helpfulScore.toStringAsFixed(1)}점)');
  }

  if (details.isEmpty) {
    details.add('커뮤니티 활동을 시작해보세요');
  }

  return ScoreDetail(
    score: score,
    maxScore: 10,
    description: '커뮤니티 활동 ${score.toStringAsFixed(1)}점',
    details: details,
  );
}
```

---

## 📱 6. UI/UX 개선안

### 6.1 평가 유도 UX

```
[평가 유도 플로우]

1. 활동 완료 직후
   ┌─────────────────────────────────┐
   │  🎉 거래가 완료되었어요!         │
   │                                 │
   │  [지금 평가하기]  [나중에]       │
   └─────────────────────────────────┘

2. 24시간 후 리마인더 (푸시 알림)
   "홍길동님과의 거래는 어떠셨나요? 평가를 남겨주세요 🐾"

3. 48시간 후 인앱 배너
   ┌─────────────────────────────────┐
   │  📝 아직 평가하지 않은 활동이    │
   │     1건 있어요                   │
   │                    [평가하기 →]  │
   └─────────────────────────────────┘

4. 일주일 후 자동 만료
   - 평가 기회 종료, 점수 미반영
5. 상대방 평가 완료 시 (추가)
   "xxx님이 평가를 남겼어요! 나도 평가해볼까요? 🐾"
[추가 권장]
평가 완료 후:
┌─────────────────────────────────┐
│  ✨ 평가 완료!                   │
│  당신의 평가가 더 좋은 커뮤니티를 │
│  만드는 데 도움이 돼요 🐾        │
└─────────────────────────────────┘
```

### 6.2 점수 상세 화면 개선

```dart
// 꼬순내지수 상세 바텀시트 개선
class KkosunnaeDetailSheet {
  // 1. 총점 + 등급 표시
  // 2. 카테고리별 점수 바 (시각화)
  // 3. 최근 받은 평가 미리보기 (최대 3개)
  // 4. 점수 올리는 팁 표시
  // 5. 등급별 혜택 안내
}
```

### 6.3 점수 변동 알림

```dart
// 점수 변동 시 알림
void notifyScoreChange(int oldScore, int newScore) {
  final diff = newScore - oldScore;
  
  if (diff > 0) {
    // 상승 알림
    showNotification(
      title: '꼬순내지수가 올랐어요! 🎉',
      body: '$oldScore% → $newScore% (+$diff%)',
    );
  } else if (diff < 0) {
    // 하락 알림 (감점 사유 포함)
    showNotification(
      title: '꼬순내지수가 변동되었어요',
      body: '$oldScore% → $newScore% ($diff%)',
    );
  }
  
  // 등급 변동 시 특별 알림
  final oldGrade = getGrade(oldScore);
  final newGrade = getGrade(newScore);
  if (oldGrade != newGrade) {
    showNotification(
      title: '등급이 변경되었어요!',
      body: '$oldGrade → $newGrade',
    );
  }
}
```


---

## ✅ 10. 핵심 요약

### 즉시 구현 필요 (P0)
1. **마켓 거래 완료 시 평가 요청 자동화**
2. **활동 카운트 자동 업데이트**
3. **평가 UI 코드 통합 (중복 제거)**

### 중기 개선 (P1-P2)
1. **커뮤니티 활동 점수 반영**
2. **시간 가중치 알고리즘 도입**

---

## 📚 참고: 타 앱 벤치마킹

### 당근마켓 (매너온도)
- 거래 완료 후 자연스러운 평가 유도
- 온도 시각화로 신뢰도 직관적 표현
- 간단한 태그 선택 방식

### 틴더/범블 (데이팅)
- 매칭 후 간단한 피드백 (이모지)
- 상세 평가는 선택사항

### 소모임/문토 (커뮤니티)
- 정기 모임 출석 체크
- 모임장 평가 시스템
- 활동 배지/레벨 시스템

---

*기획안 작성일: 2026-01-15*
*기반 코드 분석: 17개 파일*
*버전: 1.0*