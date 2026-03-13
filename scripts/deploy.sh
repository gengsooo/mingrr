#!/bin/bash

# ============================================================
# MINGRR 앱 배포 스크립트
# 
# 사용법:
#   ./scripts/deploy.sh ios        → iOS만 배포
#   ./scripts/deploy.sh android    → Android만 배포
#   ./scripts/deploy.sh all        → iOS + Android 둘 다 배포
#   ./scripts/deploy.sh ios "버그 수정"    → 릴리즈 노트 포함
#   ./scripts/deploy.sh all "v1.1 업데이트" → 릴리즈 노트 포함
# ============================================================

set -e

# ── 프로젝트 설정 ──
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_APP_ID="1:355588618342:ios:d5abaa8336c6683fe255a7"
ANDROID_APP_ID="1:355588618342:android:ee38434c08c8871be255a7"
EXPORT_OPTIONS="$PROJECT_DIR/ios/ExportOptions.plist"

# ── 인자 파싱 ──
PLATFORM="${1:-all}"
RELEASE_NOTES="${2:-배포 $(date '+%Y-%m-%d %H:%M')}"

# ── 색상 출력 ──
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "\n${BLUE}▶ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# ── 프로젝트 디렉토리로 이동 ──
cd "$PROJECT_DIR"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  MINGRR 앱 배포 스크립트${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "  플랫폼: ${YELLOW}$PLATFORM${NC}"
echo -e "  릴리즈 노트: ${YELLOW}$RELEASE_NOTES${NC}"
echo -e "${BLUE}================================================${NC}"

# ── iOS 배포 함수 ──
deploy_ios() {
  print_step "iOS 빌드 시작..."
  
  # IPA 빌드
  flutter build ipa --export-method ad-hoc 2>&1 | tail -5
  
  # IPA 파일 확인
  IPA_PATH="$PROJECT_DIR/build/ios/ipa/mingrr.ipa"
  
  if [ ! -f "$IPA_PATH" ]; then
    print_warning "flutter build ipa에서 IPA 생성 실패, xcodebuild로 재시도..."
    
    ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
    if [ ! -d "$ARCHIVE_PATH" ]; then
      print_error "Archive 파일이 없습니다. 빌드를 확인하세요."
      return 1
    fi
    
    # 기존 IPA 디렉토리 정리
    rm -rf "$PROJECT_DIR/build/ios/ipa"
    
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$PROJECT_DIR/build/ios/ipa" \
      -exportOptionsPlist "$EXPORT_OPTIONS" 2>&1 | tail -5
    
    IPA_PATH=$(find "$PROJECT_DIR/build/ios/ipa" -name "*.ipa" | head -1)
    
    if [ -z "$IPA_PATH" ]; then
      print_error "IPA 파일 생성에 실패했습니다."
      return 1
    fi
  fi
  
  print_success "iOS 빌드 완료: $IPA_PATH"
  
  # Firebase App Distribution 배포
  print_step "iOS App Distribution 배포 중..."
  firebase appdistribution:distribute "$IPA_PATH" \
    --app "$IOS_APP_ID" \
    --release-notes "$RELEASE_NOTES"
  
  print_success "iOS 배포 완료!"
}

# ── Android 배포 함수 ──
deploy_android() {
  print_step "Android 빌드 시작..."
  
  flutter build apk --release 2>&1 | tail -5
  
  APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
  
  if [ ! -f "$APK_PATH" ]; then
    print_error "APK 파일이 없습니다. 빌드를 확인하세요."
    return 1
  fi
  
  print_success "Android 빌드 완료: $APK_PATH"
  
  # Firebase App Distribution 배포
  print_step "Android App Distribution 배포 중..."
  firebase appdistribution:distribute "$APK_PATH" \
    --app "$ANDROID_APP_ID" \
    --release-notes "$RELEASE_NOTES"
  
  print_success "Android 배포 완료!"
}

# ── 실행 시간 측정 ──
START_TIME=$(date +%s)

# ── 플랫폼별 실행 ──
case "$PLATFORM" in
  ios)
    deploy_ios
    ;;
  android)
    deploy_android
    ;;
  all)
    deploy_ios
    deploy_android
    ;;
  *)
    print_error "알 수 없는 플랫폼: $PLATFORM"
    echo "사용법: $0 [ios|android|all] [릴리즈 노트]"
    exit 1
    ;;
esac

# ── 완료 ──
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  배포 완료! (${MINUTES}분 ${SECONDS}초)${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "  Firebase Console에서 확인:"
echo -e "  ${BLUE}https://console.firebase.google.com/project/mingrr/appdistribution${NC}"
echo ""
