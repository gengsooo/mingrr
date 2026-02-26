import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 네트워크 연결 상태 Provider
/// 
/// 실시간으로 네트워크 연결 상태를 감지하여 UI에 반영
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// 현재 네트워크 연결 여부 Provider
final isConnectedProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  
  return connectivity.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true, // 로딩 중에는 연결된 것으로 간주
    error: (_, __) => true, // 에러 시에도 연결된 것으로 간주
  );
});

/// 네트워크 연결 상태 메시지 Provider
final networkStatusMessageProvider = Provider<String?>((ref) {
  final isConnected = ref.watch(isConnectedProvider);
  
  if (!isConnected) {
    return '인터넷 연결을 확인해주세요';
  }
  return null;
});
