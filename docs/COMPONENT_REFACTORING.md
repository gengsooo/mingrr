# MINGRR 컴포넌트 공통화 및 리팩토링 가이드

> 작성일: 2026-01-17  
> 목적: 프로젝트 전체 코드 분석을 통한 공통화/컴포넌트화 가능 항목 정리

---

## 📊 현재 프로젝트 구조

```
lib/
├── core/
│   ├── config/          # 앱 설정
│   ├── constants/       # 상수 (AppSizes, PetConstants 등)
│   ├── models/          # 공통 모델
│   ├── providers/       # 공통 Provider (9개)
│   ├── services/        # 서비스 레이어 (19개)
│   ├── theme/           # 테마 (FeatureColors, AppTheme)
│   ├── utils/           # 유틸리티 (7개)
│   └── widgets/         # 공통 위젯 (42개 파일)
├── features/
│   ├── auth/            # 인증
│   ├── chat/            # 채팅
│   ├── dating/          # 데이팅
│   ├── health/          # 건강 관리
│   ├── home/            # 홈
│   ├── marketplace/     # 마켓
│   ├── notification/    # 알림
│   ├── onboarding/      # 온보딩
│   ├── pet/             # 반려동물
│   ├── profile/         # 프로필
│   ├── social/          # 소셜
│   └── walk/            # 산책
└── models/              # 데이터 모델 (12개)
```

---

## ✅ 이미 공통화된 컴포넌트

### 1. 기본 UI 컴포넌트 (`common_widgets.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `MingrrButton` | 메인 버튼 | ✅ 전체 사용 |
| `MingrrCard` | 기본 카드 | ✅ 전체 사용 |
| `MingrrAvatar` | 프로필 아바타 | ✅ 전체 사용 |
| `MingrrTextField` | 입력 필드 | ✅ 전체 사용 |
| `MingrrEmptyState` | 빈 상태 | ✅ 전체 사용 |
| `MingrrLoadingState` | 로딩 상태 | ✅ 전체 사용 |
| `MingrrErrorState` | 에러 상태 | ✅ 전체 사용 |
| `MingrrSnackBar` | 스낵바 | ✅ 전체 사용 |
| `MingrrDateSelector` | 날짜 선택 | ✅ 전체 사용 |

### 2. AppBar 액션 버튼 (`appbar_actions.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `AppBarActionButton.search()` | 검색 버튼 | ✅ 데이팅, 마켓, 소셜 |
| `AppBarActionButton.notification()` | 알림 버튼 | ✅ 전체 메인 화면 |
| `AppBarActionButton.profile()` | 프로필 버튼 | ✅ 전체 메인 화면 |

### 3. 필터 컴포넌트 (`filter_components.dart`) - **신규 공통화 완료**
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `MingrrFilterChip` | 기본 필터 칩 | ✅ 데이팅 기준 |
| `MingrrFilterRow` | 필터 행 | ✅ 데이팅 기준 |
| `MingrrFilterSection` | 필터 섹션 | ✅ 데이팅 기준 |
| `MingrrFilterDivider` | 필터 행 내 세로 구분선 | ✅ 데이팅 기준 |
| `MingrrFilterSectionDivider` | 필터 섹션 가로 구분선 | ✅ 데이팅 기준 |
| `MingrrCategoryChips` | 카테고리 칩 목록 | ✅ 마켓, 커뮤니티, 소모임 |
| `MingrrCategoryChipsWithIcon` | 아이콘 포함 카테고리 칩 | ✅ 데이팅 기준 |
| `MingrrSortChip` | 정렬 칩 (단일) | ✅ 소모임 |
| `MingrrSortChips` | 정렬 칩 목록 | ✅ 소모임 |

### 4. 바텀시트 (`mingrr_bottom_sheet.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `BottomSheetHandle` | 드래그 핸들 | ✅ 전체 바텀시트 |
| `MingrrBottomSheet` | 바텀시트 컨테이너 | ✅ 전체 사용 |
| `MingrrBottomButtonBar` | 상세 화면 하단 버튼 | ✅ 상세 화면들 |
| `MingrrSubmitButtonBar` | 등록/수정 화면 버튼 | ✅ Write 화면들 |

### 5. 탭 네비게이션 (`top_navigation.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `PillTabBar` | Pill 형태 탭 바 | ✅ 데이팅, 마켓 |
| `LocationDistanceBar` | 거리 필터 바 | ✅ 데이팅, 마켓 |

### 6. 폼 컴포넌트 (`form_components.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `MingrrSectionLabel` | 폼 섹션 라벨 | ✅ Write 화면들 |
| `MingrrSwitchRow` | 토글 스위치 행 | ✅ Write 화면들 |
| `MingrrSwitchCard` | 토글 스위치 카드 | ✅ Write 화면들 |
| `MingrrChipSelector` | 칩 선택기 (단일/다중) | ✅ Write 화면들 |
| `MingrrImagePicker` | 이미지 피커 (단일/다중) | ✅ Write 화면들 |
| `MingrrFormAppBar` | 폼 화면용 앱바 | ✅ Write 화면들 |

### 7. 꼬순내지수 위젯 (`kkosunnae_widgets.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `KkosunnaeScoreSmall` | 카드/리스트용 (16px) | ✅ 프로필 카드 |
| `KkosunnaeScoreMedium` | 프로필/상세용 (20px) | ✅ 프로필 모달 |
| `KkosunnaeScoreLarge` | 상세 페이지용 (32px) | ✅ 보호자 상세 |
| `KkosunnaeScoreBar` | 프로그레스 바 포함 | ✅ 프로필 카드 |
| `KkosunnaeRatingModal` | 평가 모달 | ✅ 채팅, 프로필 |

### 8. 홈 배너 (`home_reminder_banner.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `HomeReminderBanner` | 단일 리마인더 배너 | ✅ 홈 화면 |
| `HomeReminderBannerCarousel` | 스와이프 캐러셀 | ✅ 홈 화면 |

### 9. 이미지 선택 (`image_picker_sheet.dart`)
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `ImagePickerSheet` | 프로필 이미지 선택 시트 | ✅ 프로필 수정 |
| `showImagePickerSheet()` | 이미지 선택 헬퍼 함수 | ✅ 프로필 수정 |

---

## 🔴 공통화 필요 항목 (우선순위: 높음)

### 1. 상세 화면 레이아웃 통일
**현황:** 각 상세 화면(pet_detail, product_detail, job_detail, community_detail, group_detail)이 유사한 구조를 가지지만 개별 구현

**제안:**
```dart
/// 상세 화면 공통 레이아웃
class MingrrDetailScreen extends StatelessWidget {
  final Widget header;           // 이미지 슬라이더 또는 헤더
  final Widget content;          // 본문 내용
  final Widget? bottomBar;       // 하단 버튼 바
  final List<Widget>? actions;   // AppBar 액션
  final Color? accentColor;      // 테마 색상
}
```

**영향 범위:**
- `pet_detail_screen.dart`
- `product_detail_screen.dart`
- `job_detail_screen.dart`
- `community_detail_screen.dart`
- `group_detail_screen.dart`

---

### 2. 글쓰기 화면 레이아웃 통일
**현황:** 각 글쓰기 화면(breeding_write, product_write, community_write, group_write)이 유사한 폼 구조

**제안:**
```dart
/// 글쓰기 화면 공통 레이아웃
class MingrrWriteScreen extends StatelessWidget {
  final String title;
  final List<Widget> formFields;
  final VoidCallback onSubmit;
  final bool isLoading;
  final Color? accentColor;
}
```

**영향 범위:**
- `breeding_write_screen.dart`
- `product_write_screen.dart`
- `community_write_screen.dart`
- `group_write_screen.dart`

---

### 3. 리스트 아이템 카드 통일
**현황:** 각 화면에서 `_buildXxxCard`, `_buildXxxItem` 형태로 개별 구현 (96개 메서드 발견)

**제안:**
```dart
/// 리스트 아이템 공통 카드
class MingrrListCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final List<Widget>? badges;
  final Widget? trailing;
  final VoidCallback? onTap;
}
```

**영향 범위:**
- `health_screen.dart` (20개 메서드)
- `profile_screen.dart` (19개 메서드)
- `home_screen.dart` (10개 메서드)
- `dating_screen.dart` (8개 메서드)
- 기타 14개 화면

---

### 4. 프로필 모달 통일
**현황:** 여러 프로필 모달이 개별 구현

**제안:**
```dart
/// 프로필 모달 공통 컴포넌트
class MingrrProfileModal extends StatelessWidget {
  final ProfileType type;  // pet, guardian, group
  final String id;
  final Color? accentColor;
}
```

**영향 범위:**
- `pet_profile_modal.dart`
- `guardian_profile_modal.dart`
- `group_profile_modal.dart`

---

### 5. 소모임 일정 컴포넌트 (GROUP_PLANNING.md 기반)
**현황:** 기획서에 정의되어 있으나 UI 컴포넌트 미구현

**제안:**
```dart
/// 소모임 일정 카드
class GroupScheduleCard extends StatelessWidget {
  final GroupScheduleModel schedule;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;
}

/// 소모임 일정 생성 시트
class GroupScheduleWriteSheet extends StatelessWidget {
  final String groupId;
  final GroupScheduleModel? editSchedule;
  final ValueChanged<GroupScheduleModel> onSubmit;
}

/// 멤버 역할 칩 (모임장/운영진/멤버)
class GroupMemberRoleChip extends StatelessWidget {
  final GroupMemberRole role;
  final Color? accentColor;
}
```

**영향 범위:**
- `group_detail_screen.dart`
- `group_schedule_screen.dart` (신규)

---

## 🟡 공통화 필요 항목 (우선순위: 중간)

### 6. 이미지 슬라이더/갤러리
**현황:** 상세 화면마다 이미지 슬라이더 개별 구현

**제안:**
```dart
/// 이미지 슬라이더 공통 컴포넌트
class MingrrImageSlider extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final bool showIndicator;
  final VoidCallback? onTap;
}
```

---

### 7. 설정 화면 리스트 타일
**현황:** 설정 관련 화면들에서 ListTile 개별 스타일링 (125개 ListTile 발견)

**제안:**
```dart
/// 설정 리스트 타일
class MingrrSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
}
```

**영향 범위:**
- `account_settings_screen.dart` (9개)
- `app_settings_screen.dart` (4개)
- `app_info_screen.dart` (5개)
- `customer_service_screen.dart` (6개)

---

### 8. FAB (Floating Action Button) 통일
**현황:** 8개 화면에서 FAB 개별 구현

**제안:**
```dart
/// 공통 FAB
class MingrrFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final String? heroTag;
}
```

**영향 범위:**
- `dating_screen.dart`
- `marketplace_screen.dart`
- `community_screen.dart`
- `group_list_screen.dart`
- `health_screen.dart`
- `walk_screen.dart`

---

### 9. 탭 화면 레이아웃
**현황:** TabBar/IndexedStack 사용 화면들이 유사한 구조

**제안:**
```dart
/// 탭 화면 공통 레이아웃
class MingrrTabScreen extends StatelessWidget {
  final List<MingrrTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final IndexedWidgetBuilder tabBuilder;
}
```

**영향 범위:**
- `social_screen.dart`
- `notification_screen.dart`
- `activity_history_screen.dart`
- `transaction_history_screen.dart`
- `wishlist_screen.dart`

---

## 🟢 공통화 필요 항목 (우선순위: 낮음)

### 10. 신고/차단 시트 통일
**현황:** `report_sheet.dart` 존재하지만 일부 화면에서 개별 구현

---

### 11. 확인 다이얼로그 통일
**현황:** `dialogs/confirm_sheet.dart` 존재하지만 일부 화면에서 개별 구현

---

### 12. 공유 기능 통일
**현황:** `share_service.dart` 존재하지만 UI 부분 개별 구현

---

## 📋 Deprecated 항목 정리

| 파일 | 클래스/함수 | 대체 컴포넌트 |
|-----|------------|-------------|
| `common_widgets.dart` | `NotificationIconButton` | `AppBarActionButton.notification()` |
| `profile_icon.dart` | `buildProfileAction()` | `AppBarActionButton.profile()` |
| `filter_widgets.dart` | `CategoryFilterChips` | `MingrrCategoryChips` |
| `filter_widgets.dart` | `DistanceBottomSheet` | `LocationDistanceBar` |
| `warmth_score.dart` | 전체 | `kkosunnae_widgets.dart` |
| `rating_modal.dart` | 일부 로직 | `KkosunnaeRatingModal` 통합 필요 |

---

## 🎯 리팩토링 우선순위 로드맵

### Phase 1: 즉시 적용 가능 (1-2일)
1. ✅ 필터 컴포넌트 공통화 (완료)
2. ✅ 바텀시트 드래그핸들 통일 (완료)
3. ✅ 필터 구분선 스타일 통일 (완료)
4. ✅ 이미지 선택 바텀시트 디카인 통일 (완료)
5. ✅ 카테고리/정렬 칩 스타일 통일 (완료)
6. FAB 공통화

### Phase 2: 단기 (1주)
7. 리스트 아이템 카드 공통화
8. 설정 화면 리스트 타일 공통화
9. 이미지 슬라이더 공통화

### Phase 3: 중기 (2-3주)
10. 상세 화면 레이아웃 통일
11. 글쓰기 화면 레이아웃 통일
12. 프로필 모달 통일

### Phase 4: 장기 (1개월)
13. 탭 화면 레이아웃 통일
11. 전체 코드 리뷰 및 Deprecated 항목 제거

---

## 📁 권장 파일 구조

```
lib/core/widgets/
├── buttons/
│   ├── mingrr_button.dart
│   ├── mingrr_fab.dart
│   └── social_login_button.dart
├── cards/
│   ├── mingrr_card.dart
│   ├── mingrr_list_card.dart        (신규 제안)
│   └── product_card.dart
├── filters/
│   ├── filter_components.dart       ✅ 완료
│   ├── filter_widgets.dart          (deprecated 예정)
│   └── location_selector.dart       ✅ 완료
├── forms/
│   ├── form_components.dart         ✅ 완료
│   ├── mingrr_text_field.dart
│   └── tag_input.dart
├── layouts/
│   ├── detail_screen_layout.dart    (신규 제안)
│   ├── write_screen_layout.dart     (신규 제안)
│   └── tab_screen_layout.dart       (신규 제안)
├── modals/
│   ├── mingrr_bottom_sheet.dart     ✅ 완료
│   ├── image_picker_sheet.dart      ✅ 완료
│   ├── pet_profile_modal.dart
│   ├── guardian_profile_modal.dart
│   └── group_profile_modal.dart
├── navigation/
│   ├── appbar_actions.dart          ✅ 완료
│   └── top_navigation.dart          ✅ 완료
├── scores/
│   ├── kkosunnae_widgets.dart       ✅ 완료
│   └── rating_widgets.dart
├── banners/
│   └── home_reminder_banner.dart    ✅ 완료
├── states/
│   ├── mingrr_empty_state.dart
│   ├── mingrr_loading_state.dart
│   └── mingrr_error_state.dart
└── common_widgets.dart              (export 파일로 변경 권장)
```

---

## 📝 참고 사항

### 공통화 시 고려사항
1. **하위 호환성**: 기존 코드가 동작하도록 deprecated 처리 후 점진적 마이그레이션
2. **테마 지원**: `accentColor` 파라미터로 화면별 테마 색상 적용
3. **확장성**: 필수 파라미터 최소화, 선택적 파라미터로 커스터마이징 지원
4. **성능**: `const` 생성자 활용, 불필요한 리빌드 방지

### 네이밍 컨벤션
- 공통 컴포넌트: `Mingrr` 접두사 사용
- 화면별 컴포넌트: `_` 접두사 (private)
- 바텀시트: `Sheet` 접미사
- 모달: `Modal` 접미사

---

## 🔗 관련 문서
- [FIRESTORE_STRUCTURE.md](./FIRESTORE_STRUCTURE.md) - 데이터 구조
- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - 구현 요약
- [KKOSUNNAE_PLANNING.md](./KKOSUNNAE_PLANNING.md) - 꼬순내 기능 기획
