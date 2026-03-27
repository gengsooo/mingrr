import 'package:flutter/material.dart';

/// ============================================================
/// MINGRR 앱 아이콘 상수
/// 
/// 모든 아이콘을 한 곳에서 관리하여 일관성 유지
/// - 기능별 아이콘 (filled/outlined)
/// - 앱바/네비게이션 아이콘
/// - 공통 액션 아이콘
/// - 상태 아이콘
/// 
/// 사용법:
/// - AppIcons.dating (채워진 스타일)
/// - AppIcons.datingOutlined (외곽선 스타일)
/// ============================================================
class AppIcons {
  AppIcons._();

  // ===== 기능별 아이콘 (filled) =====
  /// 데이팅 - 하트
  static const IconData dating = Icons.favorite;
  /// 교배 - 가족
  static const IconData breeding = Icons.family_restroom;
  /// 소모임 - 그룹
  static const IconData group = Icons.groups;
  /// 마켓 - 상점
  static const IconData market = Icons.storefront;
  /// 채팅 - 말풍선
  static const IconData chat = Icons.chat_bubble;
  /// 커뮤니티 - 글
  static const IconData community = Icons.article;
  /// 건강 - 의료
  static const IconData health = Icons.medical_services;
  /// 반려동물 - 발바닥
  static const IconData pet = Icons.pets;

  // ===== 기능별 아이콘 (outlined) =====
  static const IconData datingOutlined = Icons.favorite_border;
  static const IconData groupOutlined = Icons.groups_outlined;
  static const IconData marketOutlined = Icons.storefront_outlined;
  static const IconData chatOutlined = Icons.chat_bubble_outline;
  static const IconData communityOutlined = Icons.article_outlined;
  static const IconData healthOutlined = Icons.medical_services_outlined;
  static const IconData petOutlined = Icons.pets_outlined;

  // ===== 앱바/네비게이션 =====
  /// 검색
  static const IconData search = Icons.search;
  /// 알림
  static const IconData notification = Icons.notifications_outlined;
  /// 알림 (채워진)
  static const IconData notificationFilled = Icons.notifications;
  /// 프로필
  static const IconData profile = Icons.person;
  /// 프로필 (외곽선)
  static const IconData profileOutlined = Icons.person_outline;
  /// 설정
  static const IconData settings = Icons.settings;
  /// 설정 (외곽선)
  static const IconData settingsOutlined = Icons.settings_outlined;
  /// 뒤로가기
  static const IconData back = Icons.arrow_back_ios_new;
  /// 닫기
  static const IconData close = Icons.close;
  /// 더보기 (가로)
  static const IconData more = Icons.more_horiz;
  /// 더보기 (세로)
  static const IconData moreVert = Icons.more_vert;
  /// 화살표 (오른쪽)
  static const IconData chevronRight = Icons.chevron_right;
  /// 화살표 (아래)
  static const IconData chevronDown = Icons.keyboard_arrow_down;
  /// 화살표 (왼쪽)
  static const IconData chevronLeft = Icons.chevron_left;
  /// 홈
  static const IconData home = Icons.home;
  /// 홈 (외곽선)
  static const IconData homeOutlined = Icons.home_outlined;
  /// 메뉴 (전체)
  static const IconData menu = Icons.grid_view_rounded;
  /// 메뉴 (전체, 외곽선)
  static const IconData menuOutlined = Icons.grid_view_outlined;

  // ===== 공통 액션 =====
  /// 추가
  static const IconData add = Icons.add;
  /// 수정
  static const IconData edit = Icons.edit;
  /// 수정 (외곽선)
  static const IconData editOutlined = Icons.edit_outlined;
  /// 삭제
  static const IconData delete = Icons.delete;
  /// 삭제 (외곽선)
  static const IconData deleteOutlined = Icons.delete_outline;
  /// 공유
  static const IconData share = Icons.share;
  /// 신고
  static const IconData report = Icons.report_outlined;
  /// 게시글/기사
  static const IconData article = Icons.article;
  /// 좋아요
  static const IconData like = Icons.favorite;
  /// 좋아요 (외곽선)
  static const IconData likeOutlined = Icons.favorite_border;
  /// 카메라
  static const IconData camera = Icons.camera_alt;
  /// 이미지
  static const IconData image = Icons.image;
  /// 이미지 (외곽선)
  static const IconData imageOutlined = Icons.image_outlined;
  /// 사진 추가
  static const IconData addPhoto = Icons.add_photo_alternate;
  /// 영상
  static const IconData video = Icons.videocam;
  /// 재생
  static const IconData play = Icons.play_arrow;
  /// 정지
  static const IconData stop = Icons.stop;
  /// 전체화면
  static const IconData fullscreen = Icons.fullscreen;
  /// 지도 (외곽선)
  static const IconData mapOutlined = Icons.map_outlined;
  /// 거리
  static const IconData distance = Icons.straighten;
  /// 불꽃/칼로리
  static const IconData fire = Icons.local_fire_department;
  /// 새로고침
  static const IconData refresh = Icons.refresh;
  /// 새로고침 (둥근)
  static const IconData refreshRounded = Icons.refresh_rounded;

  // ===== 상태 =====
  /// 빈 상태
  static const IconData empty = Icons.inbox_outlined;
  /// 에러
  static const IconData error = Icons.error_outline;
  /// 성공
  static const IconData success = Icons.check_circle;
  /// 성공 (외곽선)
  static const IconData successOutlined = Icons.check_circle_outline;
  /// 체크
  static const IconData check = Icons.check;
  /// 정보
  static const IconData info = Icons.info_outline;
  /// 경고
  static const IconData warning = Icons.warning_amber_outlined;
  /// 도움말
  static const IconData help = Icons.help_outline;
  /// 인증됨
  static const IconData verified = Icons.verified;
  /// 인증됨 (외곽선)
  static const IconData verifiedOutlined = Icons.verified_user_outlined;
  /// 차단
  static const IconData block = Icons.block;

  // ===== 성별 =====
  /// 남성
  static const IconData male = Icons.male;
  /// 여성
  static const IconData female = Icons.female;

  // ===== 위치 =====
  /// 위치
  static const IconData location = Icons.location_on;
  /// 위치 (외곽선)
  static const IconData locationOutlined = Icons.location_on_outlined;
  /// 위치 꺼짐
  static const IconData locationOff = Icons.location_off_outlined;
  /// 내 위치
  static const IconData myLocation = Icons.my_location;
  /// 지도
  static const IconData map = Icons.map_outlined;

  // ===== 건강 카테고리 =====
  /// 체중
  static const IconData weight = Icons.monitor_weight_outlined;
  /// 산책
  static const IconData walk = Icons.directions_walk;
  /// 그루밍
  static const IconData grooming = Icons.content_cut;
  /// 약
  static const IconData medication = Icons.medication_outlined;
  /// 예방접종
  static const IconData vaccination = Icons.vaccines_outlined;
  /// 정기검진
  static const IconData checkup = Icons.local_hospital_outlined;
  /// 특이사항
  static const IconData special = Icons.note_alt_outlined;

  // ===== 그루밍 세부 =====
  /// 샤워
  static const IconData shower = Icons.shower_outlined;
  /// 빗질
  static const IconData brushing = Icons.brush_outlined;
  /// 발톱정리
  static const IconData nailTrim = Icons.content_cut;
  /// 이발
  static const IconData haircut = Icons.cut_outlined;
  /// 귀청소
  static const IconData earCleaning = Icons.hearing_outlined;
  /// 눈물자국
  static const IconData eyeCleaning = Icons.visibility_outlined;
  /// 항문낭
  static const IconData analGland = Icons.circle_outlined;
  /// 발바닥
  static const IconData pawCare = Icons.pets;
  /// 양치
  static const IconData teethBrushing = Icons.clean_hands_outlined;
  /// 치석제거
  static const IconData teethScaling = Icons.auto_fix_high;

  // ===== 소모임 카테고리 =====
  /// 산책 모임
  static const IconData groupWalk = Icons.directions_walk_outlined;
  /// 놀이 모임
  static const IconData groupPlay = Icons.sports_tennis_outlined;
  /// 나눔 모임
  static const IconData groupShare = Icons.card_giftcard_outlined;
  /// 커피 모임
  static const IconData groupCoffee = Icons.coffee_outlined;
  /// 훈련 모임
  static const IconData groupTraining = Icons.school_outlined;
  /// 건강 모임
  static const IconData groupHealth = Icons.fitness_center_outlined;

  // ===== 배지 =====
  /// 본인인증
  static const IconData badgeIdentity = Icons.verified_user_outlined;
  /// 위치인증
  static const IconData badgeLocation = Icons.location_on_outlined;
  /// 동물등록
  static const IconData badgePet = Icons.pets;

  // ===== 캘린더/시간 =====
  /// 캘린더
  static const IconData calendar = Icons.calendar_today;
  /// 캘린더 (월)
  static const IconData calendarMonth = Icons.calendar_month;
  /// 날짜 범위
  static const IconData dateRange = Icons.date_range;
  /// 이벤트
  static const IconData event = Icons.event;
  /// 타이머
  static const IconData timer = Icons.timer;
  /// 타이머 꺼짐
  static const IconData timerOff = Icons.timer_off_rounded;

  // ===== 상품 카테고리 =====
  /// 사료/간식
  static const IconData food = Icons.restaurant_outlined;
  /// 의류/악세서리
  static const IconData clothes = Icons.checkroom_outlined;
  /// 장난감
  static const IconData toys = Icons.toys_outlined;
  /// 용품
  static const IconData supplies = Icons.inventory_2_outlined;
  /// 가구/하우스
  static const IconData furniture = Icons.house_outlined;

  // ===== 알바 타입 =====
  /// 돌봄
  static const IconData care = Icons.home_outlined;
  /// 목욕
  static const IconData bath = Icons.shower_outlined;
  /// 훈련
  static const IconData training = Icons.school_outlined;

  // ===== 기타 =====
  /// 알바/일
  static const IconData work = Icons.person_search;
  /// 판매
  static const IconData sell = Icons.shopping_bag;
  /// 나눔
  static const IconData gift = Icons.volunteer_activism;
  /// 축하
  static const IconData celebration = Icons.celebration;
  /// 전구 (팁)
  static const IconData lightbulb = Icons.lightbulb_outline;
  /// 자동
  static const IconData autoAwesome = Icons.auto_awesome;
  /// 교환
  static const IconData swap = Icons.swap_horiz;
  /// 나가기
  static const IconData exit = Icons.exit_to_app;
  /// 메모
  static const IconData note = Icons.note_outlined;
  /// 날씨
  static const IconData weather = Icons.wb_sunny_outlined;
  /// 보안
  static const IconData security = Icons.security_rounded;
  /// 잠금
  static const IconData lock = Icons.lock_outline_rounded;
  /// 사람들
  static const IconData people = Icons.people_outline;
  /// 취소
  static const IconData cancel = Icons.cancel_outlined;
  /// 위로
  static const IconData arrowUp = Icons.arrow_upward;
  /// 아래로
  static const IconData arrowDown = Icons.arrow_downward;
  /// 앞으로
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  /// 추가 원
  static const IconData addCircle = Icons.add_circle_outline;
  /// 체크 원
  static const IconData checkCircle = Icons.check_circle;
  /// 야간 모드
  static const IconData nightMode = Icons.nightlight_round;
  /// 캠페인/마케팅
  static const IconData campaign = Icons.campaign;
  /// 이메일
  static const IconData email = Icons.email_outlined;
  /// 전화
  static const IconData phone = Icons.phone_outlined;
  /// Apple
  static const IconData apple = Icons.apple;
  /// Google
  static const IconData google = Icons.g_mobiledata;
  /// 학교/교육
  static const IconData school = Icons.school_outlined;
  /// 보이기
  static const IconData visibility = Icons.visibility_outlined;
  /// 숨기기
  static const IconData visibilityOff = Icons.visibility_off;
  /// 깨진 이미지
  static const IconData brokenImage = Icons.broken_image;
  /// 전체 선택
  static const IconData selectAll = Icons.select_all;
  /// 영구 삭제
  static const IconData deleteForever = Icons.delete_forever;
  /// 청소
  static const IconData cleaning = Icons.cleaning_services;
  /// 설명
  static const IconData description = Icons.description_outlined;

  // ===== 네트워크/연결 =====
  /// 와이파이
  static const IconData wifi = Icons.wifi_rounded;
  /// 와이파이 꺼짐
  static const IconData wifiOff = Icons.wifi_off_rounded;
  /// 클라우드 꺼짐
  static const IconData cloudOff = Icons.cloud_off_rounded;
  /// 검색 없음
  static const IconData searchOff = Icons.search_off_rounded;

  // ===== 하단 네비게이션 (outlined/filled 쌍) =====
  /// 채팅 (외곽선) - 하단 네비게이션용
  static const IconData chatBubbleOutlined = Icons.chat_bubble_outline;
  /// 채팅 (채워진) - 하단 네비게이션용
  static const IconData chatBubble = Icons.chat_bubble;
  /// 소셜/포럼 (외곽선)
  static const IconData forumOutlined = Icons.forum_outlined;
  /// 소셜/포럼 (채워진)
  static const IconData forum = Icons.forum;

  // ===== 확인 시트 아이콘 =====
  /// 그룹 추가
  static const IconData groupAdd = Icons.group_add;
  /// 사람 제거
  static const IconData personRemove = Icons.person_remove;

  // ===== 추가 공통 아이콘 =====
  /// 갤러리
  static const IconData gallery = Icons.photo_library;
  /// 사진 (외곽선)
  static const IconData photoOutlined = Icons.photo_outlined;
  /// 히스토리
  static const IconData history = Icons.history;
  /// 로그아웃
  static const IconData logout = Icons.logout;
  /// 헤드셋 (고객센터)
  static const IconData headset = Icons.headset_mic_outlined;
  /// 개발자 모드
  static const IconData developerMode = Icons.developer_mode;
  /// 북마크
  static const IconData bookmark = Icons.bookmark;
  /// 북마크 (외곽선)
  static const IconData bookmarkOutlined = Icons.bookmark_border;
  /// 별
  static const IconData star = Icons.star;
  /// 별 (외곽선)
  static const IconData starOutlined = Icons.star_border;
  /// 별 (반)
  static const IconData starHalf = Icons.star_half;
  /// 복사
  static const IconData copy = Icons.copy;
  /// 링크
  static const IconData link = Icons.link;
  /// 전송
  static const IconData send = Icons.send;
  /// 첨부
  static const IconData attach = Icons.attach_file;
  /// 다운로드
  static const IconData download = Icons.download;
  /// 업로드
  static const IconData upload = Icons.upload;
  /// 필터
  static const IconData filter = Icons.filter_list;
  /// 정렬
  static const IconData sort = Icons.sort;
  /// 확대
  static const IconData zoomIn = Icons.zoom_in;
  /// 축소
  static const IconData zoomOut = Icons.zoom_out;
  /// 회전
  static const IconData rotate = Icons.rotate_right;
  /// 자르기
  static const IconData crop = Icons.crop;
  /// 밝기
  static const IconData brightness = Icons.brightness_6;
  /// 대비
  static const IconData contrast = Icons.contrast;
  /// 시스템 밝기
  static const IconData settingsBrightness = Icons.settings_brightness;
  /// 라이트 모드
  static const IconData lightMode = Icons.light_mode;
  /// 다크 모드
  static const IconData darkMode = Icons.dark_mode;
  /// 모래시계
  static const IconData hourglass = Icons.hourglass_empty;
  /// 근처
  static const IconData nearMe = Icons.near_me;
  /// 근처 검색
  static const IconData radar = Icons.radar;
  /// 위치 비활성
  static const IconData locationDisabled = Icons.location_disabled;
  /// 알림 없음
  static const IconData notificationsNone = Icons.notifications_none;
  /// 쇼핑백
  static const IconData shoppingBag = Icons.shopping_bag;
  /// 상점 정면
  static const IconData storefront = Icons.storefront;
  /// 이미지 지원 안됨
  static const IconData imageNotSupported = Icons.image_not_supported;
  /// 받은편지함
  static const IconData inbox = Icons.inbox_rounded;
  /// 원형 (외곽선)
  static const IconData circleOutlined = Icons.circle_outlined;
  /// 시간
  static const IconData accessTime = Icons.access_time;
  /// 더보기 (가로)
  static const IconData moreHoriz = Icons.more_horiz;
  /// 심리학/성격
  static const IconData psychology = Icons.psychology;
  /// 케이크/생일
  static const IconData cake = Icons.cake;
  /// 태그
  static const IconData tag = Icons.tag;
  /// 링크 끊김
  static const IconData linkOff = Icons.link_off;
  /// 알림 끄기
  static const IconData notificationsOff = Icons.notifications_off_outlined;
}
