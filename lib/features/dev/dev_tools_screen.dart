import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/seed_data.dart';
import '../auth/presentation/providers/auth_provider.dart';

/// 데이터 항목 정의 (사용자 계정은 Firebase Auth에서 관리하므로 제외)
enum DataCategory {
  pets('반려동물', Icons.pets),
  products('상품', Icons.shopping_bag),
  groups('소모임', Icons.groups),
  jobs('알바', Icons.work),
  likesMatches('좋아요/매칭', Icons.favorite),
  chats('채팅', Icons.chat);

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
    
    final likesCount = (await _firebaseService.likesCollection.get()).docs.length;
    final matchesCount = (await _firebaseService.matchesCollection.get()).docs.length;
    counts[DataCategory.likesMatches] = likesCount + matchesCount;
    
    counts[DataCategory.chats] = (await _firebaseService.chatRoomsCollection.get()).docs.length;
    
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
      case DataCategory.likesMatches:
        return '좋아요/매칭 ${count}개';
      case DataCategory.chats:
        return '채팅방 ${count}개';
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
        if (_selectedCategories[DataCategory.likesMatches]!) {
          await _seedData.seedLikesAndMatches();
        }
        if (_selectedCategories[DataCategory.chats]!) {
          await _seedData.seedChats();
        }
      }
      
      // Provider 리프레시
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
        if (_selectedCategories[DataCategory.likesMatches]!) {
          await _seedData.clearLikesAndMatches();
        }
        if (_selectedCategories[DataCategory.chats]!) {
          await _seedData.clearChats();
        }
      }
      
      // Provider 리프레시
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
