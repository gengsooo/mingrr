import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// 바텀시트 스택 매니저
/// 
/// 바텀시트 간 순환 감지 및 스택 관리
/// 
/// 사용 예시:
/// - 보호자 정보 → 반려동물 정보 → 보호자 정보 (순환 감지)
/// - 순환 감지 시 기존 바텀시트까지 모두 닫고 새로 열기
/// ============================================================

class BottomSheetStackManager {
  // 싱글톤 패턴
  static final BottomSheetStackManager _instance = BottomSheetStackManager._internal();
  factory BottomSheetStackManager() => _instance;
  BottomSheetStackManager._internal();

  // 열린 바텀시트 스택 (sheetId 목록)
  final List<String> _stack = [];
  
  /// 현재 스택 상태 (디버깅용)
  List<String> get stack => List.unmodifiable(_stack);

  /// 순환이 감지되었는지 확인 (같은 ID가 스택에 있는지)
  bool hasCycle(String sheetId) {
    return _stack.contains(sheetId);
  }

  /// 바텀시트 열림 등록
  void push(String sheetId) {
    _stack.add(sheetId);
    AppLogger.debug('BottomSheetStack', 'push: $sheetId, stack: $_stack');
  }

  /// 바텀시트 닫힘 등록
  void pop(String sheetId) {
    _stack.remove(sheetId);
    AppLogger.debug('BottomSheetStack', 'pop: $sheetId, stack: $_stack');
  }

  /// 특정 바텀시트까지 모두 닫기 (순환 감지 시 사용)
  /// 해당 ID부터 스택 끝까지 제거하고 Navigator.pop() 호출
  int popUntilAndGetCount(String sheetId) {
    final index = _stack.indexOf(sheetId);
    if (index < 0) return 0;
    
    final closeCount = _stack.length - index;
    final toRemove = List<String>.from(_stack.sublist(index));
    
    for (final id in toRemove) {
      _stack.remove(id);
    }
    
    AppLogger.debug('BottomSheetStack', 'popUntil: $sheetId, closeCount: $closeCount, remaining: $_stack');
    return closeCount;
  }

  /// 스택 초기화 (앱 상태 리셋 시 사용)
  void clear() {
    _stack.clear();
    AppLogger.debug('BottomSheetStack', 'cleared');
  }

  /// 바텀시트 ID 생성 헬퍼
  static String createSheetId(String type, String? entityId) {
    return entityId != null ? '${type}_$entityId' : type;
  }
}

/// 바텀시트 타입 상수
class BottomSheetType {
  static const String guardian = 'guardian';
  static const String pet = 'pet';
  static const String group = 'group';
  static const String chatOptions = 'chat_options';
  static const String rating = 'rating';
}
