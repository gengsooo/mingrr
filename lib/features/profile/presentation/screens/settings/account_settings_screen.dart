import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/feature_colors.dart';
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
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 관리'),
      ),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '연동 계정',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _buildProviderTile(
                  context: context,
                  icon: Icons.email_outlined,
                  title: '이메일',
                  subtitle: authUser?.email ?? '연동되지 않음',
                  isConnected: isEmailLogin,
                ),
                _buildProviderTile(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  title: '카카오',
                  subtitle: isKakaoLogin ? '연동됨' : '연동되지 않음',
                  isConnected: isKakaoLogin,
                  iconColor: const Color(0xFFFEE500),
                ),
                _buildProviderTile(
                  context: context,
                  icon: Icons.apple,
                  title: 'Apple',
                  subtitle: isAppleLogin ? '연동됨' : '연동되지 않음',
                  isConnected: isAppleLogin,
                ),
                _buildProviderTile(
                  context: context,
                  icon: Icons.g_mobiledata,
                  title: 'Google',
                  subtitle: isGoogleLogin ? '연동됨' : '연동되지 않음',
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '보안',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: const Text('비밀번호 변경'),
                    subtitle: Text(
                      '비밀번호 재설정 이메일을 발송합니다',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '개인정보',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('이메일'),
                  subtitle: Text(
                    authUser?.email ?? '등록되지 않음',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('전화번호'),
                  subtitle: Text(
                    currentUser?.phoneNumber ?? '등록되지 않음',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 회원 탈퇴
          MingrrCard(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_remove_outlined, color: Colors.red),
              ),
              title: const Text(
                '회원 탈퇴',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: Text(
                '계정과 모든 데이터가 삭제됩니다',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              onTap: _showDeleteAccountDialog,
            ),
          ),
          
          const SizedBox(height: AppSizes.gapM),
          
          // 안내 문구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '* 회원 탈퇴 시 30일간 데이터가 보관되며, 이 기간 내 재가입 시 복구가 가능합니다.',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isConnected 
              ? (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isConnected ? (iconColor ?? Theme.of(context).colorScheme.primary) : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: isConnected
          ? Icon(Icons.check_circle, color: context.features.success, size: 20)
          : Icon(Icons.circle_outlined, color: colorScheme.onSurfaceVariant, size: 20),
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
