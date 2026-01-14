import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/location_helper.dart';
import '../../core/utils/seed_data.dart';
import '../../core/widgets/dialogs/dialogs.dart';
import '../../core/widgets/map/map_loading_widget.dart';
import '../../../../core/theme/feature_colors.dart';
import '../auth/presentation/providers/auth_provider.dart';

/// 데이터 항목 정의 (사용자 계정은 Firebase Auth에서 관리하므로 제외)
enum DataCategory {
  pets('반려동물', Icons.pets),
  products('상품', Icons.shopping_bag),
  groups('소모임', Icons.groups),
  jobs('알바', Icons.work),
  breeding('교배', Icons.favorite_border),
  likesMatches('좋아요/매칭', Icons.favorite),
  chats('채팅', Icons.chat),
  ratings('꼬순내 평가', Icons.star),
  healthRecords('건강수첩', Icons.medical_services);

  final String label;
  final IconData icon;
  const DataCategory(this.label, this.icon);
}

/// Firebase 컬렉션 데이터 개수 Provider
final _firebaseService = FirebaseService();

final collectionCountsProvider = StreamProvider.autoDispose<Map<DataCategory, int>>((ref) {
  // 각 컬렉션의 스냅샷을 합쳐서 개수 반환
  return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
    final counts = <DataCategory, int>{};
    
    counts[DataCategory.pets] = (await _firebaseService.petsCollection.get()).docs.length;
    counts[DataCategory.products] = (await _firebaseService.productsCollection.get()).docs.length;
    counts[DataCategory.groups] = (await _firebaseService.groupsCollection.get()).docs.length;
    counts[DataCategory.jobs] = (await _firebaseService.jobsCollection.get()).docs.length;
    counts[DataCategory.breeding] = (await _firebaseService.breedingPostsCollection.get()).docs.length;
    
    final likesCount = (await _firebaseService.likesCollection.get()).docs.length;
    final matchesCount = (await _firebaseService.matchesCollection.get()).docs.length;
    counts[DataCategory.likesMatches] = likesCount + matchesCount;
    
    counts[DataCategory.chats] = (await _firebaseService.chatRoomsCollection.get()).docs.length;
    
    // 꼬순내 평가 데이터 개수
    counts[DataCategory.ratings] = (await _firebaseService.ratingsCollection.get()).docs.length;
    
    // 건강수첩 데이터 개수 (여러 컬렉션 합산)
    int healthCount = 0;
    healthCount += (await _firebaseService.firestore.collection('weight_records').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('walk_records').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('grooming_records').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('vaccination_records').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('checkup_records').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('medication_records').get()).docs.length;
    counts[DataCategory.healthRecords] = healthCount;
    
    return counts;
  });
});

class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  final SeedData _seedData = SeedData();
  bool _isLoading = false;
  String _message = '';
  
  // 체크박스 상태
  final Map<DataCategory, bool> _selectedCategories = {
    for (var cat in DataCategory.values) cat: false
  };
  
  // 전체 선택 여부
  bool get _isAllSelected => _selectedCategories.values.every((v) => v);
  
  // 선택된 항목 개수
  int get _selectedCount => _selectedCategories.values.where((v) => v).length;
  
  void _toggleAll(bool? value) {
    setState(() {
      for (var cat in DataCategory.values) {
        _selectedCategories[cat] = value ?? false;
      }
    });
  }
  
  void _toggleCategory(DataCategory category, bool? value) {
    setState(() {
      _selectedCategories[category] = value ?? false;
    });
  }
  
  String _getCategoryDescription(DataCategory category, int count) {
    switch (category) {
      case DataCategory.pets:
        return '반려동물 ${count}마리';
      case DataCategory.products:
        return '판매/나눔 상품 ${count}개';
      case DataCategory.groups:
        return '모임 ${count}개';
      case DataCategory.jobs:
        return '알바 ${count}개';
      case DataCategory.breeding:
        return '교배 글 ${count}개';
      case DataCategory.likesMatches:
        return '좋아요/매칭 ${count}개';
      case DataCategory.chats:
        return '채팅방 ${count}개';
      case DataCategory.ratings:
        return '꼬순내 평가 ${count}개';
      case DataCategory.healthRecords:
        return '건강수첩 기록 ${count}개';
    }
  }

  Future<void> _seedSelectedData() async {
    if (_selectedCount == 0) {
      setState(() => _message = '⚠️ 생성할 항목을 선택해주세요');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _message = '더미 데이터 생성 중...';
    });

    try {
      // 전체 선택인 경우 seedAll 호출
      if (_isAllSelected) {
        await _seedData.seedAll();
      } else {
        // 항목별 생성
        if (_selectedCategories[DataCategory.pets]!) {
          await _seedData.seedPets();
        }
        if (_selectedCategories[DataCategory.products]!) {
          await _seedData.seedProducts();
        }
        if (_selectedCategories[DataCategory.groups]!) {
          await _seedData.seedGroups();
        }
        if (_selectedCategories[DataCategory.jobs]!) {
          await _seedData.seedJobs();
        }
        if (_selectedCategories[DataCategory.breeding]!) {
          await _seedData.seedBreedingPosts();
        }
        if (_selectedCategories[DataCategory.likesMatches]!) {
          await _seedData.seedLikesAndMatches();
        }
        if (_selectedCategories[DataCategory.chats]!) {
          await _seedData.seedChats();
        }
        if (_selectedCategories[DataCategory.ratings]!) {
          await _seedData.seedRatings();
        }
        if (_selectedCategories[DataCategory.healthRecords]!) {
          await _seedData.seedHealthRecords();
        }
      }
      
      // 상태 관리 새로고침
      ref.invalidate(collectionCountsProvider);
      
      setState(() {
        _message = '✅ 선택한 데이터 생성 완료!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSelectedData() async {
    if (_selectedCount == 0) {
      setState(() => _message = '⚠️ 삭제할 항목을 선택해주세요');
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 경고'),
        content: Text(
          _isAllSelected 
            ? '모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'
            : '선택한 $_selectedCount개 항목의 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = '데이터 삭제 중...';
    });

    try {
      // 전체 선택인 경우 clearAllData 호출
      if (_isAllSelected) {
        await _seedData.clearAllData();
      } else {
        // 항목별 삭제
        if (_selectedCategories[DataCategory.pets]!) {
          await _seedData.clearPets();
        }
        if (_selectedCategories[DataCategory.products]!) {
          await _seedData.clearProducts();
        }
        if (_selectedCategories[DataCategory.groups]!) {
          await _seedData.clearGroups();
        }
        if (_selectedCategories[DataCategory.jobs]!) {
          await _seedData.clearJobs();
        }
        if (_selectedCategories[DataCategory.breeding]!) {
          await _seedData.clearBreedingPosts();
        }
        if (_selectedCategories[DataCategory.likesMatches]!) {
          await _seedData.clearLikesAndMatches();
        }
        if (_selectedCategories[DataCategory.chats]!) {
          await _seedData.clearChats();
        }
        if (_selectedCategories[DataCategory.ratings]!) {
          await _seedData.clearRatings();
        }
        if (_selectedCategories[DataCategory.healthRecords]!) {
          await _seedData.clearHealthRecords();
        }
      }
      
      // 상태 관리 새로고침
      ref.invalidate(collectionCountsProvider);
      
      setState(() {
        _message = '✅ 선택한 데이터 삭제 완료';
      });
    } catch (e) {
      setState(() {
        _message = '❌ 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // admin 계정 접근 제한 확인
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = currentUser?.email == 'admin@mingrr.com';
    
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🚫 접근 불가'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                '관리자 전용 페이지입니다',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'admin@mingrr.com 계정으로 로그인해주세요',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ 개발자 도구'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: '메인으로',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 안내
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase 테스트 데이터 관리',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '항목을 선택하고 생성 또는 삭제 버튼을 눌러주세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // 체크박스 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 전체 선택
                Card(
                  color: Colors.orange.shade100,
                  child: CheckboxListTile(
                    value: _isAllSelected,
                    onChanged: _isLoading ? null : _toggleAll,
                    title: const Text(
                      '전체 선택',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$_selectedCount / ${DataCategory.values.length}개 선택됨'),
                    secondary: const Icon(Icons.select_all),
                    activeColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                
                // 항목별 체크박스
                ...DataCategory.values.map((category) {
                  final countsAsync = ref.watch(collectionCountsProvider);
                  final count = countsAsync.valueOrNull?[category] ?? 0;
                  final description = _getCategoryDescription(category, count);
                  
                  return Card(
                    child: CheckboxListTile(
                      value: _selectedCategories[category],
                      onChanged: _isLoading ? null : (v) => _toggleCategory(category, v),
                      title: Text(category.label),
                      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
                      secondary: Icon(category.icon, color: Colors.orange),
                      activeColor: Colors.orange,
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
                
                // 생성/삭제 버튼
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _seedSelectedData,
                        icon: const Icon(Icons.add_circle),
                        label: const Text('생성'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _clearSelectedData,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('삭제'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 로딩 표시
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                
                // 메시지 표시
                if (_message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _message.startsWith('✅')
                          ? Colors.green.shade50
                          : _message.startsWith('⚠️')
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _message.startsWith('✅')
                            ? Colors.green
                            : _message.startsWith('⚠️')
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _message.startsWith('✅')
                            ? Colors.green.shade900
                            : _message.startsWith('⚠️')
                                ? Colors.orange.shade900
                                : Colors.red.shade900,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                
                // ===== 공통 팝업 테스트 섹션 =====
                const Text(
                  '📦 공통 팝업 컴포넌트 테스트',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '프로젝트에서 사용하는 공통 팝업들을 테스트합니다.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // 1. ErrorDialog (오류 팝업)
                _buildPopupTestSection(
                  title: '1. ErrorDialog (오류 팝업)',
                  description: '오류 발생 시 재시도/취소 선택 제공',
                  color: Colors.red,
                  children: [
                    _buildTestButton(context, '위치 오류', Icons.location_off, Colors.red,
                      () => showErrorDialog(context, type: ErrorType.location)),
                    _buildTestButton(context, '네트워크 오류', Icons.wifi_off, Colors.red,
                      () => showErrorDialog(context, type: ErrorType.network)),
                    _buildTestButton(context, '서버 오류', Icons.cloud_off, Colors.red,
                      () => showErrorDialog(context, type: ErrorType.server)),
                    _buildTestButton(context, 'DB 오류', Icons.storage, Colors.red,
                      () => showErrorDialog(context, type: ErrorType.database)),
                    _buildTestButton(context, '권한 오류', Icons.lock, Colors.orange,
                      () => showErrorDialog(context, type: ErrorType.permission)),
                    _buildTestButton(context, '타임아웃', Icons.timer_off, Colors.orange,
                      () => showErrorDialog(context, type: ErrorType.timeout)),
                    _buildTestButton(context, '인증 오류', Icons.person_off, Colors.red,
                      () => showErrorDialog(context, type: ErrorType.auth)),
                    _buildTestButton(context, '일반 오류', Icons.warning, Colors.red,
                      () => showErrorDialog(context, type: ErrorType.general)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 2. AppDialog (알림/확인 팝업)
                _buildPopupTestSection(
                  title: '2. AppDialog (알림/확인 팝업)',
                  description: '정보 알림 또는 확인/취소 선택',
                  color: Colors.blue,
                  children: [
                    _buildTestButton(context, '정보', Icons.info_outline, Theme.of(context).colorScheme.primary,
                      () => showAppDialog(context, type: DialogType.info, message: '정보 알림 메시지입니다.')),
                    _buildTestButton(context, '성공', Icons.check_circle_outline, context.features.success,
                      () => showAppDialog(context, type: DialogType.success, message: '작업이 성공적으로 완료되었습니다.')),
                    _buildTestButton(context, '경고', Icons.warning_amber, Colors.orange,
                      () => showAppDialog(context, type: DialogType.warning, message: '주의가 필요한 상황입니다.')),
                    _buildTestButton(context, '오류', Icons.error_outline, Colors.red,
                      () => showAppDialog(context, type: DialogType.error, message: '오류가 발생했습니다.')),
                    _buildTestButton(context, '확인/취소', Icons.help_outline, Theme.of(context).colorScheme.primary,
                      () => showAppDialog(context, type: DialogType.warning, title: '확인', message: '계속 진행하시겠습니까?', showCancel: true)),
                    _buildTestButton(context, '삭제 확인', Icons.delete, Colors.red,
                      () => showAppDialog(context, type: DialogType.error, title: '삭제', message: '정말 삭제하시겠습니까?', showCancel: true, confirmText: '삭제')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 3. ConfirmSheet (확인 바텀시트)
                _buildPopupTestSection(
                  title: '3. ConfirmSheet (확인 바텀시트)',
                  description: '하단에서 올라오는 확인/취소 시트',
                  color: Colors.teal,
                  children: [
                    _buildTestButton(context, '모임 탈퇴', Icons.exit_to_app, context.features.social,
                      () async { showConfirmSheet(context, type: ConfirmSheetType.groupLeave, onConfirm: () {}); return null; }),
                    _buildTestButton(context, '상품 삭제', Icons.delete, context.features.market,
                      () async { showConfirmSheet(context, type: ConfirmSheetType.productDelete, onConfirm: () {}); return null; }),
                    _buildTestButton(context, '채팅방 나가기', Icons.chat, context.features.chat,
                      () async { showConfirmSheet(context, type: ConfirmSheetType.chatLeave, onConfirm: () {}); return null; }),
                    _buildTestButton(context, '반려동물 삭제', Icons.pets, Theme.of(context).colorScheme.primary,
                      () async { showConfirmSheet(context, type: ConfirmSheetType.petDelete, onConfirm: () {}); return null; }),
                    _buildTestButton(context, '산책 기록 삭제', Icons.directions_walk, context.features.walk,
                      () async { showConfirmSheet(context, type: ConfirmSheetType.walkRecordDelete, onConfirm: () {}); return null; }),
                    _buildTestButton(context, '계정 삭제', Icons.person_remove, Colors.red,
                      () async { showConfirmSheet(context, type: ConfirmSheetType.accountDelete, onConfirm: () {}); return null; }),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 4. 위치 서비스 테스트
                _buildPopupTestSection(
                  title: '4. 위치 서비스 테스트',
                  description: '3단계 전략 위치 획득 테스트 (캐시→medium→low)',
                  color: context.features.walk,
                  children: [
                    _buildTestButton(context, '지도용 위치', Icons.map, context.features.walk,
                      () => _testLocationService(context, LocationPurpose.map)),
                    _buildTestButton(context, '산책용 위치', Icons.directions_walk, context.features.walk,
                      () => _testLocationService(context, LocationPurpose.walk)),
                    _buildTestButton(context, 'High 정확도', Icons.gps_fixed, Colors.green,
                      () => _testHighAccuracyLocation(context)),
                    _buildTestButton(context, '로딩 애니메이션', Icons.pets, context.features.walk,
                      () => _showLoadingAnimationTest(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 위치 서비스 테스트
  Future<String> _testLocationService(BuildContext context, LocationPurpose purpose) async {
    final startTime = DateTime.now();
    
    // 진행 상태 표시용 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LocationTestDialog(purpose: purpose),
    );
    
    final result = await LocationHelper.getCurrentLocation(purpose: purpose);
    
    if (context.mounted) {
      Navigator.of(context).pop(); // 다이얼로그 닫기
    }
    
    final elapsed = DateTime.now().difference(startTime);
    
    if (result.isSuccess) {
      return '✅ 성공 (${result.source?.name ?? "unknown"})\n'
          '위치: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}\n'
          '소요시간: ${elapsed.inMilliseconds}ms';
    } else {
      return '❌ 실패 (${result.errorType?.name ?? "unknown"})\n'
          '메시지: ${result.message}\n'
          '소요시간: ${elapsed.inMilliseconds}ms';
    }
  }
  
  /// High 정확도 위치 테스트
  Future<String> _testHighAccuracyLocation(BuildContext context) async {
    final startTime = DateTime.now();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('High 정확도 위치 획득 중...'),
          ],
        ),
      ),
    );
    
    final position = await LocationHelper.getHighAccuracyPosition();
    
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    final elapsed = DateTime.now().difference(startTime);
    
    if (position != null) {
      return '✅ 성공\n'
          '위치: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n'
          '정확도: ${position.accuracy.toStringAsFixed(1)}m\n'
          '소요시간: ${elapsed.inMilliseconds}ms';
    } else {
      return '❌ 실패\n소요시간: ${elapsed.inMilliseconds}ms';
    }
  }
  
  /// 로딩 애니메이션 테스트
  Future<void> _showLoadingAnimationTest(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              Expanded(child: MapLoadingWidget.walk()),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
    return;
  }
  
  /// 팝업 테스트 섹션 빌더
  Widget _buildPopupTestSection({
    required String title,
    required String description,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
  
  /// 테스트 버튼 빌더
  Widget _buildTestButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Future<dynamic> Function() onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await onPressed();
        if (context.mounted && result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('결과: $result'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
      ),
    );
  }
}

/// 위치 테스트 진행 상태 다이얼로그
class _LocationTestDialog extends StatefulWidget {
  final LocationPurpose purpose;
  
  const _LocationTestDialog({required this.purpose});
  
  @override
  State<_LocationTestDialog> createState() => _LocationTestDialogState();
}

class _LocationTestDialogState extends State<_LocationTestDialog> {
  LocationProgress? _progress;
  
  @override
  void initState() {
    super.initState();
    _startLocationTest();
  }
  
  Future<void> _startLocationTest() async {
    await LocationHelper.getCurrentLocation(
      purpose: widget.purpose,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      },
    );
  }
  
  String get _progressText {
    switch (_progress) {
      case LocationProgress.checkingPermission:
        return '권한 확인 중...';
      case LocationProgress.checkingCache:
        return '캐시 확인 중...';
      case LocationProgress.gettingGpsMedium:
        return 'GPS 신호 찾는 중 (medium)...';
      case LocationProgress.gettingGpsLow:
        return 'GPS 신호 찾는 중 (low)...';
      case null:
        return '준비 중...';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '${widget.purpose == LocationPurpose.map ? "지도용" : "산책용"} 위치 획득',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_progressText),
        ],
      ),
    );
  }
}
