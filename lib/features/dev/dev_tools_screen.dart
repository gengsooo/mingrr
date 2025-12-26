import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/seed_data.dart';
import '../auth/presentation/providers/auth_provider.dart';

class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  final SeedData _seedData = SeedData();
  bool _isLoading = false;
  String _message = '';

  Future<void> _seedAllData() async {
    setState(() {
      _isLoading = true;
      _message = '더미 데이터 생성 중...';
    });

    try {
      await _seedData.seedAll();
      setState(() {
        _message = '✅ 더미 데이터 생성 완료!';
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

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 경고'),
        content: const Text('모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
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
      await _seedData.clearAllData();
      setState(() {
        _message = '✅ 모든 데이터 삭제 완료';
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
              const Icon(
                Icons.lock,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                '관리자 전용 페이지입니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase 더미 데이터 관리',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '테스트용 더미 데이터를 생성하거나 삭제할 수 있습니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _seedAllData,
              icon: const Icon(Icons.add_circle),
              label: const Text('더미 데이터 생성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearAllData,
              icon: const Icon(Icons.delete_forever),
              label: const Text('모든 데이터 삭제'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () async {
                try {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그아웃 실패: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('✅')
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            
            const Spacer(),
            
            const Divider(),
            
            const Text(
              '생성되는 데이터:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• 사용자 10명'),
            const Text('• 강아지 6마리'),
            const Text('• 상품 5개'),
            const Text('• 모임 3개'),
          ],
        ),
      ),
    );
  }
}
