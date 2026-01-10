import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/warmth_score.dart';
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
            body: const Center(child: Text('알바 정보를 찾을 수 없습니다')),
          );
        }
        return _buildContent(context, job);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('알바')),
        body: const Center(child: Text('데이터를 불러올 수 없습니다')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, JobModel job) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
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
          color: AppColors.marketLight,
          child: Center(
            child: Icon(
              _getJobIcon(job.type),
              size: 80,
              color: AppColors.market,
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
        // 시간, 위치
        Text(
          '${job.address ?? ''} · ${formatRelativeTime(job.createdAt)}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        // 급여
        Text(
          '${formatPrice(job.price)}원 / ${job.priceUnit}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.market,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context, JobModel job) {
    return GestureDetector(
      onTap: () => _showUserProfile(context, job),
      child: Row(
        children: [
          // 프로필 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 24, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '등록자',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const KkosunnaeScoreSmall(score: 50.0),
              ],
            ),
          ),
          // 화살표
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
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
        communityCount: 5,
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
        Text(
          job.description,
          style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
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
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    job.imageUrls[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: AppColors.divider,
                      child: const Icon(Icons.image, color: AppColors.textHint),
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
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingM,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // 가격 표시
          Expanded(
            child: Text(
              '${formatPrice(job.price)}원/${job.priceUnit}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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
                backgroundColor: AppColors.market,
                disabledBackgroundColor: AppColors.divider,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        return AppColors.dating;
      case JobType.walk:
        return AppColors.walk;
      case JobType.bath:
        return AppColors.health;
      case JobType.training:
        return AppColors.community;
      case JobType.other:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.recruiting:
        return AppColors.success;
      case JobStatus.reserved:
        return AppColors.warning;
      case JobStatus.completed:
        return AppColors.textSecondary;
      case JobStatus.cancelled:
        return AppColors.error;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능 준비 중입니다')),
    );
  }

  void _showMoreOptions(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined, color: AppColors.error),
              title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  context,
                  targetId: job.id,
                  targetName: '이 알바 글',
                  targetType: ReportTargetType.product,
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _startChat(JobModel job) {
    // 채팅 시작
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('채팅방을 생성합니다...'),
        backgroundColor: AppColors.market,
      ),
    );
  }
}
