import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/badges/svg_icons.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 온보딩 화면
/// 
/// 앱 첫 실행 시 표시되는 소개 화면
/// 4개의 페이지로 구성 (친구 만들기, 산책, 커뮤니티, 시작하기)
/// ============================================================
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      svgAsset: SvgAssets.onboarding1,
      title: '새로운 친구를 만나보세요',
      description: '우리 아이와 잘 맞는 친구를 찾아\n즐거운 시간을 보내세요',
    ),
    OnboardingPage(
      svgAsset: SvgAssets.onboarding2,
      title: '함께 산책해요',
      description: '산책 기록을 남기고\n건강한 일상을 관리하세요',
    ),
    OnboardingPage(
      svgAsset: SvgAssets.onboarding3,
      title: '소모임에 참여하세요',
      description: '같은 관심사를 가진 반려인들과\n소통하고 정보를 나눠요',
    ),
    OnboardingPage(
      svgAsset: SvgAssets.onboarding4,
      title: '밍그르르와 함께 시작해요',
      description: '우리 아이와 함께하는\n특별한 일상이 시작됩니다',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 스킵 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    '건너뛰기',
                    style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                  ),
                ),
              ),
            ),
            
            // 페이지 뷰
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SVG 일러스트
                        MingrrSvgIcon(
                          assetPath: page.svgAsset,
                          width: 280,
                          height: 280,
                        ),
                        const SizedBox(height: AppSizes.gapXXL),
                        
                        // 제목
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium(context).withWeight(FontWeight.w700),
                        ),
                        const SizedBox(height: AppSizes.gapM),
                        
                        // 설명
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineSmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant).withHeight(1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 하단 영역 (인디케이터 + 버튼)
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingXL),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 다음/시작 버튼
                  MingrrButton(
                    text: _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 페이지 데이터
class OnboardingPage {
  final String svgAsset;
  final String title;
  final String description;

  const OnboardingPage({
    required this.svgAsset,
    required this.title,
    required this.description,
  });
}

/// 온보딩 완료 여부 확인
Future<bool> isOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
}
