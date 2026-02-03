import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/cards/profile_cards.dart';
import '../../../../core/widgets/sheets/report_sheet.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/mixins/distance_calculator_mixin.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../models/marketplace_model.dart';
import '../providers/marketplace_provider.dart';

/// ============================================================
/// 알바 상세 화면
/// 
/// 기능:
/// - 알바 정보 표시 (타입, 급여, 기간 등)
/// - 등록자 정보 (꼬순내 지수 포함)
/// - 채팅 문의 버튼
/// - 신고 기능
/// ============================================================
class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with DistanceCalculatorMixin {
  /// 거리 문자열 계산 (Mixin 활용)
  String _getDistanceString(JobModel job) {
    return getDistanceFromLocation(job.location, job.address);
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: const MingrrAppBar(title: '알바'),
            body: const MingrrEmptyState(
              icon: AppIcons.work,
              title: '아직 데이터가 없어요',
              subtitle: '알바 정보를 찾을 수 없습니다',
            ),
          );
        }
        return _buildContent(context, job);
      },
      loading: () => Scaffold(
        body: MingrrFullScreenLoading(
          message: '알바 정보 불러오는 중',
          type: MingrrLoadingType.market,
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: const MingrrAppBar(title: '알바'),
        body: MingrrErrorState(
          onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, JobModel job) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더 (상품 상세와 동일한 스타일)
          _buildImageHeader(context, job),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 등록자 정보
                  _buildUserInfo(context, job),
                  const MingrrDivider.section(),
                  
                  // 알바 정보
                  _buildJobInfo(job),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 상세 설명
                  _buildDescription(job),
                  
                  // 이미지 (있는 경우)
                  if (job.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.gapXL),
                    _buildImages(job),
                  ],
                  
                  // 하단 여백 (버튼 공간)
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // 하단 고정 버튼
      bottomNavigationBar: _buildBottomBar(context, job),
    );
  }

  /// 이미지 헤더 (상품 상세와 동일한 스타일)
  Widget _buildImageHeader(BuildContext context, JobModel job) {
    return MingrrImageHeader(
      imageUrls: job.imageUrls,
      expandedHeight: 200,
      onShare: () => _shareJob(job),
      onMore: () => _showMoreOptions(context, job),
      placeholder: Container(
        color: context.features.marketContainer,
        child: Center(
          child: Icon(
            AppIcons.image,
            size: 80,
            color: context.features.market,
          ),
        ),
      ),
    );
  }
  
  IconData _getJobIcon(JobType type) {
    switch (type) {
      case JobType.care:
        return AppIcons.pet;
      case JobType.walk:
        return AppIcons.walk;
      case JobType.bath:
        return AppIcons.shower;
      case JobType.training:
        return AppIcons.school;
      case JobType.other:
        return AppIcons.work;
    }
  }

  /// 알바 정보 (상품 정보와 동일한 구조)
  Widget _buildJobInfo(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 + 상태 배지
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              decoration: BoxDecoration(
                color: _getTypeColor(job.type).withValues(alpha: AppOpacity.o10),
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: Text(
                job.typeString,
                style: AppTextStyles.labelLarge(context).copyWith(color: _getTypeColor(job.type)),
              ),
            ),
            const SizedBox(width: AppSizes.gapSM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              decoration: BoxDecoration(
                color: _getStatusColor(job.status).withValues(alpha: AppOpacity.o10),
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: Text(
                _getStatusText(job.status),
                style: AppTextStyles.labelLarge(context).copyWith(color: _getStatusColor(job.status)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapM),
        // 제목
        Text(
          job.title,
          style: AppTextStyles.headlineMedium(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        // 기간, 시간, 위치
        if (job.fullPeriodString.isNotEmpty) ...[
          Row(
            children: [
              Icon(AppIcons.calendar, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSizes.gapXS),
              Expanded(
                child: Text(
                  job.fullPeriodString,
                  style: AppTextStyles.bodySmall(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapXS),
        ],
        Text(
          '${_getDistanceString(job)} · ${formatRelativeTime(job.createdAt)}',
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        // 급여
        Text(
          '${formatPrice(job.price)}원 / ${job.priceUnit}',
          style: AppTextStyles.displayMedium(context).withWeight(FontWeight.w700).withColor(context.features.market),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context, JobModel job) {
    return GuardianProfileCard(
      name: '등록자',
      kkosunnaeScore: 50.0,
      accentColor: context.features.market,
      onTap: () => _showUserProfile(context, job),
    );
  }
  
  void _showUserProfile(BuildContext context, JobModel job) {
    showGuardianProfileModal(
      context,
      guardianId: job.userId,
      guardianName: '등록자',
      kkosunnaeScore: 50.0,
      isIdentityVerified: true,
      isPetVerified: true,
      isLocationVerified: false,
      pets: [
        GuardianPetInfo(
          id: 'pet_1',
          name: '뿐삐',
          breed: '골든 리트리버',
          ageString: '3살',
          likeCount: 42,
        ),
      ],
      activityInfo: const GuardianActivityInfo(
        walkCount: 65,
        datingCount: 8,
        marketCount: 12,
        groupCount: 5,
      ),
    );
  }

  Widget _buildDescription(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상세 내용',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            job.description,
            style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildImages(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부 이미지',
          style: AppTextStyles.headlineSmall(context).withWeight(FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapM),
        MingrrImageGallery(
          imageUrls: job.imageUrls,
          height: 120,
          itemWidth: 120,
          enableViewer: true,
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, JobModel job) {
    return MingrrBottomButtonBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // 가격 표시
          Expanded(
            child: Text(
              '${formatPrice(job.price)}원/${job.priceUnit}',
              style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w700),
            ),
          ),
          // 채팅하기 버튼
          MingrrButton(
            text: '채팅하기',
            onPressed: job.status == JobStatus.recruiting
                ? () => _startChat(job)
                : null,
            backgroundColor: context.features.market,
            textColor: Colors.white,
            height: 48,
            width: 100,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(JobType type) {
    switch (type) {
      case JobType.care:
        return context.features.dating;
      case JobType.walk:
        return context.features.walk;
      case JobType.bath:
        return context.features.health;
      case JobType.training:
        return context.features.social;
      case JobType.other:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.recruiting:
        return context.features.success;
      case JobStatus.reserved:
        return Colors.orange;
      case JobStatus.completed:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case JobStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.recruiting:
        return '모집중';
      case JobStatus.reserved:
        return '예약됨';
      case JobStatus.completed:
        return '완료';
      case JobStatus.cancelled:
        return '취소됨';
    }
  }


  void _shareJob(JobModel job) {
    ShareService.shareJob(context, job);
  }

  /// 본인 글 여부 확인
  bool _isOwner(JobModel job) {
    final myUserId = FirebaseService().currentUserId;
    return myUserId != null && job.userId == myUserId;
  }

  void _showMoreOptions(BuildContext context, JobModel job) {
    showDetailOptionsSheet(
      context: context,
      isOwner: _isOwner(job),
      onShare: () => _shareJob(job),
      onReport: () {
        showReportSheet(
          context,
          targetId: job.id,
          targetName: '이 알바 글',
          targetType: ReportTargetType.product,
        );
      },
    );
  }

  void _startChat(JobModel job) {
    // 채팅 시작
    MingrrSnackBar.info(context, '채팅방을 생성합니다...');
  }
}
