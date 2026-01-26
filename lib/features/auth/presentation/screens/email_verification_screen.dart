import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../providers/auth_provider.dart';

/// ============================================================
/// 이메일 인증 대기 화면
/// 
/// 이메일 회원가입 후 인증 대기 상태를 표시
/// - 인증 메일 재발송
/// - 인증 완료 확인 (자동/수동)
/// - 다른 계정으로 로그인
/// ============================================================
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  Timer? _autoCheckTimer;
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // 5초마다 자동으로 인증 상태 확인
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification(silent: true);
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final email = authState.valueOrNull?.email ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('이메일 인증'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showLogoutConfirm,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            children: [
              const Spacer(),
              
              // 이메일 아이콘
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSizes.gapXL),
              
              // 안내 타이틀
              Text(
                '이메일 인증이 필요해요',
                style: AppTextStyles.headlineLarge(context).withWeight(FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 안내 메시지
              Text(
                '아래 이메일로 인증 메일을 보냈어요.\n메일함을 확인해주세요.',
                style: AppTextStyles.bodyLarge(context).withColor(colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.gapL),
              
              // 이메일 주소 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingM,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, color: colorScheme.primary),
                    const SizedBox(width: AppSizes.gapS),
                    Flexible(
                      child: Text(
                        email,
                        style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 인증 확인 버튼
              MingrrButton(
                text: '인증 완료 확인',
                isLoading: _isChecking,
                onPressed: () => _checkVerification(silent: false),
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 재발송 버튼
              MingrrButton(
                text: _resendCooldown > 0 
                    ? '재발송 (${_resendCooldown}초)' 
                    : '인증 메일 재발송',
                isLoading: _isResending,
                isOutlined: true,
                onPressed: _resendCooldown > 0 ? null : _resendVerificationEmail,
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 다른 계정으로 로그인
              TextButton(
                onPressed: _showLogoutConfirm,
                child: Text(
                  '다른 계정으로 로그인',
                  style: AppTextStyles.bodyMedium(context).withColor(colorScheme.outline),
                ),
              ),
              
              const SizedBox(height: AppSizes.gapL),
              
              // 안내 문구
              Text(
                '메일이 오지 않았다면 스팸함을 확인해주세요.',
                style: AppTextStyles.bodySmall(context).withColor(colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 인증 상태 확인
  Future<void> _checkVerification({required bool silent}) async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final verified = await authNotifier.checkEmailVerified();
      
      if (verified && mounted) {
        MingrrSnackBar.success(context, '이메일 인증이 완료되었습니다! 🎉');
        // authStateProvider를 무효화하여 라우터가 새로운 인증 상태를 감지하도록 함
        ref.invalidate(authStateProvider);
        // 약간의 딜레이 후 홈으로 이동 (상태 업데이트 대기)
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) context.go('/');
      } else if (!silent && mounted) {
        MingrrSnackBar.warning(context, '아직 인증이 완료되지 않았어요');
      }
    } catch (e) {
      if (!silent && mounted) {
        MingrrSnackBar.error(context, '인증 확인 중 오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  /// 인증 메일 재발송
  Future<void> _resendVerificationEmail() async {
    if (_isResending || _resendCooldown > 0) return;
    
    setState(() => _isResending = true);
    
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.sendEmailVerification();
      
      if (mounted) {
        MingrrSnackBar.success(context, '인증 메일을 다시 보냈어요');
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// 재발송 쿨다운 시작 (60초)
  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  /// 로그아웃 확인 다이얼로그
  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('다른 계정으로 로그인하시겠어요?\n현재 계정에서 로그아웃됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
