import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/dialogs/dialogs.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// AppVersionService - 앱 버전 체크 서비스
/// 
/// Firebase Firestore에서 최소 버전 정보를 가져와
/// 강제 업데이트가 필요한지 확인
/// ============================================================

class AppVersionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 현재 앱 버전 정보
  static Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
  
  /// 현재 앱 버전 문자열
  static Future<String> get currentVersion async {
    final info = await getPackageInfo();
    return info.version;
  }
  
  /// 현재 빌드 번호
  static Future<String> get currentBuildNumber async {
    final info = await getPackageInfo();
    return info.buildNumber;
  }
  
  /// Firestore에서 최소 버전 정보 가져오기
  static Future<VersionInfo?> getMinimumVersion() async {
    try {
      final doc = await _firestore.collection('config').doc('app_version').get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return VersionInfo(
        minVersion: data['min_version'] as String? ?? '1.0.0',
        latestVersion: data['latest_version'] as String? ?? '1.0.0',
        updateUrl: data['update_url'] as String?,
        updateMessage: data['update_message'] as String?,
        forceUpdate: data['force_update'] as bool? ?? false,
      );
    } catch (e) {
      AppLogger.error('AppVersionService', '버전 정보 로드 실패', e);
      return null;
    }
  }
  
  /// 버전 비교 (v1 < v2 이면 true)
  static bool isVersionLower(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    // 길이 맞추기
    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }
    
    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return true;
      if (parts1[i] > parts2[i]) return false;
    }
    return false;
  }
  
  /// 업데이트 필요 여부 확인 및 팝업 표시
  static Future<bool> checkAndShowUpdateDialog(BuildContext context) async {
    try {
      final current = await currentVersion;
      final versionInfo = await getMinimumVersion();
      
      if (versionInfo == null) return true; // 정보 없으면 통과
      
      final needsUpdate = isVersionLower(current, versionInfo.minVersion);
      
      if (!needsUpdate) return true; // 업데이트 불필요
      
      AppLogger.info('AppVersionService', 
        '업데이트 필요: 현재=$current, 최소=${versionInfo.minVersion}');
      
      if (!context.mounted) return false;
      
      // 강제 업데이트 팝업
      if (versionInfo.forceUpdate) {
        await showAppDialog(
          context,
          type: DialogType.warning,
          title: '업데이트 필요',
          message: versionInfo.updateMessage ?? 
            '새로운 버전이 출시되었습니다.\n앱을 업데이트해주세요.',
          confirmText: '업데이트',
          showCancel: false,
        );
        await _openStore(versionInfo.updateUrl);
        return false;
      }
      
      // 선택적 업데이트 팝업
      final result = await showAppDialog(
        context,
        type: DialogType.info,
        title: '업데이트 안내',
        message: versionInfo.updateMessage ?? 
          '새로운 버전(${versionInfo.latestVersion})이 있습니다.\n업데이트하시겠습니까?',
        confirmText: '업데이트',
        showCancel: true,
      );
      
      if (result == true) {
        await _openStore(versionInfo.updateUrl);
      }
      
      return true;
    } catch (e) {
      AppLogger.error('AppVersionService', '버전 체크 실패', e);
      return true; // 실패 시 통과
    }
  }

  /// 앱 스토어/플레이 스토어 열기
  static Future<void> _openStore(String? updateUrl) async {
    try {
      // Firestore에 설정된 URL이 있으면 우선 사용
      if (updateUrl != null && updateUrl.isNotEmpty) {
        final uri = Uri.parse(updateUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // 플랫폼별 기본 스토어 URL
      final packageInfo = await getPackageInfo();
      final packageName = packageInfo.packageName;

      final Uri storeUri;
      if (Platform.isAndroid) {
        storeUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
      } else if (Platform.isIOS) {
        // TODO: 실제 App Store ID로 변경 필요 (출시 후)
        storeUri = Uri.parse('https://apps.apple.com/app/id000000000');
      } else {
        return;
      }

      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.error('AppVersionService', '스토어 열기 실패', e);
    }
  }
}

/// 버전 정보 모델
class VersionInfo {
  final String minVersion;
  final String latestVersion;
  final String? updateUrl;
  final String? updateMessage;
  final bool forceUpdate;
  
  const VersionInfo({
    required this.minVersion,
    required this.latestVersion,
    this.updateUrl,
    this.updateMessage,
    this.forceUpdate = false,
  });
}
