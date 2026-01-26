import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';
import '../theme/feature_colors.dart';

/// ============================================================
/// 네트워크 상태 배너 위젯
/// 
/// 오프라인 상태일 때 화면 상단에 배너를 표시
/// - 자동으로 네트워크 상태 감지
/// - 온라인 복구 시 자동으로 사라짐
/// ============================================================
class NetworkStatusBanner extends ConsumerWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatusAsync = ref.watch(networkStatusProvider);
    final errorColor = Theme.of(context).colorScheme.error;
    
    return networkStatusAsync.when(
      data: (status) {
        if (status == NetworkStatus.online) {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: errorColor,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '인터넷 연결이 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// 네트워크 상태를 감지하여 오프라인 시 스낵바를 표시하는 위젯
class NetworkAwareWidget extends ConsumerStatefulWidget {
  final Widget child;
  final bool showSnackBar;
  
  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.showSnackBar = true,
  });

  @override
  ConsumerState<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends ConsumerState<NetworkAwareWidget> {
  NetworkStatus? _previousStatus;
  
  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final successColor = context.features.success;
    
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (previous, next) {
      next.whenData((status) {
        // 온라인 → 오프라인 전환 시 스낵바 표시
        if (_previousStatus == NetworkStatus.online && status == NetworkStatus.offline) {
          if (widget.showSnackBar && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('인터넷 연결이 끊어졌습니다'),
                  ],
                ),
                backgroundColor: errorColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        // 오프라인 → 온라인 전환 시 스낵바 표시
        else if (_previousStatus == NetworkStatus.offline && status == NetworkStatus.online) {
          if (widget.showSnackBar && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('인터넷에 다시 연결되었습니다'),
                  ],
                ),
                backgroundColor: successColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        
        _previousStatus = status;
      });
    });
    
    return widget.child;
  }
}
