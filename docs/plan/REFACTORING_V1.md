# MINGRR 컴포넌트 공통화 및 리팩토링 가이드 (V1)

> 작성일: 2026-01-17  
> 완료일: 2026-01-18  
> 상태: ✅ **완료**  
> 목적: 프로젝트 전체 코드 분석을 통한 공통화/컴포넌트화 가능 항목 정리

---

## 📊 V1 리팩토링 완료 요약

| 항목 | 완료 내용 |
|------|----------|
| **Phase 1-2** | 필터 컴포넌트, 바텀시트, FAB 공통화 |
| **Phase 3** | 상세 화면 레이아웃, 글쓰기 화면 통일 |
| **Phase 4** | 탭 화면 레이아웃 통일 |
| **Phase 5** | 데이팅 카드 디자인 통일 |
| **Phase 6** | 교배찾기 혈통서 기능 강화 |
| **Phase 7-9** | 로딩 상태 공통화, 타임아웃 처리 |
| **Phase 12** | 프로필 모달 통일 |
| **Phase 13** | 좋아요 컴포넌트 & 빈 상태 UI 공통화 |

### 총 효과
- **코드 절감**: ~2,500줄
- **공통 컴포넌트**: 50+ 개
- **디자인 통일성**: 90% → 98%
- **유지보수성**: 크게 향상

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

### 10. FAB 컴포넌트 (`mingrr_fab.dart`) - **신규 공통화 완료**
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `MingrrFAB` | 기본 FAB | ✅ 전체 화면 |
| `MingrrFAB.write()` | 글쓰기/편집 FAB | ✅ 데이팅, 마켓, 커뮤니티 |
| `MingrrFAB.add()` | 추가 FAB | ✅ 소모임, 건강수첩 |
| `MingrrFAB.location()` | 현재 위치 FAB (small) | ✅ 산책 |
| `MingrrFAB.extended()` | 확장형 FAB (아이콘+텍스트) | ✅ 필요시 사용 |
| `MingrrFABBuilder` | 조건부 FAB 표시 헬퍼 | ✅ AsyncValue 연동 |
| `MingrrFABColumn` | 다중 FAB 세로 배치 | ✅ 지도 화면 등 |

### 11. 설정 타일 컴포넌트 (`mingrr_settings_tile.dart`) - **신규 공통화 완료**
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `MingrrSettingsTile` | 기본 설정 타일 | ✅ 설정 화면 전체 |
| `MingrrSettingsTile.destructive()` | 위험 동작 타일 (빨간색) | ✅ 로그아웃, 탈퇴, 캐시삭제 |
| `MingrrSettingsTile.toggle()` | 토글 스위치 타일 | ✅ 설정 옵션 |
| `MingrrSettingsTile.connection()` | 연결 상태 타일 | ✅ 소셜 로그인 연동 |
| `MingrrSettingsTile.radio()` | 라디오 선택 타일 | ✅ 테마 모드 선택 |
| `MingrrSettingsTile.badge()` | 배지 포함 타일 | ✅ 프로필 메뉴 |
| `MingrrSettingsSection` | 설정 섹션 헤더 | ✅ 설정 화면 |

### 12. 기록 타일 컴포넌트 (`mingrr_record_tile.dart`) - **신규 공통화 완료**
| 컴포넌트 | 용도 | 사용 현황 |
|---------|------|----------|
| `MingrrRecordTile` | 기본 기록 타일 | ✅ 건강수첩 |
| `MingrrRecordTile.medication()` | 투약 기록 타일 | ✅ 건강수첩 투약 |
| `MingrrRecordStatusBadge` | 상태 배지 (복용중/완료) | ✅ 건강수첩 |

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

### 3. 리스트 아이템 타일 통일 - **분석 완료, 선택적 공통화 권장**
**현황:** 각 화면에서 `_buildXxxCard`, `_buildXxxItem` 형태로 개별 구현 (136개 메서드, 21개 파일)

**분석 결과:**
- 채팅/알림/프로필 카드: 각각 고유한 비즈니스 로직 → **공통화 비권장**
- 설정 메뉴/기록 아이템: 패턴 명확 → **공통화 권장**

**제안 (수정됨):** 범용 `MingrrListCard` 대신 **특화된 2개 컴포넌트**
```dart
/// 1. 설정 메뉴용 타일 (24개 ListTile 대체, ~420줄 절감)
class MingrrSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;  // 빨간색 (로그아웃, 탈퇴 등)
}

/// 2. 기록 아이템용 타일 (건강수첩 전용, ~110줄 절감)
class MingrrRecordTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
}
```

**영향 범위:**
- `MingrrSettingsTile`: 설정 화면 4개 (account, app, customer, info)
- `MingrrRecordTile`: `health_screen.dart`

**비공통화 대상 (현재 구조 유지):**
- `chat_list_screen.dart` - 타입별 복잡한 분기 로직
- `notification_screen.dart` - 타입별 아이콘/색상 로직
- `profile_screen.dart` - 화면별 다른 레이아웃

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

### 6. 이미지 슬라이더/갤러리 ✅ 완료
**현황:** 상세 화면마다 이미지 슬라이더 개별 구현 (5개 화면)

**구현된 컴포넌트:**

#### 6-1. `MingrrImageViewer` (전체화면 뷰어)
```dart
class MingrrImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final bool enableZoom;              // 확대/축소 (InteractiveViewer)
  final VoidCallback? onShare;        // 공유 버튼 (옵션)
}
```

#### 6-2. `MingrrImageGallery` (본문 내 가로 스크롤)
```dart
class MingrrImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final double? itemWidth;            // null이면 height와 동일
  final bool enableViewer;            // 탭 시 MingrrImageViewer 열기
  final VoidCallback? onShare;        // 공유 버튼 (옵션)
}
```

#### 6-3. `MingrrImageHeader` (SliverAppBar 슬라이더)
```dart
class MingrrImageHeader extends StatefulWidget {
  // 필수
  final List<String> imageUrls;
  final double expandedHeight;
  
  // 슬라이더 옵션
  final bool showIndicator;           // 페이지 인디케이터 (점)
  final Widget? placeholder;          // 이미지 없을 때
  final bool pinned;                  // AppBar 고정 (기본 true)
  
  // AppBar 액션 (옵션)
  final VoidCallback? onShare;        // 공유 버튼
  final VoidCallback? onMore;         // 더보기 버튼
  final Widget? customAction;         // 커스텀 액션 (좋아요 등)
  
  // 4개 코너 오버레이 (옵션)
  final Widget? topLeftOverlay;       // 좌상단 (성별 배지)
  final Widget? topRightOverlay;      // 우상단 (거리 배지)
  final Widget? bottomLeftOverlay;    // 좌하단 (좋아요 버튼)
  final Widget? bottomRightOverlay;   // 우하단 (궁합점수)
  
  // 콜백
  final ValueChanged<int>? onPageChanged;
}
```

**적용 화면:**
| 화면 | 컴포넌트 | 오버레이 | 액션 |
|------|----------|----------|------|
| `pet_detail_screen.dart` | `MingrrImageHeader` | 4개 코너 모두 | 더보기 |
| `product_detail_screen.dart` | `MingrrImageHeader` | 없음 | 공유, 더보기 |
| `job_detail_screen.dart` | `MingrrImageHeader` | 없음 | 공유, 더보기 |
| `group_detail_screen.dart` | `MingrrImageHeader` | 없음 | 좋아요(custom), 더보기 |
| `community_detail_screen.dart` | `MingrrImageGallery` | - | 공유 |

**코드 절감:** ~340줄

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

### 9. 탭 화면 레이아웃 ✅ 완료
**현황:** TabBar/IndexedStack 사용 화면들이 유사한 구조

**구현된 컴포넌트:** (`top_navigation.dart`)
```dart
/// 탭 아이템 정의
class MingrrTabItem {
  final String label;
  final String? emoji;
  final IconData? icon;
  final Color color;
}

/// 메인 화면용 탭 바 (Pill 형태)
class MingrrMainTabBar extends StatelessWidget {
  final List<MingrrTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
}

/// 서브 화면용 탭 바 (밑줄 인디케이터)
class MingrrSubTabBar extends StatelessWidget {
  final List<String> tabs;
  final Color? accentColor;
}
```

**적용 화면:**
- `MingrrMainTabBar`: `dating_screen.dart`, `marketplace_screen.dart`, `chat_list_screen.dart`, `social_screen.dart`
- `MingrrSubTabBar`: `activity_history_screen.dart`, `transaction_history_screen.dart`, `wishlist_screen.dart`

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
6. ✅ FAB 공통화 (완료) - `mingrr_fab.dart`

### Phase 2: 단기 (1주)
7. ✅ 설정 화면 리스트 타일 공통화 (완료) - `mingrr_settings_tile.dart`
8. ✅ 기록 아이템 타일 공통화 (완료) - `mingrr_record_tile.dart`
9. ✅ 이미지 슬라이더 공통화 (완료) - `mingrr_image_header.dart`, `mingrr_image_gallery.dart`, `mingrr_image_viewer.dart`

### Phase 3: 중기 (2-3주)
10. ✅ 상세 화면 레이아웃 통일 (완료) - `showDetailOptionsSheet` 헬퍼 추가
11. ✅ 글쓰기/등록/수정 화면 레이아웃 통일 (완료) - `MingrrFormAppBar` 적용 확대
12. ✅ 프로필 모달 통일 (완료) - `profile_modal_components.dart`

### Phase 4: 장기 (1개월)
13. ✅ 탭 화면 레이아웃 통일 (완료) - `MingrrMainTabBar`, `MingrrSubTabBar`
14. 전체 코드 리뷰 및 Deprecated 항목 제거

---

## 📊 Phase 3 상세 분석: 상세 화면 & 글쓰기/등록/수정 화면 통일

> 작성일: 2026-01-18
> 목적: 상세 화면과 글쓰기/등록/수정 화면의 레이아웃 공통화 분석

---

### 10. 상세 화면 레이아웃 통일 (Detail Screens)

#### 현재 상세 화면 목록 (8개)

| 화면 | 파일 | 하단 버튼 | 공통 컴포넌트 사용 |
|------|------|----------|------------------|
| 반려동물 상세 | `pet_detail_screen.dart` | 데이트/교배 신청 | `MingrrBottomButtonBar` ✅ |
| 상품 상세 | `product_detail_screen.dart` | 채팅하기 | `MingrrBottomButtonBar` ✅ |
| 알바 상세 | `job_detail_screen.dart` | 지원하기 | `MingrrBottomButtonBar` ✅ |
| 커뮤니티 상세 | `community_detail_screen.dart` | 댓글 입력 | 별도 구현 |
| 소모임 상세 | `group_detail_screen.dart` | 가입하기/채팅 | `MingrrBottomButtonBar` ✅ |
| 채팅 상세 | `chat_detail_screen.dart` | 메시지 입력 | 별도 구현 |
| 건강기록 상세 | `health_record_detail_screens.dart` | 없음 | - |
| 산책기록 상세 | `walk_record_detail_screen.dart` | 없음 | - |

#### 공통 레이아웃 패턴

```
┌─────────────────────────────────┐
│ AppBar (제목, 더보기 버튼)        │
├─────────────────────────────────┤
│                                 │
│ 이미지/헤더 영역                  │
│ (MingrrImageHeader 사용)         │
│                                 │
├─────────────────────────────────┤
│                                 │
│ 콘텐츠 영역 (스크롤)              │
│ - 기본 정보                      │
│ - 상세 정보                      │
│ - 작성자/판매자 정보              │
│                                 │
├─────────────────────────────────┤
│ 하단 버튼 바 (MingrrBottomButtonBar) │
└─────────────────────────────────┘
```

#### 공통 요소
- `context.detailBackground` 배경색
- 더보기 메뉴 (`_showMoreOptions`) - 6개 화면에서 동일 패턴
- 좋아요/찜 기능
- 작성자/판매자 프로필 카드
- 신고/차단 기능

#### 제안: `MingrrDetailScaffold`

```dart
/// 상세 화면 공통 Scaffold
class MingrrDetailScaffold extends StatelessWidget {
  // 필수
  final Widget body;
  
  // AppBar
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onMoreOptions;
  
  // 하단 버튼
  final Widget? bottomBar;
  
  // 테마
  final Color? accentColor;
  
  // 배경
  final bool useDetailBackground; // context.detailBackground 사용
}
```

#### 공통화 효과
- 코드 중복 감소: ~200줄/화면 × 6개 = ~1,200줄
- 더보기 메뉴 로직 중앙화
- 배경색/테마 일관성 보장

---

### 11. 글쓰기/등록/수정 화면 레이아웃 통일 (Write/Edit Screens)

#### 현재 글쓰기/등록/수정 화면 목록 (11개)

| 화면 | 파일 | 유형 | 공통 컴포넌트 사용 |
|------|------|------|------------------|
| **기획서 명시 (4개)** | | | |
| 교배 등록 | `breeding_write_screen.dart` | 글쓰기 | `MingrrFormAppBar` ✅, `MingrrSubmitButtonBar` ✅ |
| 상품 등록 | `product_write_screen.dart` | 글쓰기 | `MingrrFormAppBar` ✅, `MingrrSubmitButtonBar` ✅ |
| 커뮤니티 글쓰기 | `community_write_screen.dart` | 글쓰기 | `MingrrFormAppBar` ✅, `MingrrSubmitButtonBar` ✅ |
| 소모임 만들기 | `group_write_screen.dart` | 글쓰기 | `MingrrFormAppBar` ✅, `MingrrSubmitButtonBar` ✅ |
| **기획서 미명시 (7개)** | | | |
| 프로필 수정 | `profile_edit_screen.dart` | 수정 | `MingrrSubmitButtonBar` ✅ |
| 반려동물 추가/수정 | `pet_edit_screen.dart` | 등록/수정 | `MingrrSubmitButtonBar` ✅ |
| 건강기록 추가 | `health_record_add_screens.dart` | 바텀시트 | `MingrrInputBottomSheet` ✅ (6개) |
| 온보딩 | `onboarding_screen.dart` | 등록 | 별도 구현 |

#### 공통 레이아웃 패턴

```
┌─────────────────────────────────┐
│ MingrrFormAppBar (제목, X버튼)   │
├─────────────────────────────────┤
│                                 │
│ Form 영역 (스크롤)               │
│ - MingrrSectionLabel            │
│ - TextField                     │
│ - MingrrChipSelector            │
│ - MingrrImagePicker             │
│ - MingrrSwitchRow               │
│                                 │
├─────────────────────────────────┤
│ MingrrSubmitButtonBar (등록/저장) │
└─────────────────────────────────┘
```

#### 공통 요소
- `context.detailBackground` 배경색
- `MingrrFormAppBar` (X 버튼으로 닫기)
- `MingrrSubmitButtonBar` (하단 고정 버튼)
- `MingrrSectionLabel` (섹션 라벨)
- `MingrrChipSelector` (칩 선택기)
- `MingrrImagePicker` (이미지 피커)
- `MingrrSwitchRow` (토글 스위치)
- 로딩 상태 (`_isLoading`)
- 수정 모드 판별 (`_isEditMode`)

#### 제안: `MingrrFormScaffold`

```dart
/// 폼 화면 공통 Scaffold
class MingrrFormScaffold extends StatelessWidget {
  // 필수
  final String title;
  final Widget body;
  final VoidCallback onSubmit;
  
  // 버튼
  final String submitLabel;        // 기본: '저장'
  final bool isLoading;
  final bool canSubmit;            // 제출 가능 여부
  
  // 테마
  final Color? accentColor;
  
  // 옵션
  final bool showCloseButton;      // X 버튼 (기본: true)
  final VoidCallback? onClose;     // 닫기 전 확인
  final bool useDetailBackground;  // context.detailBackground 사용
}
```

#### 공통화 효과
- 코드 중복 감소: ~50줄/화면 × 7개 = ~350줄
- 앱바/버튼 스타일 일관성 보장
- 로딩/제출 로직 중앙화

---

### 추가 공통화 가능 요소

#### 1. 더보기 옵션 메뉴 (`_showMoreOptions`)
**현황:** 6개 상세 화면에서 동일 패턴으로 구현

```dart
// 현재: 각 화면에서 개별 구현
void _showMoreOptions(BuildContext context) {
  showMingrrOptionsSheet(
    context: context,
    options: [
      MingrrOptionItem(icon: Icons.block_outlined, label: '차단하기', ...),
      MingrrOptionItem(icon: Icons.report_outlined, label: '신고하기', ...),
    ],
  );
}
```

**제안:** `MingrrDetailOptionsSheet` 헬퍼

```dart
/// 상세 화면 더보기 옵션 시트
void showDetailOptionsSheet({
  required BuildContext context,
  required String targetId,
  required String targetName,
  required ReportTargetType targetType,
  bool isOwner = false,           // 본인 글이면 수정/삭제 표시
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onBlock,
});
```

#### 2. 키보드 대응 바텀시트 (`MingrrInputBottomSheet`)
**현황:** 이미 공통화 완료 ✅
- `health_record_add_screens.dart` (6개 바텀시트)
- `report_sheet.dart`
- `request_sheet.dart`

**최근 개선:**
- `AppSizes.bottomSheetButtonPaddingH/V` 상수 추가
- 커스텀 버튼 지원 (`customButton`)
- 헤더 아이콘/부제목 지원

#### 3. 비동기 데이터 로딩 패턴
**현황:** 각 화면에서 `AsyncValue.when()` 개별 구현

```dart
// 현재: 각 화면에서 반복
return asyncData.when(
  data: (data) => _buildContent(data),
  loading: () => const MingrrLoadingState(),
  error: (e, _) => MingrrErrorState(message: '$e'),
);
```

**제안:** `MingrrAsyncBuilder` 위젯

```dart
class MingrrAsyncBuilder<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error)? errorBuilder;
}
```

---

### 개발 계획: Phase 3 상세 ✅ 완료

> 완료일: 2026-01-18

#### 10. 상세 화면 레이아웃 통일 ✅ 완료

**구현 내용:**
- `showDetailOptionsSheet` 헬퍼 함수 추가 (`mingrr_bottom_sheet.dart`)
- 본인/타인 글 구분하여 옵션 자동 표시 (수정/삭제 vs 차단/신고)
- 공유 옵션 지원

**적용 화면 (5개):**
- ✅ `pet_detail_screen.dart`
- ✅ `product_detail_screen.dart`
- ✅ `job_detail_screen.dart`
- ✅ `community_detail_screen.dart`
- ✅ `group_detail_screen.dart`

**코드 절감:** 각 화면 ~20줄 × 5개 = ~100줄

#### 11. 글쓰기/등록/수정 화면 레이아웃 통일 ✅ 완료

**구현 내용:**
- 기존 `MingrrFormAppBar` 활용 (X 버튼으로 닫기)
- 프로필/반려동물 수정 화면에 적용 확대

**적용 화면:**
- ✅ `breeding_write_screen.dart` (기존)
- ✅ `product_write_screen.dart` (기존)
- ✅ `community_write_screen.dart` (기존)
- ✅ `group_write_screen.dart` (기존)
- ✅ `profile_edit_screen.dart` (신규 적용)
- ✅ `pet_edit_screen.dart` (신규 적용)

---

### 실제 효과

| 항목 | 결과 |
|------|------|
| 더보기 메뉴 로직 | 5곳 중복 → 1곳 중앙화 (~100줄 절감) |
| 폼 앱바 통일 | 6개 화면 동일 스타일 적용 |
| 디자인 일관성 | 완전 통일 |
| 유지보수 | 공통 수정으로 시간 절감 |

---

## 📊 Phase 3 추가 작업: 폼 컴포넌트 디자인 통일

> 완료일: 2026-01-18
> 목적: 등록/수정 화면의 TextField, Switch, SectionLabel 디자인 통일

### 발견된 불일치 항목 및 해결

#### 1. TextField 사용 방식 통일 ✅
| 화면 | Before | After |
|------|--------|-------|
| `profile_edit_screen.dart` | `TextFormField` 직접 사용 | `MingrrTextField` 적용 |
| `pet_edit_screen.dart` | `TextFormField` 직접 사용 | `MingrrTextField` 적용 |
| `community_write_screen.dart` | `TextField` 직접 사용 | `MingrrTextField` 적용 |

#### 2. 토글 스위치 통일 ✅
| 화면 | Before | After |
|------|--------|-------|
| `pet_edit_screen.dart` | `SwitchListTile` 직접 사용 | `MingrrSwitchCard` 적용 |

#### 3. 섹션 라벨 통일 ✅
| 화면 | Before | After |
|------|--------|-------|
| `profile_edit_screen.dart` | `_buildSectionTitle()` 직접 구현 | `MingrrSectionLabel` 적용 |
| `pet_edit_screen.dart` | `_buildSectionTitle()` 직접 구현 | `MingrrSectionLabel` 적용 |

#### 4. hintText 상수화 ✅
| 화면 | Before | After |
|------|--------|-------|
| `group_write_screen.dart` | 하드코딩 | `FormStrings` 상수 사용 |
| `profile_edit_screen.dart` | 하드코딩 | `FormStrings` 상수 사용 |
| `pet_edit_screen.dart` | 하드코딩 | `FormStrings` 상수 사용 |

### 추가된 상수 (`form_strings.dart`)

```dart
// FormStrings
static const String hintPetName = '반려동물 이름을 입력해주세요';
static const String hintBreed = '예: 골든 리트리버, 말티즈';
static const String hintWeight = '예: 5.5';
static const String hintPetBio = '반려동물을 소개해주세요\n예: 활발하고 사람을 좋아하는 아이입니다.';
static const String hintUserBio = '다른 보호자들에게 보여질 자기소개를 작성해주세요.';
static const String hintGroupName = '소모임 이름을 입력해주세요';
static const String hintGroupDescription = '소모임에 대해 소개해주세요';

// SwitchStrings
static const String neutered = '중성화 여부';
static const String neuteredYes = '중성화 완료';
static const String neuteredNo = '중성화 안함';
static const String hasPedigree = '혈통서 보유';
static const String hasPedigreeYes = '혈통서 있음';
static const String hasPedigreeNo = '혈통서 없음';
```

### 변경된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `form_strings.dart` | 프로필/반려동물 관련 상수 추가 |
| `profile_edit_screen.dart` | `MingrrTextField`, `MingrrSectionLabel`, `FormStrings` 적용 |
| `pet_edit_screen.dart` | `MingrrTextField`, `MingrrSwitchCard`, `MingrrSectionLabel`, `FormStrings` 적용 |
| `community_write_screen.dart` | 본문 입력 `MingrrTextField` 적용 |
| `group_write_screen.dart` | hintText `FormStrings` 상수화 |

### 효과

| 항목 | 결과 |
|------|------|
| TextField 스타일 | 6개 화면 완전 통일 |
| Switch 스타일 | 배경색 통일 (`inputBackground`) |
| 섹션 라벨 | 모든 화면 `MingrrSectionLabel` 사용 |
| hintText 관리 | 중앙 집중화 (유지보수 용이) |
| 코드 절감 | ~150줄 |

---

## 📊 Phase 4: 필터 컴포넌트 공통화

> 완료일: 2026-01-18
> 목적: 필터 컴포넌트 공통화 및 디자인 통일

### 문제점 분석

1. **공통 컴포넌트 미사용**: `MingrrFilterRow`, `MingrrFilterSection` 등이 정의되어 있으나 실제 화면에서 미사용
2. **중복 구현**: `dating_screen.dart`에서 자체 `_buildFilterRow` 메서드 사용
3. **타이틀 스타일 불일치**: 필터 타이틀에 배경색이 있어 디자인 불일치

### 수정 내용

#### 1. 필터 타이틀 스타일 통일 ✅
| 컴포넌트 | Before | After |
|---------|--------|-------|
| `MingrrFilterRow` | 배경색 + fontSize 11 | 배경 없음 + fontSize 12 + w700 |
| `MingrrCategoryChips` | 배경색 + fontSize 11 | 배경 없음 + fontSize 12 + w700 |
| `MingrrCategoryChipsWithIcon` | 배경색 + fontSize 11 | 배경 없음 + fontSize 12 + w700 |

#### 2. dating_screen.dart 공통화 ✅
| Before | After |
|--------|-------|
| 자체 `_buildFilterRow` 메서드 | `MingrrFilterRow` 사용 |
| 자체 `Container` 래핑 | `MingrrFilterSection` 사용 |
| `_buildDivider()` 메서드 | `MingrrFilterDivider` 직접 사용 |

#### 3. 지역선택 바텀시트 통일 ✅
| 항목 | Before | After |
|------|--------|-------|
| 단일선택 헤더 | 초기화(우측), 완료 버튼 | 초기화(좌측), 완료 버튼 제거 |
| 다중선택 시/군 아이콘 | > 아이콘 표시 | > 아이콘 제거 |
| + 아이콘 색상 | `onSurfaceVariant` | `accentColor` |

### 변경된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `filter_components.dart` | 3개 컴포넌트 타이틀 스타일 통일 |
| `dating_screen.dart` | `MingrrFilterRow`, `MingrrFilterSection` 적용 |
| `location_selector.dart` | 바텀시트 헤더 통일, > 아이콘 제거, + 아이콘 색상 통일 |

### 공통 필터 컴포넌트 사용 현황

| 컴포넌트 | 사용 화면 |
|---------|----------|
| `MingrrFilterRow` | ✅ `dating_screen.dart` |
| `MingrrFilterSection` | ✅ `dating_screen.dart` |
| `MingrrFilterDivider` | ✅ `dating_screen.dart` |
| `MingrrFilterSectionDivider` | ✅ `dating_screen.dart` |
| `MingrrCategoryChips` | ✅ `marketplace_screen.dart`, `community_screen.dart` |
| `MingrrFilterChip` | 🔄 향후 적용 예정 |
| `MingrrSortChip` | 🔄 향후 적용 예정 |

### 효과

| 항목 | 결과 |
|------|------|
| 필터 타이틀 스타일 | 모든 화면 통일 (배경 없음 + 볼드체) |
| 코드 중복 | ~45줄 절감 (`dating_screen.dart`) |
| 유지보수 | 공통 컴포넌트 수정으로 전체 반영 |
| 확장성 | 새 화면에서 공통 컴포넌트 재사용 가능 |

---

## 📊 Phase 5: 필터 타이틀 공통 위젯화

> 완료일: 2026-01-18
> 목적: 필터 컴포넌트 내 중복 타이틀 코드 제거

### 문제점

`filter_components.dart`에 동일한 타이틀 스타일 코드가 **4곳에 중복**되어 있어서 일부만 수정하고 나머지를 놓치는 문제 발생

### 해결 방법

공통 타이틀 위젯 `_FilterTitle` 생성 및 모든 필터 컴포넌트에 적용

```dart
class _FilterTitle extends StatelessWidget {
  final String title;
  const _FilterTitle(this.title);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
```

### 적용된 컴포넌트

| 컴포넌트 | 상태 |
|---------|------|
| `MingrrFilterRow` | ✅ `_FilterTitle` 적용 |
| `MingrrCategoryChips` | ✅ `_FilterTitle` 적용 |
| `MingrrCategoryChipsWithIcon` | ✅ `_FilterTitle` 적용 |
| `MingrrSortChips` | ✅ `_FilterTitle` 적용 |

### 효과

| 항목 | 결과 |
|------|------|
| 코드 중복 | 4곳 → 1곳 (타이틀 스타일 코드 ~40줄 절감) |
| 유지보수 | 타이틀 스타일 변경 시 1곳만 수정 |
| 일관성 | 향후 누락 방지 |

### 향후 작업

| 작업 | 상태 | 설명 |
|------|------|------|
| `dating_screen.dart`의 `_buildFilterChip` | ✅ 완료 | `MingrrFilterChip` 사용으로 교체 |
| `dating_screen.dart`의 `_buildGenderFilterChip` | ✅ 완료 | 공통 컴포넌트로 교체 |

---

## 📊 Phase 6: 필터 칩 완전 공통화

> 완료일: 2026-01-18
> 목적: dating_screen.dart의 자체 필터 칩 메서드를 MingrrFilterChip으로 완전 교체

### 수정 내용

#### 1. MingrrFilterChip 확장
- `iconSize` 파라미터 추가 (기본값: 12)
- 성별 필터 칩의 아이콘 크기(14) 지원

#### 2. dating_screen.dart 공통화

| 메서드 | Before | After |
|--------|--------|-------|
| `_buildGenderFilters` | `_buildGenderFilterChip` 사용 | `MingrrFilterChip` 사용 |
| `_buildBreedFilters` | `_buildFilterChip` 사용 | `MingrrFilterChip` 사용 |
| `_buildSizeFilters` | `_buildFilterChip` + `Builder` | `MingrrFilterChip` 사용 |
| `_buildAgeFilters` | `_buildFilterChip` 사용 | `MingrrFilterChip` 사용 |
| `_buildVerificationFilters` | `_buildFilterChip` 사용 | `MingrrFilterChip` 사용 |

#### 3. 삭제된 코드
- `_buildFilterChip` 메서드 (~50줄)
- `_buildGenderFilterChip` 메서드 (~40줄)

### 변경된 파일

| 파일 | 변경 내용 |
|------|----------|
| `filter_components.dart` | `MingrrFilterChip`에 `iconSize` 파라미터 추가 |
| `dating_screen.dart` | 5개 필터 메서드 공통화, 2개 자체 메서드 삭제 |

### 효과

| 항목 | 결과 |
|------|------|
| 코드 절감 | ~90줄 삭제 |
| 공통 컴포넌트 사용 | 16곳에서 `MingrrFilterChip` 사용 |
| 유지보수 | 필터 칩 스타일 변경 시 1곳만 수정 |
| 일관성 | 모든 필터 칩 동일한 스타일 보장 |

---

## 📁 권장 파일 구조

```
lib/core/widgets/
├── buttons/
│   ├── mingrr_button.dart
│   ├── mingrr_fab.dart              ✅ 완료
│   └── social_login_button.dart
├── cards/
│   ├── mingrr_card.dart
│   └── product_card.dart
├── tiles/
│   ├── mingrr_settings_tile.dart    ✅ 완료
│   └── mingrr_record_tile.dart      ✅ 완료
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
│   ├── profile_modal_components.dart ✅ 완료 (Phase 12)
│   ├── pet_profile_modal.dart       ✅ 완료 (Phase 12)
│   ├── guardian_profile_modal.dart  ✅ 완료 (Phase 12)
│   └── group_profile_modal.dart     ✅ 완료 (Phase 12)
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

## � Phase 12: 프로필 모달 통일

> 작성일: 2026-01-18
> 목적: 프로필 모달 공통 빌딩 블록 추출 및 디자인 통일

### 현재 상태 분석

#### 기존 프로필 모달 파일 (3개, 총 1,785줄)

| 파일 | 줄 수 | 용도 | 사용처 |
|------|-------|------|--------|
| `pet_profile_modal.dart` | 783줄 | 반려동물 프로필 | 채팅 상세, 보호자 모달 내부 |
| `guardian_profile_modal.dart` | 512줄 | 보호자 프로필 | 채팅 상세, 마켓/알바 상세, 소모임 멤버 |
| `group_profile_modal.dart` | 490줄 | 소모임 프로필 | 채팅 상세 (그룹 채팅) |

#### 공통 패턴 분석

```
┌─────────────────────────────────────┐
│ BottomSheetHandle                   │
├─────────────────────────────────────┤
│ 헤더 (타이틀)                        │
├─────────────────────────────────────┤
│ 본문 (SingleChildScrollView)        │
│ ├─ 기본 정보 (아바타 + 이름 + 부가정보) │
│ ├─ 섹션 1 (사진/인증배지/태그)        │
│ ├─ 섹션 2 (소개)                    │
│ └─ 섹션 3 (관련 정보)               │
├─────────────────────────────────────┤
│ 하단 버튼 (선택적)                   │
└─────────────────────────────────────┘
```

#### 중복 코드 패턴

| 패턴 | Pet | Guardian | Group | 중복 줄 수 |
|------|-----|----------|-------|-----------|
| 바텀시트 컨테이너 | ✅ | ✅ | ✅ | ~30줄 × 3 |
| 기본 정보 Row (아바타 + 텍스트) | ✅ | ✅ | ✅ | ~40줄 × 3 |
| 섹션 타이틀 스타일 | ✅ | ✅ | ✅ | ~10줄 × 10+ |
| 소개 섹션 | ✅ | - | ✅ | ~25줄 × 2 |
| 리스트 아이템 (가로 스크롤) | ✅ | ✅ | ✅ | ~50줄 × 3 |
| 스택 매니저 로직 | ✅ | ✅ | ✅ | ~15줄 × 3 |

### 공통화 방향: 빌딩 블록 추출

**핵심:** 모달 자체를 통합하지 않고, **재사용 가능한 빌딩 블록**을 추출

```dart
// 1. 프로필 모달 기본 컨테이너
class ProfileModalContainer extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomButton;
  final double maxHeightRatio;
}

// 2. 프로필 헤더 (아바타 + 이름 + 부가정보)
class ProfileModalHeader extends StatelessWidget {
  final Widget avatar;
  final String name;
  final Widget? badge;
  final Widget? subtitle;
  final Widget? trailing;
}

// 3. 프로필 섹션 (타이틀 + 컨텐츠)
class ProfileModalSection extends StatelessWidget {
  final String title;
  final String? count;
  final Widget content;
}

// 4. 가로 스크롤 아이템 리스트
class ProfileModalHorizontalList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final double height;
  final double itemWidth;
}

// 5. 소개 박스
class ProfileModalDescriptionBox extends StatelessWidget {
  final String text;
}

// 6. 상세 정보 행
class ProfileModalDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
}
```

### 개발 계획 ✅ 완료

> 완료일: 2026-01-18

| 단계 | 작업 내용 | 상태 |
|------|----------|------|
| 1 | 공통 빌딩 블록 생성 (`profile_modal_components.dart`) | ✅ 완료 |
| 2 | `guardian_profile_modal.dart` 리팩토링 | ✅ 완료 |
| 3 | `group_profile_modal.dart` 리팩토링 | ✅ 완료 |
| 4 | `pet_profile_modal.dart` 리팩토링 | ✅ 완료 |
| 5 | 전체 테스트 및 검증 | ✅ 완료 |

### 구현된 공통 컴포넌트 (`profile_modal_components.dart`)

| 컴포넌트 | 용도 |
|---------|------|
| `ProfileModalContainer` | 모달 기본 컨테이너 (타이틀, 본문, 하단버튼) |
| `ProfileModalHeader` | 프로필 헤더 (아바타 + 이름 + 배지 + 부제목) |
| `ProfileModalSection` | 섹션 (타이틀 + 카운트 + 컨텐츠) |
| `ProfileModalHorizontalList<T>` | 가로 스크롤 리스트 |
| `ProfileModalDescriptionBox` | 소개/설명 박스 |
| `ProfileModalDetailRow` | 상세 정보 행 (아이콘 + 라벨 + 값) |
| `ProfileModalDetailsBox` | 상세 정보 컨테이너 |
| `ProfileModalAvatar` | 프로필 아바타 (원형, 이미지/아이콘) |
| `ProfileModalItemCard` | 가로 스크롤용 아이템 카드 |
| `ProfileModalActivityItem` | 활동 기록 아이템 |
| `showStackedProfileModal()` | 스택 방식 모달 표시 헬퍼 |

### 실제 효과

| 항목 | Before | After | 절감 |
|------|--------|-------|------|
| 개별 모달 코드 | 1,785줄 | 1,261줄 | **524줄 (29%)** |
| 공통 컴포넌트 | 0줄 | 580줄 | 재사용 가능 |
| 스타일 일관성 | 낮음 | 높음 | ✅ |
| 유지보수성 | 중간 | 높음 | ✅ |

### 변경된 파일

| 파일 | Before | After | 변경 내용 |
|------|--------|-------|----------|
| `pet_profile_modal.dart` | 783줄 | 645줄 | 공통 컴포넌트 적용 |
| `guardian_profile_modal.dart` | 512줄 | 318줄 | 공통 컴포넌트 적용 |
| `group_profile_modal.dart` | 490줄 | 298줄 | 공통 컴포넌트 적용 |
| `profile_modal_components.dart` | - | 580줄 | **신규 생성** |

### 호출부 영향 (변경 없음)

기존 `showPetProfileModal`, `showGuardianProfileModal`, `showGroupProfileModal` 함수 시그니처 유지로 호출부 수정 불필요

| 사용 파일 | 상태 |
|----------|------|
| `chat_detail_screen.dart` | ✅ 변경 없음 |
| `chat_list_screen.dart` | ✅ 변경 없음 |
| `pet_detail_screen.dart` | ✅ 변경 없음 |
| `product_detail_screen.dart` | ✅ 변경 없음 |
| `job_detail_screen.dart` | ✅ 변경 없음 |

---

## 📊 Phase 13: 좋아요 컴포넌트 & 빈 상태 UI 공통화

> 완료일: 2026-01-18
> 목적: 좋아요 관련 UI 통일 및 빈 상태 UI 공통화

### 1. 좋아요 컴포넌트 재설계 (`info_badge.dart`)

#### 문제점
- 좋아요 버튼/배지가 화면마다 다른 디자인
- 이모지(`❤️`) 사용으로 일관성 부족
- 클릭 가능/불가능 구분 어려움

#### 구현된 컴포넌트

| 컴포넌트 | 용도 | 디자인 |
|---------|------|--------|
| `LikeCountText` | 정보 표시용 (클릭 불가) | 회색 아이콘+숫자, 배경 없음 |
| `LikeButton` | 클릭 가능한 좋아요 버튼 | dating 색상, 배경 없음 |
| `LikeOverlayBadge` | 이미지 오버레이용 | 반투명 검정 배경, 흰색 텍스트 |

#### 적용 대상

| 파일 | 위치 | 사용 컴포넌트 |
|------|------|-------------|
| `pet_detail_screen.dart` | 이미지 헤더 | `LikeOverlayBadge` |
| `pet_detail_screen.dart` | 하단 버튼 | `LikeButton` |
| `pet_profile_modal.dart` | 헤더 우측 | `LikeButton` |
| `guardian_profile_modal.dart` | 반려동물 카드 | `LikeCountText` |
| `mingrr_image_header.dart` | 하위 호환성 | `typedef LikeBadge = LikeOverlayBadge` |

#### 코드 예시

```dart
// 정보 표시용 (클릭 불가)
LikeCountText(count: 42, size: InfoBadgeSize.small)

// 클릭 가능한 버튼 (배경 없음)
LikeButton(
  count: 42,
  isLiked: true,
  onTap: () => _toggleLike(),
  size: InfoBadgeSize.large,
)

// 이미지 오버레이용 (반투명 배경)
LikeOverlayBadge(
  count: 42,
  isLiked: false,
  onTap: () => _toggleLike(),
)
```

### 2. 빈 상태 UI 공통화 (`common_widgets.dart`)

#### 문제점
- 데이터 없을 때 영역이 사라지는 패턴
- 사용자에게 "없음" 상태 미표시
- UI 일관성 부족

#### 구현된 컴포넌트

| 컴포넌트 | 용도 | 높이 |
|---------|------|------|
| `MingrrEmptyState` | 전체 화면 빈 상태 | 화면 전체 |
| `MingrrEmptySection` | 섹션 내 빈 상태 | 60~80px |

#### 적용 대상

| 파일 | 위치 | 메시지 |
|------|------|--------|
| `pet_profile_modal.dart` | 사진 갤러리 | "등록된 사진이 없어요" |
| `trait_badge.dart` | 성격&특성 섹션 | "등록된 특성이 없어요" |

#### 코드 예시

```dart
// 섹션 내 빈 상태
const MingrrEmptySection(
  icon: Icons.photo_library_outlined,
  message: '등록된 사진이 없어요',
  height: 80,
)

// TraitSection에서 빈 상태 표시
TraitSection(
  traits: [],
  showEmptyState: true, // 빈 상태 표시 옵션
)
```

### 3. ProfileModalItemCard 개선

#### 변경 사항
- `subtitle` (String) → `subtitleWidget` (Widget)
- 커스텀 위젯 직접 전달 가능

#### 코드 예시

```dart
ProfileModalItemCard(
  avatar: ProfileModalAvatar(...),
  title: pet.name,
  subtitleWidget: LikeCountText(count: pet.likeCount, size: InfoBadgeSize.small),
  onTap: () => _openPetProfile(context, pet),
)
```

### 4. 데이터 누락 패턴 수정

#### 수정된 파일

| 파일 | 수정 내용 |
|------|----------|
| `pet_detail_screen.dart` | `_openPetProfileModal`에서 `guardianInfo` 전달 |

#### 검증된 파일 (이미 정상)

| 파일 | 상태 |
|------|------|
| `chat_detail_screen.dart` | ✅ `guardianInfo` 전달됨 |
| `chat_list_screen.dart` | ✅ `pets` 정보 전달됨 |
| `guardian_profile_modal.dart` | ✅ `guardianInfo` 전달됨 |

### 5. 실제 효과

| 항목 | Before | After |
|------|--------|-------|
| 좋아요 디자인 통일성 | 낮음 | 높음 ✅ |
| 빈 상태 UI 일관성 | 낮음 | 높음 ✅ |
| 이모지 사용 | 있음 | 제거 ✅ |
| 컴포넌트 재사용성 | 낮음 | 높음 ✅ |

---

## 📊 Phase 4 상세: 탭 화면 레이아웃 통일

> 완료일: 2026-01-18
> 목적: 탭 컴포넌트 명칭 통일 및 서브 화면 탭 바 공통화

### 변경 사항

#### 1. 명칭 리네이밍 (하위 호환성 없이 깔끔하게 정리)

| Before | After | 설명 |
|--------|-------|------|
| `TopNavTab` | `MingrrTabItem` | 탭 아이템 정의 클래스 |
| `PillTabBar` | `MingrrMainTabBar` | 메인 화면용 탭 바 (Pill 형태) |
| (없음) | `MingrrSubTabBar` | 서브 화면용 탭 바 (밑줄 인디케이터) |

#### 2. 구현된 컴포넌트

| 컴포넌트 | 용도 | 특징 |
|---------|------|------|
| `MingrrTabItem` | 탭 아이템 정의 | label, emoji, icon, color |
| `MingrrMainTabBar` | 메인 화면 탭 바 | Pill 형태, 아이콘+라벨, 피처 컬러 배경 |
| `MingrrSubTabBar` | 서브 화면 탭 바 | 밑줄 인디케이터, controller/isScrollable 지원, PreferredSizeWidget 구현 |
| `MingrrSubTabBarDelegate` | Sliver용 탭 바 | SliverPersistentHeader에서 사용, 스크롤 시 탭바 고정 |

#### 3. 적용 화면

**MingrrMainTabBar (4개 화면):**
- `dating_screen.dart` - 추천친구 / 근처 검색 / 교배찾기
- `marketplace_screen.dart` - 판매 / 나눔 / 알바
- `chat_list_screen.dart` - 데이팅 / 마켓 / 소모임
- `social_screen.dart` - 커뮤니티 / 소모임

**MingrrSubTabBar (5개 화면):**
- `activity_history_screen.dart` - 매칭 / 거래 / 모임 (DefaultTabController)
- `transaction_history_screen.dart` - 판매 / 구매 (DefaultTabController)
- `wishlist_screen.dart` - 상품 / 반려동물 (DefaultTabController)
- `notification_screen.dart` - 전체 / 데이팅 / 채팅 / 마켓 / 소모임 (AppBar.bottom, isScrollable)
- `group_detail_screen.dart` - 정보 / 멤버 / 일정 (MingrrSubTabBarDelegate 사용)

### 코드 예시

**MingrrMainTabBar 사용:**
```dart
final tabs = [
  MingrrTabItem(label: '추천친구', icon: Icons.auto_awesome, color: features.dating),
  MingrrTabItem(label: '근처 검색', icon: Icons.location_on, color: features.dating),
  MingrrTabItem(label: '교배찾기', icon: Icons.pets, color: features.dating),
];

MingrrMainTabBar(
  tabs: tabs,
  selectedIndex: selectedTab,
  onTabSelected: (index) => ref.read(_selectedTabProvider.notifier).state = index,
)
```

**MingrrSubTabBar 사용 (DefaultTabController):**
```dart
body: DefaultTabController(
  length: 3,
  child: Column(
    children: [
      const MingrrSubTabBar(tabs: ['매칭', '거래', '모임']),
      Expanded(
        child: TabBarView(children: [...]),
      ),
    ],
  ),
)
```

**MingrrSubTabBar 사용 (AppBar.bottom):**
```dart
appBar: AppBar(
  title: Text('알림'),
  bottom: MingrrSubTabBar(
    tabs: _tabLabels,
    controller: _tabController,
    isScrollable: true,
  ),
),
```

**MingrrSubTabBarDelegate 사용 (SliverPersistentHeader):**
```dart
SliverPersistentHeader(
  pinned: true,
  delegate: MingrrSubTabBarDelegate(
    tabs: const ['정보', '멤버', '일정'],
    controller: _tabController,
    accentColor: accentColor,
  ),
),
```

### 실제 효과

| 항목 | Before | After |
|------|--------|-------|
| 공통화 범위 | 7/9 화면 (78%) | **9/9 화면 (100%)** |
| 명칭 통일성 | 불일치 (`PillTabBar`, `TopNavTab`) | 통일 (`MingrrMainTabBar`, `MingrrSubTabBar`) |
| 코드 절감 | - | ~70줄 (서브 화면 5개 + _TabBarDelegate 삭제) |
| TabBar 스타일 | 5곳 개별 정의 | 1곳 중앙 관리 |
| 유지보수 | 각 화면 개별 수정 | 공통 컴포넌트 1곳 수정 |

### 변경된 파일 (10개)

| 파일 | 변경 내용 |
|------|----------|
| `top_navigation.dart` | 명칭 리네이밍 + `MingrrSubTabBar` 확장 + `MingrrSubTabBarDelegate` 추가 |
| `dating_screen.dart` | `TopNavTab` → `MingrrTabItem`, `PillTabBar` → `MingrrMainTabBar` |
| `marketplace_screen.dart` | 동일 |
| `chat_list_screen.dart` | 동일 |
| `social_screen.dart` | 동일 |
| `activity_history_screen.dart` | `MingrrSubTabBar` 적용 |
| `transaction_history_screen.dart` | `MingrrSubTabBar` 적용 |
| `wishlist_screen.dart` | `MingrrSubTabBar` 적용 |
| `notification_screen.dart` | `MingrrSubTabBar` 적용 (AppBar.bottom, isScrollable) |
| `group_detail_screen.dart` | `MingrrSubTabBarDelegate` 적용, `_TabBarDelegate` 삭제 |

---

## 📊 Phase 5 상세: 데이팅 카드 디자인 통일 및 상세화면 개선

> 작성일: 2026-01-18
> 완료일: 2026-01-18
> 목적: 데이팅 3개 탭(추천친구/근처검색/교배찾기) 카드 디자인 통일 및 상세화면 빈 상태 UI 개선
> 상태: ✅ 완료

---

### 1. 현재 문제점 분석

#### 1-1. 카드 디자인 불일치

| 탭 | 카드 형태 | 레이아웃 | 표시 정보 | 문제점 |
|---|---------|---------|----------|--------|
| **추천친구** | 대형 카드 (280px) | 전체 이미지 + 하단 오버레이 | 성별, 궁합점수, 이름, 나이, 품종, 거리, 특성 | ✅ 가장 완성도 높음 |
| **근처검색** | 그리드 카드 | 상단 이미지 + 하단 정보 | 거리, 궁합점수, 이름, 품종/나이, 특성 | ⚠️ 정보 배치 불일치 |
| **교배찾기** | 가로형 카드 | 좌측 이미지 + 우측 정보 | 성별, 이름, 거리, 품종/나이, 조건태그, 버튼 | ⚠️ 디자인 스타일 상이 |

#### 1-2. 상세화면 빈 상태 UI 부재

| 영역 | 현재 상태 | 문제점 |
|-----|---------|--------|
| **이미지 헤더** | 이미지 없으면 빈 공간 | 사용자에게 오류처럼 보임 |
| **거리 정보** | 거리 0이면 "0.0km" 표시 | 위치 정보 없음 안내 필요 |
| **궁합 점수** | 점수 없으면 배지 미표시 | 궁합 정보 없음 안내 필요 |

---

### 2. 리팩토링 계획

#### Phase 5-1: 공통 카드 컴포넌트 설계 (우선순위: 높음)

**목표**: 3개 탭에서 사용할 수 있는 통일된 카드 컴포넌트 설계

**새로운 컴포넌트:**

| 컴포넌트 | 용도 | 파일 |
|---------|------|------|
| `MingrrDatingCard` | 데이팅 공통 카드 (추천/근처) | `dating_card.dart` |
| `MingrrBreedingCard` | 교배찾기 전용 카드 | `dating_card.dart` |
| `DatingCardBadge` | 카드 내 배지 (성별, 거리, 궁합) | `dating_card.dart` |

**통일할 디자인 요소:**
- 카드 모서리 반경: `AppSizes.radiusL` (16px)
- 그림자: `BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)`
- 이미지 없을 때: `DefaultPetIcon` + 배경 그라데이션
- 성별 배지: 좌상단 고정
- 거리 배지: 우상단 고정

#### Phase 5-2: 카드 정보 구조 통일 (우선순위: 높음)

**공통 표시 정보 (모든 탭):**
1. **필수**: 이름, 품종, 나이, 성별
2. **선택**: 거리, 궁합점수, 특성태그

**탭별 추가 정보:**
| 탭 | 추가 정보 |
|---|----------|
| 추천친구 | 궁합점수 (필수) |
| 근처검색 | 거리 (필수), 궁합점수 (선택) |
| 교배찾기 | 거리 (필수), 교배조건태그, 교배신청버튼 |

#### Phase 5-3: 상세화면 빈 상태 UI 개선 (우선순위: 높음)

**이미지 헤더 개선:**
```dart
// 이미지 없을 때
MingrrImageHeader(
  imageUrls: [],  // 빈 배열
  emptyStateWidget: _buildEmptyImageState(),  // 신규 파라미터
)

Widget _buildEmptyImageState() {
  return Container(
    color: context.features.datingContainer,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DefaultPetIcon(size: 80),
        SizedBox(height: 12),
        Text('사진이 없어요', style: TextStyle(color: Colors.white70)),
      ],
    ),
  );
}
```

**거리/궁합 정보 빈 상태:**
```dart
// 거리 정보 없을 때
bottomLeftOverlay: distance > 0
    ? DistanceBadge(distanceKm: distanceKm)
    : EmptyInfoBadge(icon: Icons.location_off, text: '위치 정보 없음'),

// 궁합 정보 없을 때 (데이팅 탭)
topRightOverlay: matchScore != null
    ? ImageHeaderMatchBadge(score: matchScore)
    : EmptyInfoBadge(icon: Icons.auto_awesome_outlined, text: '궁합 정보 없음'),
```

**새로운 컴포넌트:**
| 컴포넌트 | 용도 | 파일 |
|---------|------|------|
| `EmptyInfoBadge` | 빈 상태 안내 배지 | `info_badge.dart` |

---

### 3. 상세 작업 목록

#### 3-1. 공통 컴포넌트 생성

| 순서 | 작업 | 파일 | 예상 시간 |
|-----|------|------|----------|
| 1 | `EmptyInfoBadge` 컴포넌트 생성 | `info_badge.dart` | 30분 |
| 2 | `MingrrImageHeader`에 `emptyStateWidget` 파라미터 추가 | `mingrr_image_header.dart` | 30분 |
| 3 | `MingrrDatingCard` 공통 카드 컴포넌트 생성 | `dating_card.dart` (신규) | 2시간 |
| 4 | `MingrrBreedingCard` 교배찾기 카드 컴포넌트 생성 | `dating_card.dart` | 1시간 |

#### 3-2. 화면 적용

| 순서 | 작업 | 파일 | 예상 시간 |
|-----|------|------|----------|
| 5 | 추천친구 탭 `MingrrDatingCard` 적용 | `dating_screen.dart` | 30분 |
| 6 | 근처검색 탭 `MingrrDatingCard` 적용 | `dating_screen.dart` | 30분 |
| 7 | 교배찾기 탭 `MingrrBreedingCard` 적용 | `dating_screen.dart` | 30분 |
| 8 | 상세화면 빈 상태 UI 적용 | `pet_detail_screen.dart` | 1시간 |

#### 3-3. 정리 및 테스트

| 순서 | 작업 | 예상 시간 |
|-----|------|----------|
| 9 | 기존 카드 빌드 메서드 삭제 | 30분 |
| 10 | 전체 테스트 및 검증 | 1시간 |

**총 예상 시간: 8시간**

---

### 4. 디자인 가이드

#### 4-1. 카드 디자인 통일 원칙

**추천친구 카드 (대형):**
```
┌─────────────────────────────────┐
│ [성별]              [궁합 90%] │  ← 상단 배지
│                                 │
│         (이미지 영역)           │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 이름 · 나이                 │ │  ← 하단 오버레이
│ │ 품종 · 📍 거리              │ │
│ │ [활발함] [친화적]           │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**근처검색 카드 (그리드):**
```
┌─────────────────┐
│        [거리]  │  ← 상단 배지
│   (이미지)     │
├─────────────────┤
│ [궁합 85%]     │
│ 이름           │
│ 품종 · 나이    │
│ [활발함]       │
└─────────────────┘
```

**교배찾기 카드 (가로형):**
```
┌──────────┬────────────────────────┐
│ [성별]   │ 이름          [거리]  │
│          │ 품종 · 나이           │
│ (이미지) │ [혈통서] [예방접종]   │
│          │ ┌──────────────────┐  │
│          │ │   교배 신청      │  │
│          │ └──────────────────┘  │
└──────────┴────────────────────────┘
```

#### 4-2. 빈 상태 UI 디자인

**이미지 없음:**
```
┌─────────────────────────────────┐
│                                 │
│           🐕 (아이콘)           │
│                                 │
│        "사진이 없어요"          │
│                                 │
└─────────────────────────────────┘
```

**위치 정보 없음:**
```
┌─────────────────┐
│ 📍 위치 정보 없음 │
└─────────────────┘
```

**궁합 정보 없음:**
```
┌─────────────────┐
│ ✨ 궁합 정보 없음 │
└─────────────────┘
```

---

### 5. 예상 효과

| 항목 | Before | After |
|------|--------|-------|
| 카드 디자인 통일성 | 3개 탭 모두 다름 | 공통 디자인 시스템 |
| 코드 중복 | ~300줄 (3개 카드 빌드 메서드) | ~100줄 (공통 컴포넌트) |
| 빈 상태 안내 | 없음 (오류처럼 보임) | 친절한 안내 메시지 |
| 유지보수 | 각 탭 개별 수정 | 공통 컴포넌트 1곳 수정 |

---

### 6. 구현 결과

#### 6-1. 생성된 컴포넌트

| 컴포넌트 | 용도 | 파일 |
|---------|------|------|
| `DatingRecommendCard` | 추천친구 탭용 대형 카드 | `dating_card.dart` |
| `DatingNearbyCard` | 근처검색 탭용 그리드 카드 | `dating_card.dart` |
| `DatingBreedingCard` | 교배찾기 탭용 가로형 카드 | `dating_card.dart` |
| `EmptyInfoBadge` | 빈 상태 안내 배지 | `info_badge.dart` |

#### 6-2. 변경된 파일 (5개)

| 파일 | 변경 내용 |
|------|----------|
| `info_badge.dart` | `EmptyInfoBadge` 컴포넌트 추가 |
| `mingrr_image_header.dart` | `emptyStateWidget` 파라미터 추가 |
| `dating_card.dart` (신규) | `DatingRecommendCard`, `DatingNearbyCard`, `DatingBreedingCard` 생성 |
| `dating_screen.dart` | 3개 카드 빌드 메서드 → 공통 컴포넌트 교체, 더미 데이터용 메서드 삭제 (~200줄 절감) |
| `pet_detail_screen.dart` | 빈 상태 UI 적용 (이미지 없음, 궁합 정보 없음) |

#### 6-3. 실제 효과

| 항목 | Before | After |
|------|--------|-------|
| 카드 디자인 통일성 | 3개 탭 모두 다름 | **공통 디자인 시스템** |
| 코드 중복 | ~350줄 (3개 카드 + 더미 메서드) | **~100줄 (공통 컴포넌트)** |
| 빈 상태 안내 | 없음 (오류처럼 보임) | **친절한 안내 메시지** |
| 유지보수 | 각 탭 개별 수정 | **공통 컴포넌트 1곳 수정** |

---

## 📊 Phase 6 상세: 교배찾기 혈통서 기능 강화

> 작성일: 2026-01-18
> 완료일: 2026-01-18
> 목적: 교배찾기 관련 화면에 혈통서 보유 여부 기능 강화
> 상태: ✅ 완료

---

### 1. 구현 현황

| 영역 | 파일 | 혈통서 관련 필드 | 상태 |
|------|------|-----------------|------|
| **데이터 모델** | `pet_model.dart` | `hasPedigree`, `pedigreeImageUrl` | ✅ 구현됨 |
| **반려동물 편집** | `pet_edit_screen.dart` | 혈통서 유무 입력 | ✅ 구현됨 |
| **교배찾기 카드** | `dating_card.dart` | `hasPedigree` 조건 태그 표시 | ✅ 구현됨 |
| **교배 등록** | `breeding_write_screen.dart` | 혈통서 정보 표시 | ✅ **신규 구현** |
| **교배 상세** | `pet_detail_screen.dart` | 혈통서 배지 표시 | ✅ **신규 구현** |
| **교배찾기 필터** | `dating_screen.dart` | 혈통서 필터 | ✅ **신규 구현** |

---

### 2. 구현 결과

#### Phase 6-1: 교배찾기 필터에 혈통서 필터 추가 ✅

```dart
// dating_screen.dart
final _breedingPedigreeFilterProvider = StateProvider<bool?>((ref) => null);

// 필터 UI - 3행에 추가
MingrrFilterRow(
  title: '혈통서',
  children: [
    MingrrFilterChip(label: '전체', isSelected: filter == null),
    MingrrFilterChip(label: '혈통서 보유', icon: Icons.verified, isSelected: filter == true),
  ],
),

// 필터 적용 로직
if (pedigreeFilter == true) {
  filteredPets = filteredPets.where((p) => p.pet.hasPedigree).toList();
}
```

#### Phase 6-2: 교배 등록 화면에 혈통서 정보 표시 ✅

- 선택된 반려동물의 혈통서 보유 여부 자동 표시
- 혈통서 보유 시: 핑크 배경 + "혈통서 보유" 메시지
- 혈통서 미보유 시: 회색 배경 + "반려동물 정보에서 혈통서를 등록할 수 있어요" 안내

#### Phase 6-3: 교배 상세 화면에 혈통서 배지 표시 ✅

- 기본 정보 섹션에서 이름 옆에 "혈통서" 배지 표시
- `widget.isBreeding && pet.hasPedigree` 조건으로 교배찾기에서만 표시

---

### 3. 변경된 파일 (5개)

| 파일 | 변경 내용 |
|------|----------|
| `dating_screen.dart` | `_breedingPedigreeFilterProvider` 추가, `_buildPedigreeFilters()` 메서드 추가, 필터 적용 로직 추가 |
| `breeding_write_screen.dart` | `_buildPedigreeInfo()` 메서드 추가, 선택된 강아지 혈통서 정보 표시 |
| `pet_detail_screen.dart` | `_buildPedigreeBadge()` 메서드 추가, 혈통서 유무에 따른 배지 표시 (있음/없음) |
| `dating_card.dart` | `DatingBreedingCard`에 `_buildPedigreeBadge()` 추가, 혈통서 유무 항상 표시 |
| `pet_selector_card.dart` | `_buildPedigreeBadge()` 추가, `LikeCountText` 공통 컴포넌트 적용 |

### 4. 추가 개선 사항 (Phase 6 보완)

| 화면 | 개선 내용 |
|------|----------|
| **교배 상세** | 혈통서 없을 때도 "혈통서 없음" 배지 표시 |
| **교배찾기 리스트카드** | 혈통서 유무 항상 표시 (있음: 핑크, 없음: 회색) |
| **강아지 선택 바텀시트** | 혈통서 유무 배지 + `LikeCountText` 공통 컴포넌트 적용 |
| **교배할 강아지 섹션** | `PetSelectorCard` 공통 사용으로 자동 적용 |

### 5. PedigreeBadge 공통 컴포넌트화 ✅

#### 생성된 컴포넌트

| 컴포넌트 | 파일 | 용도 |
|---------|------|------|
| `PedigreeBadge` | `info_badge.dart` | 혈통서 유무 배지 (3곳 → 1곳 관리) |

#### 컴포넌트 사양

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `hasPedigree` | `bool` (필수) | 혈통서 보유 여부 |
| `size` | `InfoBadgeSize` | 크기 (small/medium/large) |
| `accentColor` | `Color?` | 커스텀 색상 (기본: dating 색상) |

#### 디자인

| 상태 | 배경색 | 아이콘 | 텍스트 |
|------|--------|--------|--------|
| **혈통서 보유** | 핑크 10% | `Icons.verified` | "혈통서" |
| **혈통서 없음** | 회색 | `Icons.block` | "혈통서 없음" |

#### 적용된 파일 (3개 → 공통 컴포넌트 사용)

| 파일 | 변경 내용 |
|------|----------|
| `pet_detail_screen.dart` | `_buildPedigreeBadge()` 삭제 → `PedigreeBadge` 사용 |
| `dating_card.dart` | `_buildPedigreeBadge()` 삭제 → `PedigreeBadge` 사용 |
| `pet_selector_card.dart` | `_buildPedigreeBadge()` 삭제 → `PedigreeBadge` 사용 |

#### 효과

| 항목 | Before | After |
|------|--------|-------|
| 코드 중복 | 3곳에 동일 코드 (~90줄) | **1곳 (~30줄)** |
| 유지보수 | 3곳 수정 필요 | **1곳 수정** |
| 디자인 통일성 | 수동 관리 | **자동 보장** |

---

## Phase 7: 로딩 상태 공통화 ✅ 완료

### 1. 문제점 및 해결

#### 문제점
- **데이터 로딩 중 빈 상태 표시**: 거리 필터 50km 설정 시 데이터 로딩이 오래 걸리면 "아직 데이터가 없어요" 메시지가 먼저 표시됨
- **로딩 상태 미표시**: `AsyncValue`의 `loading` 상태를 제대로 처리하지 않는 화면 존재
- **일관성 부족**: 화면마다 로딩 UI가 다르거나 누락됨

#### 해결 방안
1. **Provider 수정**: `filteredBreedingPetsProvider`, `filteredDatingPetsProvider`, `filteredProductsProvider`가 `AsyncValue`를 유지하도록 수정
2. **MingrrLoadingState 개선**: `type`, `message`, `subMessage` 파라미터 추가로 기능별 색상 및 메시지 지원
3. **전체 화면 적용**: 모든 화면에서 `AsyncValue.when()`의 `loading` 상태에 개선된 로딩 UI 적용

#### 로딩 컴포넌트 현황 (`loading_widgets.dart` + `common_widgets.dart`)

| 컴포넌트 | 용도 | 현황 |
|---------|------|------|
| `MingrrLoadingDialog` | 팝업 형태 로딩 (작업 중 화면 차단) | ✅ 구현됨 |
| `MingrrLoadingOverlay` | 화면 내 오버레이 로딩 | ✅ 구현됨 |
| `MingrrLoadingIndicator` | 인라인 로딩 인디케이터 | ✅ 구현됨 |
| `MingrrFullScreenLoading` | 전체 화면 로딩 | ✅ 구현됨 |
| `MingrrLoadingState` | Riverpod AsyncValue용 로딩 | ✅ **개선됨** (type, message 지원) |

#### 로딩 필요 화면 분석 (24개 파일)

| 카테고리 | 파일 | 로딩 필요 상황 |
|---------|------|---------------|
| **데이팅** | `dating_screen.dart` | 추천/근처/교배 리스트 로딩 |
| **데이팅** | `pet_detail_screen.dart` | 반려동물 상세 정보 로딩 |
| **데이팅** | `breeding_write_screen.dart` | 내 반려동물 목록 로딩 |
| **채팅** | `chat_list_screen.dart` | 채팅 목록 로딩 |
| **채팅** | `chat_detail_screen.dart` | 메시지 목록 로딩 |
| **마켓** | `marketplace_screen.dart` | 상품 목록 로딩 |
| **마켓** | `product_detail_screen.dart` | 상품 상세 로딩 |
| **커뮤니티** | `community_screen.dart` | 게시글 목록 로딩 |
| **커뮤니티** | `community_detail_screen.dart` | 게시글 상세 로딩 |
| **소모임** | `group_list_screen.dart` | 소모임 목록 로딩 |
| **소모임** | `group_detail_screen.dart` | 소모임 상세 로딩 |
| **건강** | `health_screen.dart` | 건강 기록 로딩 |
| **프로필** | `profile_screen.dart` | 사용자/반려동물 정보 로딩 |
| **프로필** | `activity_history_screen.dart` | 활동 내역 로딩 |
| **프로필** | `transaction_history_screen.dart` | 거래 내역 로딩 |
| **프로필** | `wishlist_screen.dart` | 찜 목록 로딩 |
| **알림** | `notification_screen.dart` | 알림 목록 로딩 |
| **산책** | `walk_screen.dart` | 지도/산책 데이터 로딩 |
| **홈** | `home_screen.dart` | 대시보드 데이터 로딩 |

---

### 2. 개선 방안

#### 2-1. AsyncValue 래퍼 컴포넌트 생성

```dart
/// Riverpod AsyncValue를 위한 공통 래퍼
class MingrrAsyncBuilder<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;
  final MingrrLoadingType loadingType;
  final String? loadingMessage;
  final bool showLoadingOnRefresh; // 새로고침 시에도 로딩 표시

  const MingrrAsyncBuilder({
    required this.asyncValue,
    required this.builder,
    this.loading,
    this.errorBuilder,
    this.loadingType = MingrrLoadingType.primary,
    this.loadingMessage,
    this.showLoadingOnRefresh = false,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: builder,
      loading: () => loading ?? MingrrLoadingState(
        type: loadingType,
        message: loadingMessage,
      ),
      error: (e, s) => errorBuilder?.call(e, s) ?? MingrrErrorState(error: e),
    );
  }
}
```

#### 2-2. 리스트 로딩 컴포넌트 생성

```dart
/// 리스트 데이터 로딩용 컴포넌트
class MingrrListBuilder<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncValue;
  final Widget Function(List<T> data) builder;
  final Widget? emptyWidget;
  final MingrrLoadingType loadingType;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptySubtitle;
  final IconData? emptyIcon;

  const MingrrListBuilder({
    required this.asyncValue,
    required this.builder,
    this.emptyWidget,
    this.loadingType = MingrrLoadingType.primary,
    this.loadingMessage,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        if (data.isEmpty) {
          return emptyWidget ?? MingrrEmptyState(
            icon: emptyIcon ?? Icons.inbox,
            title: emptyTitle ?? '데이터가 없어요',
            subtitle: emptySubtitle,
          );
        }
        return builder(data);
      },
      loading: () => MingrrLoadingState(
        type: loadingType,
        message: loadingMessage,
      ),
      error: (e, s) => MingrrErrorState(error: e),
    );
  }
}
```

#### 2-3. 스켈레톤 로딩 컴포넌트 생성

```dart
/// 스켈레톤 로딩 (카드/리스트 형태)
class MingrrSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final SkeletonType type;
  final double? height;

  const MingrrSkeletonLoader({
    this.itemCount = 3,
    this.type = SkeletonType.card,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (_, __) => _buildSkeletonItem(context),
    );
  }
}

enum SkeletonType { card, listTile, grid }
```

---

### 2. 구현 완료 내역

#### Provider 수정 (AsyncValue 유지)

| Provider | 파일 | 변경 내용 |
|----------|------|----------|
| `filteredBreedingPetsProvider` | `dating_provider.dart` | `List<PetWithDistance>` → `AsyncValue<List<PetWithDistance>>` |
| `filteredDatingPetsProvider` | `dating_provider.dart` | `List<PetWithDistance>` → `AsyncValue<List<PetWithDistance>>` |
| `filteredProductsProvider` | `marketplace_provider.dart` | `List<ProductWithDistance>` → `AsyncValue<List<ProductWithDistance>>` |

#### MingrrLoadingState 개선 (`common_widgets.dart`)

```dart
class MingrrLoadingState extends StatelessWidget {
  final String? message;
  final String? subMessage;
  final Color? color;
  final MingrrLoadingType type; // 기능별 색상 자동 적용

  // type: primary, walk, dating, market, community, chat, health, success
}
```

#### 적용된 화면 (18개 파일)

| 카테고리 | 파일 | 로딩 메시지 |
|---------|------|------------|
| **데이팅** | `dating_screen.dart` | "궁합 맞는 친구를 찾고 있어요", "근처 반려동물을 찾고 있어요", "교배 가능한 반려동물을 찾고 있어요" |
| **마켓** | `marketplace_screen.dart` | "판매 상품을 불러오고 있어요", "나눔 상품을 불러오고 있어요", "알바 정보를 불러오고 있어요" |
| **커뮤니티** | `community_screen.dart` | "게시글을 불러오고 있어요" |
| **채팅** | `chat_list_screen.dart` | "채팅 목록을 불러오고 있어요" |
| **건강** | `health_screen.dart` | "건강 정보를 불러오고 있어요" (9곳) |
| **프로필** | `profile_screen.dart` | "반려동물 정보를 불러오고 있어요" |
| **프로필** | `wishlist_screen.dart` | "찜 목록을 불러오고 있어요" |
| **프로필** | `received_dating_requests_screen.dart` | "받은 신청을 불러오고 있어요" |
| **프로필** | `transaction_history_screen.dart` | "거래 내역을 불러오고 있어요" |
| **프로필** | `activity_history_screen.dart` | "활동 내역을 불러오고 있어요" |
| **알림** | `notification_screen.dart` | "알림을 불러오고 있어요" |

---

### 3. 효과

| 항목 | Before | After |
|------|--------|-------|
| **사용자 경험** | 빈 화면 → 데이터 표시 | **로딩 → 데이터 표시** |
| **로딩 UI** | 단순 스피너 | **기능별 색상 + 메시지** |
| **디자인 통일성** | 화면마다 다름 | **일관된 로딩 UI** |
| **유지보수** | 개별 처리 | **공통 컴포넌트 사용** |

---

## Phase 8: 로딩 타임아웃 처리 ✅ 완료

### 1. 문제점 및 해결

#### 문제점
- **무한 로딩**: 네트워크 느림/서버 응답 지연 시 무한 로딩
- **사용자 액션 불가**: 재시도 방법 없음
- **앱 멈춤 인식**: 사용자가 앱이 멈춘 것으로 인식

#### 해결 방안
- `MingrrLoadingState`를 `StatefulWidget`으로 변경
- `timeout` 파라미터로 타임아웃 시간 지정 (기본 15초)
- `onRetry` 콜백으로 재시도 버튼 표시

### 2. 구현 내역

#### MingrrLoadingState 개선 (`common_widgets.dart`)

```dart
class MingrrLoadingState extends StatefulWidget {
  final String? message;
  final String? subMessage;
  final MingrrLoadingType type;
  final Duration? timeout;        // 타임아웃 시간
  final VoidCallback? onRetry;    // 재시도 콜백
  final String? retryButtonText;  // 재시도 버튼 텍스트
}
```

#### 타임아웃 UI

| 상태 | UI |
|------|-----|
| **로딩 중** | 스피너 + 메시지 |
| **타임아웃** | ⏳ 아이콘 + "로딩이 오래 걸리고 있어요" + "네트워크 상태를 확인해주세요" + 재시도 버튼 |

#### 적용된 화면 (5곳)

| 화면 | Provider | 타임아웃 |
|------|----------|---------|
| 데이팅 - 교배찾기 | `filteredBreedingPetsProvider` | 15초 |
| 데이팅 - 근처 검색 | `filteredDatingPetsProvider` | 15초 |
| 데이팅 - 추천 | `recommendedPetsProvider` | 15초 |
| 마켓 - 상품 목록 | `filteredProductsProvider` | 15초 |
| 마켓 - 알바 목록 | `jobsProvider` | 15초 |

### 3. 효과

| 항목 | Before | After |
|------|--------|-------|
| **사용자 경험** | 무한 로딩 → 앱 종료 | **타임아웃 → 재시도 가능** |
| **에러 복구** | 불가능 | **재시도 버튼으로 복구** |
| **사용자 피드백** | 없음 | **"로딩이 오래 걸리고 있어요" 메시지** |

### 4. 하위 호환성

| 항목 | 처리 방안 |
|------|----------|
| **기존 사용처** | `timeout`, `onRetry` 미지정 시 기존 동작 유지 |
| **const 제거** | `ConsumerStatefulWidget`으로 변경되어 `const` 제거 필요 |

---

## Phase 9: 로딩 타임아웃 개선 ✅ 완료

### 1. 개선 내역

#### 9-1. 타임아웃 시간 상수화 (`app_sizes.dart`)

```dart
// ===== 로딩 타임아웃 =====
static const Duration loadingTimeout = Duration(seconds: 15);
static const Duration loadingTimeoutShort = Duration(seconds: 10);
static const Duration loadingTimeoutLong = Duration(seconds: 30);
```

#### 9-2. 추가 화면 타임아웃 적용 (8곳)

| 화면 | Provider | 타임아웃 |
|------|----------|---------|
| 채팅 목록 (일반) | `userChatRoomsProvider` | 15초 |
| 채팅 목록 (데이팅) | `userChatRoomsProvider` | 15초 |
| 채팅 상세 | `chatMessagesProvider` | 15초 |
| 커뮤니티 목록 | `communityPostsProvider` | 15초 |
| 커뮤니티 상세 | `communityPostDetailProvider` | 15초 |
| 소모임 상세 | `groupDetailProvider` | 15초 |
| 소모임 일정 | `groupSchedulesProvider` | 15초 |

#### 9-3. 네트워크 상태 감지 연동

**새 파일**: `lib/core/providers/network_provider.dart`

```dart
// 네트워크 연결 상태 Provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// 현재 네트워크 연결 여부 Provider
final isConnectedProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => true,
  );
});
```

**MingrrLoadingState 개선**:
- `StatefulWidget` → `ConsumerStatefulWidget` 변경
- 네트워크 연결 끊김 시 자동 감지
- Wi-Fi 끊김 아이콘 + "인터넷 연결이 끊겼어요" 메시지

### 2. 로딩 상태 UI 분기

| 상태 | 아이콘 | 메시지 |
|------|--------|--------|
| **로딩 중** | ⏳ 스피너 | 사용자 지정 메시지 |
| **네트워크 끊김** | 📶 wifi_off | "인터넷 연결이 끊겼어요" |
| **타임아웃** | ⏳ hourglass_empty | "로딩이 오래 걸리고 있어요" |

### 3. 효과

| 항목 | Before | After |
|------|--------|-------|
| **타임아웃 관리** | 하드코딩 (15초) | **상수화 (AppSizes.loadingTimeout)** |
| **적용 범위** | 5곳 | **13곳** |
| **네트워크 감지** | 없음 | **실시간 감지 + 맞춤 메시지** |

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
