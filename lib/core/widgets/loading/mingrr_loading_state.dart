import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/network_provider.dart';
import 'loading_widgets.dart' show MingrrLoadingType, MingrrLoadingIndicator;

// ===== 공통 로딩 상태 위젯 =====
/// 데이터 로딩 중 표시하는 위젯
/// 
/// Riverpod AsyncValue.when()의 loading 상태에서 사용
/// MingrrEmptyState와 동일한 디자인 (아이콘 → 로딩 스피너)
/// 
/// [timeout] 지정 시 해당 시간 후 타임아웃 UI 표시
/// [onRetry] 지정 시 타임아웃 후 재시도 버튼 표시
/// 네트워크 연결 상태 자동 감지
class MingrrLoadingState extends ConsumerStatefulWidget {
  final String? message;
  final String? subMessage;
  final Color? color;
  final MingrrLoadingType type;
  final Duration? timeout;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const MingrrLoadingState({
    super.key,
    this.message,
    this.subMessage,
    this.color,
    this.type = MingrrLoadingType.primary,
    this.timeout,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  ConsumerState<MingrrLoadingState> createState() => _MingrrLoadingStateState();
}

class _MingrrLoadingStateState extends ConsumerState<MingrrLoadingState> {
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    if (widget.timeout != null) {
      Future.delayed(widget.timeout!, () {
        if (mounted && !_isTimedOut) {
          setState(() => _isTimedOut = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = ref.watch(isConnectedProvider);
    
    // 네트워크 연결 끊김 상태
    if (!isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.wifiOff,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapL),
            Text(
              '인터넷 연결이 끊겼어요',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              'Wi-Fi 또는 모바일 데이터를 확인해주세요',
              style: AppTextStyles.bodySmall(context).withColor(colorScheme.outlineVariant),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppSizes.gapL),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.retryButtonText ?? '다시 시도'),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // 타임아웃 상태
    if (_isTimedOut) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.hourglass,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapL),
            Text(
              '로딩이 오래 걸리고 있어요',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              '네트워크 상태를 확인해주세요',
              style: AppTextStyles.bodySmall(context).withColor(colorScheme.outlineVariant),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppSizes.gapL),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isTimedOut = false);
                    _startTimeoutTimer();
                    widget.onRetry!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.retryButtonText ?? '다시 시도'),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // 로딩 상태
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MingrrLoadingIndicator(
            size: 48,
            strokeWidth: 3,
            customColor: colorScheme.outlineVariant,
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppSizes.gapL),
            Text(
              widget.message!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.subMessage != null) ...[
            const SizedBox(height: AppSizes.gapS),
            Text(
              widget.subMessage!,
              style: AppTextStyles.bodySmall(context).withColor(colorScheme.outlineVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
