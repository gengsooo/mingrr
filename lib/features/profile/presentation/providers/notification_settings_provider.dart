import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 알림 설정 Provider
/// 
/// 프로필 > 알림 설정 화면에서 사용
/// Firestore users/{userId}/settings 컬렉션에 저장
/// ============================================================

final _firebase = FirebaseService();

/// 알림 설정 모델
class NotificationSettings {
  final bool allEnabled;
  final bool datingEnabled;
  final bool marketEnabled;
  final bool chatEnabled;
  final bool groupEnabled;
  final bool communityEnabled;
  final bool nightModeEnabled;
  final String nightModeStart;
  final String nightModeEnd;
  final bool marketingEnabled;
  
  const NotificationSettings({
    this.allEnabled = true,
    this.datingEnabled = true,
    this.marketEnabled = true,
    this.chatEnabled = true,
    this.groupEnabled = true,
    this.communityEnabled = true,
    this.nightModeEnabled = false,
    this.nightModeStart = '22:00',
    this.nightModeEnd = '08:00',
    this.marketingEnabled = false,
  });
  
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      allEnabled: map['allEnabled'] ?? true,
      datingEnabled: map['datingEnabled'] ?? true,
      marketEnabled: map['marketEnabled'] ?? true,
      chatEnabled: map['chatEnabled'] ?? true,
      groupEnabled: map['groupEnabled'] ?? true,
      communityEnabled: map['communityEnabled'] ?? true,
      nightModeEnabled: map['nightModeEnabled'] ?? false,
      nightModeStart: map['nightModeStart'] ?? '22:00',
      nightModeEnd: map['nightModeEnd'] ?? '08:00',
      marketingEnabled: map['marketingEnabled'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'allEnabled': allEnabled,
      'datingEnabled': datingEnabled,
      'marketEnabled': marketEnabled,
      'chatEnabled': chatEnabled,
      'groupEnabled': groupEnabled,
      'communityEnabled': communityEnabled,
      'nightModeEnabled': nightModeEnabled,
      'nightModeStart': nightModeStart,
      'nightModeEnd': nightModeEnd,
      'marketingEnabled': marketingEnabled,
    };
  }
  
  NotificationSettings copyWith({
    bool? allEnabled,
    bool? datingEnabled,
    bool? marketEnabled,
    bool? chatEnabled,
    bool? groupEnabled,
    bool? communityEnabled,
    bool? nightModeEnabled,
    String? nightModeStart,
    String? nightModeEnd,
    bool? marketingEnabled,
  }) {
    return NotificationSettings(
      allEnabled: allEnabled ?? this.allEnabled,
      datingEnabled: datingEnabled ?? this.datingEnabled,
      marketEnabled: marketEnabled ?? this.marketEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      groupEnabled: groupEnabled ?? this.groupEnabled,
      communityEnabled: communityEnabled ?? this.communityEnabled,
      nightModeEnabled: nightModeEnabled ?? this.nightModeEnabled,
      nightModeStart: nightModeStart ?? this.nightModeStart,
      nightModeEnd: nightModeEnd ?? this.nightModeEnd,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
    );
  }
}

/// 알림 설정 Provider (스트림)
final notificationSettingsProvider = StreamProvider.autoDispose<NotificationSettings>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) {
    return Stream.value(const NotificationSettings());
  }
  
  return _firebase.usersCollection
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return const NotificationSettings();
        final data = doc.data();
        final settingsData = data?['notificationSettings'] as Map<String, dynamic>?;
        if (settingsData == null) return const NotificationSettings();
        return NotificationSettings.fromMap(settingsData);
      });
});

/// 알림 설정 Notifier
class NotificationSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationSettingsNotifier() : super(const AsyncValue.data(null));
  
  /// 알림 설정 업데이트
  Future<bool> updateSettings(NotificationSettings settings) async {
    state = const AsyncValue.loading();
    
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) throw Exception('로그인이 필요합니다');
      
      await _firebase.usersCollection.doc(userId).update({
        'notificationSettings': settings.toMap(),
      });
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
  
  /// 개별 설정 토글
  Future<bool> toggleSetting(String key, bool value, NotificationSettings current) async {
    NotificationSettings updated;
    
    switch (key) {
      case 'allEnabled':
        updated = current.copyWith(
          allEnabled: value,
          datingEnabled: value,
          marketEnabled: value,
          chatEnabled: value,
          groupEnabled: value,
          communityEnabled: value,
        );
        break;
      case 'datingEnabled':
        updated = current.copyWith(datingEnabled: value);
        break;
      case 'marketEnabled':
        updated = current.copyWith(marketEnabled: value);
        break;
      case 'chatEnabled':
        updated = current.copyWith(chatEnabled: value);
        break;
      case 'groupEnabled':
        updated = current.copyWith(groupEnabled: value);
        break;
      case 'communityEnabled':
        updated = current.copyWith(communityEnabled: value);
        break;
      case 'nightModeEnabled':
        updated = current.copyWith(nightModeEnabled: value);
        break;
      case 'marketingEnabled':
        updated = current.copyWith(marketingEnabled: value);
        break;
      default:
        return false;
    }
    
    return updateSettings(updated);
  }
}

/// 알림 설정 Notifier Provider
final notificationSettingsNotifierProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<void>>((ref) {
  return NotificationSettingsNotifier();
});
