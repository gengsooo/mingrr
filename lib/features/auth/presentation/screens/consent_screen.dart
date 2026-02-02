import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/legal_texts.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../providers/auth_provider.dart';

/// ============================================================
/// 회원가입 동의 화면
/// 
/// 정보통신망법, 개인정보보호법 준수를 위한 필수 동의 절차
/// 
/// 필수 동의 항목:
/// - 이용약관 동의
/// - 개인정보 수집·이용 동의
/// - 만 14세 이상 확인
/// 
/// 선택 동의 항목:
/// - 위치정보 이용 동의
/// - 마케팅 정보 수신 동의
/// ============================================================
class ConsentScreen extends ConsumerStatefulWidget {
  /// 이메일 회원가입 시 전달받는 정보
  final String? email;
  final String? password;
  
  /// 소셜 로그인 시 사용할 provider
  final String? socialProvider;
  
  const ConsentScreen({
    super.key,
    this.email,
    this.password,
    this.socialProvider,
  });

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  // 필수 동의
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _ageConfirmed = false;
  
  // 선택 동의
  bool _locationAgreed = false;
  bool _marketingAgreed = false;
  
  bool get _allRequiredAgreed => _termsAgreed && _privacyAgreed && _ageConfirmed;
  bool get _allAgreed => _allRequiredAgreed && _locationAgreed && _marketingAgreed;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: const MingrrAppBar(title: '약관 동의'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 문구
                    Text(
                      '밍그르르 서비스 이용을 위해\n약관에 동의해주세요.',
                      style: AppTextStyles.headlineMedium(context),
                    ),
                    const SizedBox(height: AppSizes.gapXXL),
                    
                    // 전체 동의
                    _buildAllAgreeItem(colorScheme),
                    
                    const Divider(height: AppSizes.gapXL * 2),
                    
                    // 필수 동의 항목
                    _buildConsentItem(
                      title: '[필수] 이용약관 동의',
                      isChecked: _termsAgreed,
                      onChanged: (v) => setState(() => _termsAgreed = v ?? false),
                      onViewDetail: () => _showTermsDetail(context),
                      colorScheme: colorScheme,
                    ),
                    
                    _buildConsentItem(
                      title: '[필수] 개인정보 수집·이용 동의',
                      isChecked: _privacyAgreed,
                      onChanged: (v) => setState(() => _privacyAgreed = v ?? false),
                      onViewDetail: () => _showPrivacyDetail(context),
                      colorScheme: colorScheme,
                    ),
                    
                    _buildConsentItem(
                      title: '[필수] 만 14세 이상입니다',
                      isChecked: _ageConfirmed,
                      onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
                      colorScheme: colorScheme,
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 선택 동의 항목
                    _buildConsentItem(
                      title: '[선택] 위치정보 이용 동의',
                      isChecked: _locationAgreed,
                      onChanged: (v) => setState(() => _locationAgreed = v ?? false),
                      onViewDetail: () => _showLocationDetail(context),
                      colorScheme: colorScheme,
                      isOptional: true,
                    ),
                    
                    _buildConsentItem(
                      title: '[선택] 마케팅 정보 수신 동의',
                      isChecked: _marketingAgreed,
                      onChanged: (v) => setState(() => _marketingAgreed = v ?? false),
                      onViewDetail: () => _showMarketingDetail(context),
                      colorScheme: colorScheme,
                      isOptional: true,
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 안내 문구
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.info,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSizes.gapS),
                          Expanded(
                            child: Text(
                              '선택 항목에 동의하지 않아도 서비스 이용이 가능합니다.\n단, 일부 기능 이용이 제한될 수 있습니다.',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 버튼
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSizes.paddingL,
                AppSizes.paddingM,
                AppSizes.paddingL,
                AppSizes.paddingL + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: MingrrButton(
                text: '동의하고 가입하기',
                isLoading: authState.isLoading,
                onPressed: _allRequiredAgreed ? _onSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 전체 동의 항목
  Widget _buildAllAgreeItem(ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        final newValue = !_allAgreed;
        setState(() {
          _termsAgreed = newValue;
          _privacyAgreed = newValue;
          _ageConfirmed = newValue;
          _locationAgreed = newValue;
          _marketingAgreed = newValue;
        });
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: _allAgreed 
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: _allAgreed ? colorScheme.primary : colorScheme.outline,
            width: _allAgreed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _allAgreed ? AppIcons.checkCircle : AppIcons.successOutlined,
              color: _allAgreed ? colorScheme.primary : colorScheme.outline,
              size: 24,
            ),
            const SizedBox(width: AppSizes.gapM),
            Expanded(
              child: Text(
                '전체 동의',
                style: AppTextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: _allAgreed ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 동의 항목
  Widget _buildConsentItem({
    required String title,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onViewDetail,
    required ColorScheme colorScheme,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        children: [
          // 체크박스
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          
          // 제목
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!isChecked),
              child: Text(
                title,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: isOptional 
                      ? colorScheme.onSurfaceVariant 
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          
          // 상세 보기 버튼
          if (onViewDetail != null)
            TextButton(
              onPressed: onViewDetail,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '보기',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: colorScheme.outline,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 이용약관 상세
  void _showTermsDetail(BuildContext context) {
    _showPolicySheet(
      context,
      title: '이용약관',
      content: termsOfService,
    );
  }

  /// 개인정보 수집·이용 상세
  void _showPrivacyDetail(BuildContext context) {
    _showPolicySheet(
      context,
      title: '개인정보 수집·이용 동의',
      content: privacyPolicy,
    );
  }

  /// 위치정보 이용 상세
  void _showLocationDetail(BuildContext context) {
    _showPolicySheet(
      context,
      title: '위치정보 이용약관',
      content: locationPolicy,
    );
  }

  /// 마케팅 정보 수신 상세
  void _showMarketingDetail(BuildContext context) {
    _showPolicySheet(
      context,
      title: '마케팅 정보 수신 동의',
      content: marketingPolicy,
    );
  }

  void _showPolicySheet(BuildContext context, {required String title, required String content}) {
    showMingrrBottomSheet(
      context: context,
      title: title,
      height: 0.85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
        child: Text(
          content,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  /// 가입 처리
  Future<void> _onSubmit() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    // 동의 정보 저장 (나중에 사용자 프로필에 저장)
    final consentData = ConsentData(
      termsAgreed: _termsAgreed,
      privacyAgreed: _privacyAgreed,
      ageConfirmed: _ageConfirmed,
      locationAgreed: _locationAgreed,
      marketingAgreed: _marketingAgreed,
      agreedAt: DateTime.now(),
    );
    
    if (widget.email != null && widget.password != null) {
      // 이메일 회원가입
      await authNotifier.signUpWithEmail(
        widget.email!,
        widget.password!,
        consentData: consentData,
      );
    } else if (widget.socialProvider != null) {
      // 소셜 로그인
      switch (widget.socialProvider) {
        case 'kakao':
          await authNotifier.signInWithKakao(consentData: consentData);
          break;
        case 'naver':
          await authNotifier.signInWithNaver(consentData: consentData);
          break;
        case 'google':
          await authNotifier.signInWithGoogle(consentData: consentData);
          break;
      }
    }
  }
}

/// 동의 데이터 모델
class ConsentData {
  final bool termsAgreed;
  final bool privacyAgreed;
  final bool ageConfirmed;
  final bool locationAgreed;
  final bool marketingAgreed;
  final DateTime agreedAt;
  
  const ConsentData({
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.ageConfirmed,
    required this.locationAgreed,
    required this.marketingAgreed,
    required this.agreedAt,
  });
  
  Map<String, dynamic> toMap() => {
    'termsAgreed': termsAgreed,
    'privacyAgreed': privacyAgreed,
    'ageConfirmed': ageConfirmed,
    'locationAgreed': locationAgreed,
    'marketingAgreed': marketingAgreed,
    'agreedAt': agreedAt.toIso8601String(),
  };
}
