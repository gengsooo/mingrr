import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/profile_cards.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';
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

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('알바')),
            body: const MingrrEmptyState(
              icon: Icons.work_outline,
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
        appBar: AppBar(title: const Text('알바')),
        body: const MingrrErrorState(title: '일시적인 오류가 발생했어요', subtitle: '잠시 후 다시 시도해주세요'),
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
                  const Divider(height: 32),
                  
                  // 알바 정보
                  _buildJobInfo(job),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 상세 설명
                  _buildDescription(job),
                  
                  // 이미지 (있는 경우)
                  if (job.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
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
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: () => _shareJob(job),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showMoreOptions(context, job),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.features.marketContainer,
          child: Center(
            child: Icon(
              _getJobIcon(job.type),
              size: 80,
              color: context.features.market,
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getJobIcon(JobType type) {
    switch (type) {
      case JobType.care:
        return Icons.pets;
      case JobType.walk:
        return Icons.directions_walk;
      case JobType.bath:
        return Icons.bathtub_outlined;
      case JobType.training:
        return Icons.school_outlined;
      case JobType.other:
        return Icons.work_outline;
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(job.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                job.typeString,
                style: TextStyle(fontSize: 12, color: _getTypeColor(job.type)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(job.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusText(job.status),
                style: TextStyle(fontSize: 12, color: _getStatusColor(job.status)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 제목
        Text(
          job.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // 기간, 시간, 위치
        if (job.fullPeriodString.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.fullPeriodString,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Text(
          '${job.address ?? ''} · ${formatRelativeTime(job.createdAt)}',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        // 급여
        Text(
          '${formatPrice(job.price)}원 / ${job.priceUnit}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.features.market,
          ),
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
        const Text(
          '상세 내용',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            job.description,
            style: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildImages(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '첨부 이미지',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: job.imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < job.imageUrls.length - 1 ? 8 : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  child: Image.network(
                    job.imageUrls[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: Theme.of(context).colorScheme.outline,
                      child: Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                ),
              );
            },
          ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // 채팅하기 버튼
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: job.status == JobStatus.recruiting
                  ? () => _startChat(job)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.features.market,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '채팅하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
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
    MingrrSnackBar.info(context, '공유 기능 준비 중입니다');
  }

  void _showMoreOptions(BuildContext context, JobModel job) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.report_outlined,
          label: '신고하기',
          isDestructive: true,
          onTap: () {
            showReportSheet(
              context,
              targetId: job.id,
              targetName: '이 알바 글',
              targetType: ReportTargetType.product,
            );
          },
        ),
      ],
    );
  }

  void _startChat(JobModel job) {
    // 채팅 시작
    MingrrSnackBar.info(context, '채팅방을 생성합니다...');
  }
}
