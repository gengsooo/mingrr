import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 건강 수첩 화면
/// 예방접종, 체중, 배변, 산책 기록 관리
/// 앱 체류시간 증대를 위한 유틸리티 기능
/// ============================================================
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('건강 수첩'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 알림 설정
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '예방접종'),
            Tab(text: '체중'),
            Tab(text: '배변'),
            Tab(text: '산책'),
          ],
          indicatorColor: AppColors.health,
          labelColor: AppColors.health,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVaccinationTab(),
          _buildWeightTab(),
          _buildPoopTab(),
          _buildWalkHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRecordSheet();
        },
        backgroundColor: AppColors.health,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 예방접종 탭
  Widget _buildVaccinationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 다음 접종 알림 카드
          _buildNextVaccinationCard(),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 접종 기록 목록
          const MingrrSectionHeader(title: '접종 기록'),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(5, (index) => _buildVaccinationItem(index)),
        ],
      ),
    );
  }

  /// 다음 접종 알림 카드
  Widget _buildNextVaccinationCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.health,
            AppColors.health.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.health.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.vaccines,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '다음 접종 예정',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '종합백신 5차',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'D-7 (2024.01.28)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '알림 ON',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.health,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 접종 기록 아이템
  Widget _buildVaccinationItem(int index) {
    final vaccines = [
      {'name': '종합백신 4차', 'date': '2023.12.28', 'hospital': '행복동물병원'},
      {'name': '광견병', 'date': '2023.11.15', 'hospital': '행복동물병원'},
      {'name': '종합백신 3차', 'date': '2023.10.28', 'hospital': '행복동물병원'},
      {'name': '종합백신 2차', 'date': '2023.09.28', 'hospital': '행복동물병원'},
      {'name': '종합백신 1차', 'date': '2023.08.28', 'hospital': '행복동물병원'},
    ];

    final vaccine = vaccines[index];

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.health.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.health,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine['name']!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vaccine['date']} · ${vaccine['hospital']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  /// 체중 탭
  Widget _buildWeightTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 체중 카드
          _buildCurrentWeightCard(),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 체중 그래프 (플레이스홀더)
          _buildWeightChart(),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 체중 기록 목록
          const MingrrSectionHeader(title: '기록'),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(7, (index) => _buildWeightItem(index)),
        ],
      ),
    );
  }

  /// 현재 체중 카드
  Widget _buildCurrentWeightCard() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.health.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_weight,
              color: AppColors.health,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '현재 체중',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '5.2',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 14,
                      color: AppColors.success,
                    ),
                    Text(
                      '0.2kg',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '지난주 대비',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 체중 그래프 (플레이스홀더)
  Widget _buildWeightChart() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 30일',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Center(
              child: Text(
                '📈 체중 변화 그래프\n(fl_chart로 구현)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 체중 기록 아이템
  Widget _buildWeightItem(int index) {
    final weights = [5.2, 5.1, 5.0, 5.1, 5.0, 4.9, 4.8];
    final dates = ['오늘', '어제', '3일 전', '4일 전', '5일 전', '6일 전', '7일 전'];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapS),
      child: Row(
        children: [
          Text(
            dates[index],
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '${weights[index]}kg',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          if (index > 0)
            Icon(
              weights[index] > weights[index - 1]
                  ? Icons.arrow_drop_up
                  : weights[index] < weights[index - 1]
                      ? Icons.arrow_drop_down
                      : Icons.remove,
              color: weights[index] > weights[index - 1]
                  ? AppColors.success
                  : weights[index] < weights[index - 1]
                      ? AppColors.error
                      : AppColors.textHint,
            ),
        ],
      ),
    );
  }

  /// 배변 탭
  Widget _buildPoopTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오늘 요약
          _buildPoopSummaryCard(),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 기록 목록
          const MingrrSectionHeader(title: '오늘 기록'),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(3, (index) => _buildPoopItem(index)),
          
          const SizedBox(height: AppSizes.gapXL),
          
          const MingrrSectionHeader(title: '어제 기록'),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(4, (index) => _buildPoopItem(index + 3)),
        ],
      ),
    );
  }

  /// 배변 요약 카드
  Widget _buildPoopSummaryCard() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPoopStat('오늘', '3회', AppColors.success),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _buildPoopStat('이번 주 평균', '3.5회', AppColors.health),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _buildPoopStat('상태', '정상', AppColors.success),
        ],
      ),
    );
  }

  /// 배변 통계 아이템
  Widget _buildPoopStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 배변 기록 아이템
  Widget _buildPoopItem(int index) {
    final conditions = ['정상', '정상', '무른 변', '정상', '정상', '정상', '딱딱한 변'];
    final times = ['09:30', '14:20', '19:45', '08:15', '12:30', '17:00', '21:30'];
    final isNormal = conditions[index] == '정상';

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNormal
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNormal ? Icons.check : Icons.warning_amber,
              color: isNormal ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conditions[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isNormal ? AppColors.success : AppColors.warning,
                  ),
                ),
                Text(
                  times[index],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 산책 기록 탭
  Widget _buildWalkHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이번 주 요약
          _buildWalkSummaryCard(),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 산책 기록 목록
          const MingrrSectionHeader(title: '산책 기록'),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(7, (index) => _buildWalkHistoryItem(index)),
        ],
      ),
    );
  }

  /// 산책 요약 카드
  Widget _buildWalkSummaryCard() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      backgroundColor: AppColors.walk,
      child: Column(
        children: [
          const Text(
            '이번 주 산책',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWalkSummaryStat('총 거리', '12.5km'),
              _buildWalkSummaryStat('총 시간', '3시간 20분'),
              _buildWalkSummaryStat('횟수', '7회'),
            ],
          ),
        ],
      ),
    );
  }

  /// 산책 요약 통계
  Widget _buildWalkSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 산책 기록 아이템
  Widget _buildWalkHistoryItem(int index) {
    final dates = ['오늘', '어제', '2일 전', '3일 전', '4일 전', '5일 전', '6일 전'];
    final distances = [2.1, 1.8, 1.5, 2.3, 1.9, 1.2, 1.7];
    final durations = [35, 28, 25, 40, 32, 20, 30];

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.walk.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(
              Icons.directions_walk,
              color: AppColors.walk,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dates[index],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${distances[index]}km · ${durations[index]}분',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  /// 기록 추가 바텀시트
  void _showAddRecordSheet() {
    final currentTab = _tabController.index;
    final titles = ['예방접종 기록', '체중 기록', '배변 기록', '산책 기록'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      titles[currentTab],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('기록이 저장되었습니다!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: _buildRecordForm(currentTab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 기록 폼 (탭별)
  Widget _buildRecordForm(int tabIndex) {
    switch (tabIndex) {
      case 0: // 예방접종
        return Column(
          children: const [
            MingrrTextField(
              labelText: '백신 이름',
              hintText: '예: 종합백신 5차',
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '접종일',
              hintText: '2024.01.21',
              prefixIcon: Icons.calendar_today,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '다음 접종 예정일',
              hintText: '2024.02.21',
              prefixIcon: Icons.calendar_today,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '병원',
              hintText: '병원 이름',
              prefixIcon: Icons.local_hospital,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '메모',
              hintText: '추가 메모',
              maxLines: 3,
            ),
          ],
        );
      case 1: // 체중
        return Column(
          children: const [
            MingrrTextField(
              labelText: '체중 (kg)',
              hintText: '5.2',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.monitor_weight,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '날짜',
              hintText: '2024.01.21',
              prefixIcon: Icons.calendar_today,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '메모',
              hintText: '추가 메모',
              maxLines: 3,
            ),
          ],
        );
      case 2: // 배변
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상태',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConditionChip('정상', true),
                _buildConditionChip('무른 변', false),
                _buildConditionChip('딱딱한 변', false),
                _buildConditionChip('설사', false),
                _buildConditionChip('혈변', false),
              ],
            ),
            const SizedBox(height: AppSizes.gapL),
            const MingrrTextField(
              labelText: '시간',
              hintText: '09:30',
              prefixIcon: Icons.access_time,
            ),
            const SizedBox(height: AppSizes.gapL),
            const MingrrTextField(
              labelText: '메모',
              hintText: '추가 메모',
              maxLines: 3,
            ),
          ],
        );
      case 3: // 산책
        return Column(
          children: const [
            MingrrTextField(
              labelText: '거리 (km)',
              hintText: '2.5',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.straighten,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '시간 (분)',
              hintText: '30',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.timer,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '날짜',
              hintText: '2024.01.21',
              prefixIcon: Icons.calendar_today,
            ),
            SizedBox(height: AppSizes.gapL),
            MingrrTextField(
              labelText: '메모',
              hintText: '추가 메모',
              maxLines: 3,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 상태 칩
  Widget _buildConditionChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {},
      selectedColor: AppColors.health.withOpacity(0.2),
    );
  }
}
