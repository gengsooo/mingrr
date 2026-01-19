# 📚 MINGRR 가이드 파일 계획

> 프로젝트 가이드 문서 작성 진행 상황을 추적합니다.  
> 작업 완료 시 `[ ]`를 `[x]`로 변경하세요.

---

## ✅ 작성 완료 (4/33)

| 상태 | 파일명 | 설명 |
|:---:|-------|------|
| [x] | `KKOSUNNAE_GUIDE.md` | 꼬순내지수 (보호자 신뢰도) |
| [x] | `COMPATIBILITY_GUIDE.md` | 반려동물 궁합 알고리즘 |
| [x] | `DATING_GUIDE.md` | 데이팅 메뉴 |
| [x] | `TERMINOLOGY.md` | 용어 정의 |

---

## 📱 기능별 가이드 (0/11)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `MARKETPLACE_GUIDE.md` | 마켓 (중고거래) | `marketplace/`, `marketplace_model.dart` |
| [ ] | `CHAT_GUIDE.md` | 채팅 시스템 | `chat/`, `chat_model.dart`, `chat_service.dart` |
| [ ] | `SOCIAL_GUIDE.md` | 소모임/커뮤니티 | `social/`, `group_model.dart`, `community_post_model.dart` |
| [ ] | `HEALTH_GUIDE.md` | 건강수첩 | `health/`, `health_model.dart` |
| [ ] | `PET_GUIDE.md` | 반려동물 관리 | `pet/`, `pet_model.dart`, `pet_constants.dart` |
| [ ] | `PROFILE_GUIDE.md` | 프로필/설정 | `profile/`, `user_model.dart` |
| [ ] | `WALK_GUIDE.md` | 산책 기능 | `walk/`, `location_service.dart` |
| [ ] | `NOTIFICATION_GUIDE.md` | 알림 시스템 | `notification/`, `notification_model.dart`, `notification_service.dart` |
| [ ] | `RATING_GUIDE.md` | 평가 시스템 | `rating_model.dart`, `rating_service.dart`, `rating_widgets.dart` |
| [ ] | `BREEDING_GUIDE.md` | 교배 시스템 | `breeding_model.dart`, `breeding_write_screen.dart` |
| [ ] | `HOME_GUIDE.md` | 홈 화면/배너 | `home/`, `home_reminder_provider.dart`, `home_reminder_banner.dart` |

---

## 🔧 기술/인프라 가이드 (0/8)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `FIREBASE_GUIDE.md` | Firebase 연동 (Auth, Firestore, Storage) | `firebase_service.dart`, `firestore_service.dart`, `storage_service.dart` |
| [ ] | `DATABASE_GUIDE.md` | Firestore DB 구조/모델 | `models/` (12개 모델), `FIRESTORE_STRUCTURE.md` |
| [ ] | `AUTH_GUIDE.md` | 회원체계/인증 (소셜로그인, 본인인증) | `auth/`, `auth_service.dart`, `user_model.dart` |
| [ ] | `LOCATION_GUIDE.md` | 위치 서비스 (카카오맵, 위치인증) | `location_service.dart`, `geocoding_service.dart`, `location_provider.dart`, `map/` |
| [ ] | `VERIFICATION_GUIDE.md` | 인증 시스템 (본인/위치/동물등록) | `animal_registration_service.dart`, `location_verification_provider.dart`, `verification_badge.dart` |
| [ ] | `IMAGE_GUIDE.md` | 이미지 처리 (업로드, 크롭, 갤러리) | `image_utils.dart`, `image_crop_service.dart`, `image_picker_sheet.dart` |
| [ ] | `RIVERPOD_GUIDE.md` | 상태관리 (Provider 구조) | `providers/` (10개 파일) |
| [ ] | `SHARE_GUIDE.md` | 공유 기능 | `share_service.dart` |

---

## 🎨 디자인/UI 가이드 (0/6)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `THEME_GUIDE.md` | 테마 시스템 (라이트/다크, 색상) | `app_theme.dart`, `feature_colors.dart`, `theme_provider.dart` |
| [ ] | `TYPOGRAPHY_GUIDE.md` | 타이포그래피/폰트 | `app_text_styles.dart`, `Pretendard` 폰트 |
| [ ] | `COMPONENT_GUIDE.md` | 공통 위젯/컴포넌트 | `common_widgets.dart` (104KB), `form_components.dart`, `filter_components.dart` |
| [ ] | `MODAL_GUIDE.md` | 모달/바텀시트 | `mingrr_bottom_sheet.dart`, `guardian_profile_modal.dart`, `pet_profile_modal.dart` |
| [ ] | `ICON_GUIDE.md` | 아이콘/SVG | `svg_icons.dart`, `assets/icons/` |
| [ ] | `SIZING_GUIDE.md` | 사이즈/간격 상수 | `app_sizes.dart` |

---

## 📖 개발 가이드 (0/4)

| 상태 | 파일명 | 설명 | 관련 파일 |
|:---:|-------|------|----------|
| [ ] | `PROJECT_STRUCTURE_GUIDE.md` | 프로젝트 구조/아키텍처 | 전체 폴더 구조 |
| [ ] | `ERROR_HANDLING_GUIDE.md` | 에러 처리/로깅 | `error_handler.dart`, `app_logger.dart` |
| [ ] | `VALIDATION_GUIDE.md` | 입력 검증/폼 | `validators.dart`, `form_strings.dart` |
| [ ] | `SEED_DATA_GUIDE.md` | 테스트 데이터 | `seed_data.dart` (76KB) |

---

## 📊 진행 현황

| 카테고리 | 완료 | 전체 | 진행률 |
|---------|:---:|:---:|:-----:|
| ✅ 작성 완료 | 4 | 4 | 100% |
| 📱 기능별 | 0 | 11 | 0% |
| 🔧 기술/인프라 | 0 | 8 | 0% |
| 🎨 디자인/UI | 0 | 6 | 0% |
| 📖 개발 | 0 | 4 | 0% |
| **총합** | **4** | **33** | **12%** |

---

## 🔥 우선순위 (권장 작업 순서)

### 1순위 - 핵심 인프라
1. `FIREBASE_GUIDE.md` - Firebase 연동 핵심
2. `DATABASE_GUIDE.md` - DB 모델 구조
3. `AUTH_GUIDE.md` - 회원체계

### 2순위 - 주요 기능
4. `MARKETPLACE_GUIDE.md` - 마켓 기능
5. `CHAT_GUIDE.md` - 채팅 시스템
6. `SOCIAL_GUIDE.md` - 소모임
7. `HEALTH_GUIDE.md` - 건강수첩

### 3순위 - 디자인/UI
8. `THEME_GUIDE.md` - 디자인 테마
9. `COMPONENT_GUIDE.md` - 공통 컴포넌트

### 4순위 - 기타
10. `LOCATION_GUIDE.md` - 위치/카카오맵
11. 나머지 가이드들...

---

*최종 업데이트: 2025-01-18*
