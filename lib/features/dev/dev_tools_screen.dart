import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/seed_data.dart';
import '../../core/widgets/dividers/app_dividers.dart';
import '../auth/presentation/providers/auth_provider.dart';

/// 데이터 항목 정의 (사용자 계정은 Firebase Auth에서 관리하므로 제외)
enum DataCategory {
  pets('반려동물', AppIcons.pet),
  products('상품', AppIcons.shoppingBag),
  groups('소모임', AppIcons.group),
  groupSchedules('소모임 일정', AppIcons.event),
  jobs('알바', AppIcons.work),
  breeding('교배', AppIcons.likeOutlined),
  likesMatches('좋아요/매칭', AppIcons.like),
  chats('채팅', AppIcons.chat),
  communityPosts('커뮤니티', AppIcons.community),
  ratings('꼼순내 평가', AppIcons.star),
  healthRecords('건강수첩', AppIcons.health);

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
    
    final likesCount = (await _firebaseService.datingRequestsCollection.get()).docs.length;
    final matchesCount = (await _firebaseService.matchesCollection.get()).docs.length;
    counts[DataCategory.likesMatches] = likesCount + matchesCount;
    
    counts[DataCategory.chats] = (await _firebaseService.chatRoomsCollection.get()).docs.length;
    
    // 커뮤니티 게시글 데이터 개수
    counts[DataCategory.communityPosts] = (await _firebaseService.feedPostsCollection.get()).docs.length;
    
    // 소모임 일정 데이터 개수
    counts[DataCategory.groupSchedules] = (await _firebaseService.firestore.collection('schedules').get()).docs.length;
    
    // 꼬순내 평가 데이터 개수
    counts[DataCategory.ratings] = (await _firebaseService.ratingsCollection.get()).docs.length;
    
    // 건강수첩 데이터 개수 (여러 컴렉션 합산)
    int healthCount = 0;
    healthCount += (await _firebaseService.firestore.collection('weightRecords').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('walkRecords').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('groomingRecords').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('vaccinationRecords').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('checkupRecords').get()).docs.length;
    healthCount += (await _firebaseService.firestore.collection('medicationRecords').get()).docs.length;
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
      case DataCategory.groupSchedules:
        return '소모임 일정 ${count}개';
      case DataCategory.jobs:
        return '알바 ${count}개';
      case DataCategory.breeding:
        return '교배 글 ${count}개';
      case DataCategory.likesMatches:
        return '좋아요/매칭 ${count}개';
      case DataCategory.chats:
        return '채팅방 ${count}개';
      case DataCategory.communityPosts:
        return '커뮤니티 게시글 ${count}개';
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
        if (_selectedCategories[DataCategory.communityPosts]!) {
          await _seedData.seedCommunityPosts();
        }
        if (_selectedCategories[DataCategory.groupSchedules]!) {
          await _seedData.seedGroupSchedules();
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

  Future<void> _clearTestDataOnly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧹 테스트 데이터 삭제'),
        content: const Text(
          'test_ 접두사로 시작하는 테스트 데이터만 삭제합니다.\n실제 사용자 데이터는 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = '테스트 데이터 삭제 중...';
    });

    try {
      await _seedData.clearTestDataOnly();
      ref.invalidate(collectionCountsProvider);
      
      setState(() {
        _message = '✅ 테스트 데이터만 삭제 완료!';
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
        if (_selectedCategories[DataCategory.communityPosts]!) {
          await _seedData.clearCommunityPosts();
        }
        if (_selectedCategories[DataCategory.groupSchedules]!) {
          await _seedData.clearGroupSchedules();
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

  Future<void> _seedUserLocations() async {
    setState(() {
      _isLoading = true;
      _message = '사용자 위치 정보 생성 중...';
    });

    try {
      await _seedData.seedUserLocations();
      ref.invalidate(collectionCountsProvider);
      
      setState(() {
        _message = '✅ 사용자 위치 정보 생성 완료!';
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
              Icon(AppIcons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                '관리자 전용 페이지입니다',
                style: AppTextStyles.headlineMedium(context),
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
            icon: Icon(AppIcons.home),
            onPressed: () => context.go('/'),
            tooltip: '메인으로',
          ),
          IconButton(
            icon: Icon(AppIcons.logout),
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
            padding: const EdgeInsets.all(AppSizes.paddingL),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase 테스트 데이터 관리',
                  style: AppTextStyles.headlineSmall(context),
                ),
                const SizedBox(height: 4),
                Text(
                  '항목을 선택하고 생성 또는 삭제 버튼을 눌러주세요.',
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
          
          // 체크박스 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
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
                    secondary: Icon(AppIcons.selectAll),
                    activeColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const MingrrDivider(),
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
                      subtitle: Text(description, style: AppTextStyles.caption(context)),
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
                        icon: Icon(AppIcons.addCircle),
                        label: const Text('생성'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(AppSizes.paddingL),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _clearSelectedData,
                        icon: Icon(AppIcons.deleteForever),
                        label: const Text('전체 삭제'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(AppSizes.paddingL),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 테스트 데이터만 삭제 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearTestDataOnly,
                    icon: Icon(AppIcons.cleaning),
                    label: const Text('테스트 데이터만 삭제 (test_ 접두사)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSizes.paddingL),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 사용자 위치 정보 생성 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _seedUserLocations,
                    icon: Icon(AppIcons.location),
                    label: const Text('사용자 위치 정보 생성 (대한민국 전역)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSizes.paddingL),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 로딩 표시
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                
                // 메시지 표시
                if (_message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    decoration: BoxDecoration(
                      color: _message.startsWith('✅')
                          ? Colors.green.shade50
                          : _message.startsWith('⚠️')
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXS),
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
                
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}
