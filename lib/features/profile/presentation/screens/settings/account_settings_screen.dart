import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 계정 관리 화면
/// 
/// 기능:
/// - 연동 계정 확인
/// - 비밀번호 변경 (이메일 로그인 사용자)
/// - 개인정보 수정
/// - 회원 탈퇴 (논리 삭제)
/// ============================================================

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final authUser = ref.watch(authStateProvider).valueOrNull;
    
    // 로그인 방식 확인
    final providerData = authUser?.providerData ?? [];
    final isEmailLogin = providerData.any((p) => p.providerId == 'password');
    final isKakaoLogin = providerData.any((p) => p.providerId == 'oidc.kakao');
    final isAppleLogin = providerData.any((p) => p.providerId == 'apple.com');
    final isGoogleLogin = providerData.any((p) => p.providerId == 'google.com');

    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const MingrrAppBar(title: '계정 관리'),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // 연동 계정
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '연동 계정',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MingrrSettingsTile.connection(
                  icon: AppIcons.email,
                  title: '이메일',
                  isConnected: isEmailLogin,
                  connectedText: authUser?.email ?? '연동됨',
                ),
                MingrrSettingsTile.connection(
                  icon: AppIcons.chatOutlined,
                  title: '카카오',
                  isConnected: isKakaoLogin,
                  iconColor: const Color(0xFFFEE500),
                ),
                MingrrSettingsTile.connection(
                  icon: AppIcons.apple,
                  title: 'Apple',
                  isConnected: isAppleLogin,
                ),
                MingrrSettingsTile.connection(
                  icon: AppIcons.google,
                  title: 'Google',
                  isConnected: isGoogleLogin,
                  iconColor: const Color(0xFF4285F4),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapL),
          
          // 비밀번호 변경 (이메일 로그인 사용자만)
          if (isEmailLogin) ...[
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                    child: Text(
                      '보안',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  MingrrSettingsTile(
                    icon: AppIcons.lock,
                    title: '비밀번호 변경',
                    subtitle: '비밀번호 재설정 이메일을 발송합니다',
                    onTap: _sendPasswordResetEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
          ],
          
          // 개인정보 수정
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '개인정보',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MingrrSettingsTile(
                  icon: AppIcons.email,
                  title: '이메일',
                  subtitle: authUser?.email ?? '등록되지 않음',
                  showChevron: false,
                ),
                MingrrSettingsTile(
                  icon: AppIcons.phone,
                  title: '전화번호',
                  subtitle: currentUser?.phoneNumber ?? '등록되지 않음',
                  showChevron: false,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 회원 탈퇴
          MingrrCard(
            margin: EdgeInsets.zero,
            child: MingrrSettingsTile.destructive(
              icon: AppIcons.personRemove,
              title: '회원 탈퇴',
              subtitle: '계정과 모든 데이터가 삭제됩니다',
              onTap: _showDeleteAccountDialog,
              showChevron: true,
            ),
          ),
          
          const SizedBox(height: AppSizes.gapM),
          
          // 안내 문구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
            child: Text(
              '* 회원 탈퇴 시 30일간 데이터가 보관되며, 이 기간 내 재가입 시 복구가 가능합니다.',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final email = authUser?.email;
    
    if (email == null) {
      MingrrSnackBar.error(context, '이메일 정보를 찾을 수 없습니다');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordResetEmail(email);
      
      if (mounted) {
        MingrrSnackBar.success(context, '비밀번호 재설정 이메일을 발송했습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '이메일 발송에 실패했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteAccountDialog() {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.accountDelete,
      onConfirm: () async {
        await _deleteAccount();
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    
    try {
      // 논리 삭제: isDeleted 플래그 설정 및 deletedAt 타임스탬프 저장
      // 실제 데이터는 30일 후 배치 작업으로 물리 삭제
      await ref.read(authNotifierProvider.notifier).deleteAccount();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        MingrrSnackBar.success(context, '회원 탈퇴가 완료되었습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '회원 탈퇴 중 오류가 발생했습니다');
        setState(() => _isLoading = false);
      }
    }
  }
}
