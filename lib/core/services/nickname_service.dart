import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import '../constants/forbidden_words.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// 닉네임 서비스
/// 
/// 기능:
/// - 닉네임 중복 체크 (nicknames 컬렉션 사용)
/// - 자동 닉네임 생성 (형용사 + 명사 + 숫자)
/// - 닉네임 변경 (트랜잭션 처리)
/// - 닉네임 유효성 검사
/// ============================================================
class NicknameService {
  static final _firebase = FirebaseService();
  static final _random = Random();
  
  /// nicknames 컬렉션 참조
  static CollectionReference<Map<String, dynamic>> get _nicknamesCollection =>
      _firebase.firestore.collection('nicknames');

  // ===== 닉네임 생성용 단어 목록 =====
  
  /// 형용사 목록 (반려동물 앱 테마)
  static const List<String> _adjectives = [
    '행복한', '귀여운', '사랑스런', '멋진', '신나는',
    '즐거운', '따뜻한', '포근한', '활발한', '씩씩한',
    '용감한', '똑똑한', '착한', '예쁜', '깜찍한',
    '발랄한', '상냥한', '다정한', '명랑한', '건강한',
    '튼튼한', '재빠른', '느긋한', '졸린', '배고픈',
    '장난꾸러기', '호기심많은', '충성스런', '순수한', '천진난만한',
  ];
  
  /// 명사 목록 (반려동물 관련)
  static const List<String> _nouns = [
    '강아지', '댕댕이', '멍멍이', '뽀삐', '초코',
    '콩이', '두부', '모찌', '구름이', '별이',
    '달이', '해피', '러키', '코코', '보리',
    '밤이', '호두', '땅콩', '치즈', '버터',
    '푸딩', '마카롱', '쿠키', '도넛', '젤리',
    '사탕', '솜사탕', '눈송이', '꽃잎', '나비',
  ];

  // ===== 닉네임 규칙 상수 =====
  
  /// 최소 길이
  static const int minLength = 2;
  
  /// 최대 길이
  static const int maxLength = 12;
  
  /// 허용 문자 정규식 (한글, 영문, 숫자만)
  static final RegExp _allowedPattern = RegExp(r'^[가-힣a-zA-Z0-9]+$');

  // ===== 닉네임 유효성 검사 =====
  
  /// 닉네임 유효성 검사
  /// 반환값: null이면 유효, 문자열이면 에러 메시지
  static String? validate(String nickname) {
    final trimmed = nickname.trim();
    
    if (trimmed.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    
    if (trimmed.length < minLength) {
      return '닉네임은 $minLength자 이상이어야 합니다';
    }
    
    if (trimmed.length > maxLength) {
      return '닉네임은 $maxLength자 이하여야 합니다';
    }
    
    if (!_allowedPattern.hasMatch(trimmed)) {
      return '한글, 영문, 숫자만 사용할 수 있습니다';
    }
    
    // 금지어 체크 (필요시 확장)
    if (_containsForbiddenWord(trimmed)) {
      return '사용할 수 없는 닉네임입니다';
    }
    
    return null;
  }
  
  /// 금지어 포함 여부 체크 (ForbiddenWords 클래스 사용)
  static bool _containsForbiddenWord(String nickname) {
    return ForbiddenWords.contains(nickname);
  }

  // ===== 닉네임 중복 체크 =====
  
  /// 닉네임 사용 가능 여부 확인 (빠른 체크 - nicknames 컬렉션 사용)
  /// [nickname] 체크할 닉네임
  /// [excludeUserId] 본인 ID (수정 시 본인 제외)
  /// 반환값: true = 사용 가능, false = 이미 사용 중
  static Future<bool> isAvailable(String nickname, {String? excludeUserId}) async {
    try {
      final normalizedNickname = _normalize(nickname);
      final doc = await _nicknamesCollection.doc(normalizedNickname).get();
      
      if (!doc.exists) return true;
      
      // 본인인 경우 사용 가능
      if (excludeUserId != null) {
        final data = doc.data();
        if (data != null && data['userId'] == excludeUserId) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      AppLogger.error('NicknameService', '닉네임 중복 체크 실패', e);
      // 에러 시 users 컬렉션으로 폴백
      return _isAvailableFallback(nickname, excludeUserId: excludeUserId);
    }
  }
  
  /// 닉네임 중복 체크 폴백 (users 컬렉션 직접 조회)
  static Future<bool> _isAvailableFallback(String nickname, {String? excludeUserId}) async {
    try {
      final query = await _firebase.usersCollection
          .where('nickname', isEqualTo: nickname.trim())
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return true;
      
      if (excludeUserId != null && query.docs.first.id == excludeUserId) {
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('NicknameService', '닉네임 중복 체크 폴백 실패', e);
      rethrow;
    }
  }
  
  /// 닉네임 정규화 (소문자 변환, 공백 제거)
  static String _normalize(String nickname) {
    return nickname.trim().toLowerCase();
  }

  // ===== 자동 닉네임 생성 =====
  
  /// 고유한 닉네임 자동 생성
  /// 형식: 형용사 + 명사 + 4자리 숫자 (예: "행복한강아지1234")
  /// 최대 5회 시도 후 실패 시 UUID 기반 닉네임 반환
  static Future<String> generateUnique() async {
    const maxAttempts = 5;
    
    for (int i = 0; i < maxAttempts; i++) {
      final nickname = _generateRandom();
      final isAvailable = await NicknameService.isAvailable(nickname);
      
      if (isAvailable) {
        return nickname;
      }
    }
    
    // 모든 시도 실패 시 타임스탬프 기반 닉네임
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return '새친구$timestamp';
  }
  
  /// 랜덤 닉네임 생성 (중복 체크 없음)
  static String _generateRandom() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    final number = _random.nextInt(9000) + 1000; // 1000~9999
    
    return '$adjective$noun$number';
  }

  // ===== 닉네임 등록/변경 =====
  
  /// 새 닉네임 등록 (회원가입 시)
  /// nicknames 컬렉션에 문서 생성
  static Future<void> register(String userId, String nickname) async {
    try {
      final normalizedNickname = _normalize(nickname);
      
      await _nicknamesCollection.doc(normalizedNickname).set({
        'userId': userId,
        'originalNickname': nickname.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('NicknameService', '닉네임 등록 완료: $nickname (userId: $userId)');
    } catch (e) {
      AppLogger.error('NicknameService', '닉네임 등록 실패', e);
      // 등록 실패해도 회원가입은 진행 (폴백으로 users 컬렉션만 사용)
    }
  }
  
  /// 닉네임 변경 (트랜잭션 처리)
  /// 1. 기존 nicknames 문서 존재 확인 후 삭제
  /// 2. 새 nicknames 문서 생성
  /// 3. users 문서 업데이트
  static Future<void> change({
    required String userId,
    required String oldNickname,
    required String newNickname,
  }) async {
    final normalizedOld = _normalize(oldNickname);
    final normalizedNew = _normalize(newNickname);
    
    // 같은 닉네임이면 스킵
    if (normalizedOld == normalizedNew) return;
    
    try {
      await _firebase.firestore.runTransaction((transaction) async {
        // 1. 새 닉네임 중복 체크
        final newDoc = await transaction.get(_nicknamesCollection.doc(normalizedNew));
        if (newDoc.exists) {
          final data = newDoc.data();
          if (data != null && data['userId'] != userId) {
            throw Exception('이미 사용 중인 닉네임입니다');
          }
        }
        
        // 2. 기존 닉네임 문서 존재 확인 후 삭제 (없으면 스킵)
        final oldDoc = await transaction.get(_nicknamesCollection.doc(normalizedOld));
        if (oldDoc.exists) {
          final oldData = oldDoc.data();
          // 본인 문서인 경우에만 삭제
          if (oldData != null && oldData['userId'] == userId) {
            transaction.delete(_nicknamesCollection.doc(normalizedOld));
          }
        }
        
        // 3. 새 닉네임 문서 생성
        transaction.set(_nicknamesCollection.doc(normalizedNew), {
          'userId': userId,
          'originalNickname': newNickname.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // 4. users 문서 업데이트
        transaction.update(_firebase.usersCollection.doc(userId), {
          'nickname': newNickname.trim(),
          'nicknameChangedAt': FieldValue.serverTimestamp(),
        });
      });
      
      AppLogger.info('NicknameService', '닉네임 변경 완료: $oldNickname → $newNickname');
    } catch (e) {
      AppLogger.error('NicknameService', '닉네임 변경 실패', e);
      rethrow;
    }
  }
  
  /// 닉네임 삭제 (회원 탈퇴 시)
  static Future<void> delete(String nickname) async {
    try {
      final normalizedNickname = _normalize(nickname);
      await _nicknamesCollection.doc(normalizedNickname).delete();
      AppLogger.info('NicknameService', '닉네임 삭제 완료: $nickname');
    } catch (e) {
      AppLogger.error('NicknameService', '닉네임 삭제 실패', e);
      // 삭제 실패해도 회원 탈퇴는 진행
    }
  }
}
