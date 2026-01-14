import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// ============================================================
/// 동물등록 정보조회 API 서비스
/// 
/// 농림축산검역본부 동물등록 정보조회 서비스 API 연동
/// - 동물등록번호 + 소유자 성명으로 조회
/// - 등록된 반려동물 정보 반환
/// ============================================================

class AnimalRegistrationService {
  AnimalRegistrationService._();
  
  /// 동물등록 정보 조회
  /// 
  /// [registrationNumber]: 동물등록번호 (15자리) 또는 RFID 코드
  /// [ownerName]: 소유자 성명
  /// 반환값: AnimalRegistrationResult
  static Future<AnimalRegistrationResult> verify({
    required String registrationNumber,
    required String ownerName,
  }) async {
    try {
      // URL 구성
      final queryParams = {
        'serviceKey': ApiConfig.animalRegistrationApiKey,
        'dog_reg_no': registrationNumber,
        'owner_nm': ownerName,
        '_type': 'json',
      };
      
      final url = Uri.parse('${ApiConfig.animalRegistrationBaseUrl}/animalInfo_v3')
          .replace(queryParameters: queryParams);
      
      debugPrint('동물등록 API 호출: $url');
      
      // API 호출
      final response = await http.get(url).timeout(
        Duration(seconds: ApiConfig.animalRegistrationTimeoutSeconds),
      );
      
      debugPrint('동물등록 API 응답 코드: ${response.statusCode}');
      debugPrint('동물등록 API 응답: ${response.body}');
      
      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        return AnimalRegistrationResult.error(
          errorCode: response.statusCode.toString(),
          errorMessage: 'HTTP 오류: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('동물등록 API 오류: $e');
      return AnimalRegistrationResult.error(
        errorCode: 'NETWORK_ERROR',
        errorMessage: '네트워크 오류가 발생했습니다.',
      );
    }
  }
  
  /// API 응답 파싱
  static AnimalRegistrationResult _parseResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      
      // 응답 구조 확인
      final header = data['response']?['header'] ?? data['header'];
      final body = data['response']?['body'] ?? data['body'];
      
      // 결과 코드 확인
      final resultCode = header?['resultCode']?.toString() ?? '';
      final resultMsg = header?['resultMsg']?.toString() ?? '';
      final errorMsg = header?['errorMsg']?.toString() ?? '';
      
      // 에러 처리
      if (resultCode != '00' && resultCode.isNotEmpty) {
        return AnimalRegistrationResult.error(
          errorCode: resultCode,
          errorMessage: _getErrorMessage(resultCode, resultMsg, errorMsg),
        );
      }
      
      // 데이터 확인
      final item = body?['item'];
      
      if (item == null || (item is Map && item.isEmpty)) {
        return AnimalRegistrationResult.error(
          errorCode: 'NO_DATA',
          errorMessage: '등록된 동물 정보를 찾을 수 없습니다.\n동물등록번호와 소유자 성명을 확인해주세요.',
        );
      }
      
      // 성공 - 동물 정보 파싱
      return AnimalRegistrationResult.success(
        animalInfo: AnimalInfo.fromJson(item),
      );
    } catch (e) {
      debugPrint('응답 파싱 오류: $e');
      return AnimalRegistrationResult.error(
        errorCode: 'PARSE_ERROR',
        errorMessage: '응답 처리 중 오류가 발생했습니다.',
      );
    }
  }
  
  /// 에러 코드별 메시지 반환
  static String _getErrorMessage(String code, String resultMsg, String errorMsg) {
    switch (code) {
      case '10':
        return '입력값을 확인해주세요.';
      case '11':
        return '동물등록번호와 소유자 성명을 모두 입력해주세요.';
      case '12':
        return '서비스가 일시적으로 중단되었습니다.';
      case '30':
        return '서비스 점검 중입니다. 잠시 후 다시 시도해주세요.';
      case '32':
        return '서비스 접근이 제한되었습니다.';
      case '01':
      case '02':
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case '99':
      default:
        return errorMsg.isNotEmpty ? errorMsg : (resultMsg.isNotEmpty ? resultMsg : '알 수 없는 오류가 발생했습니다.');
    }
  }
}

/// ============================================================
/// 동물등록 조회 결과
/// ============================================================
class AnimalRegistrationResult {
  /// 조회 성공 여부
  final bool isSuccess;
  
  /// 에러 코드
  final String? errorCode;
  
  /// 에러 메시지
  final String? errorMessage;
  
  /// 동물 정보 (성공 시)
  final AnimalInfo? animalInfo;
  
  const AnimalRegistrationResult._({
    required this.isSuccess,
    this.errorCode,
    this.errorMessage,
    this.animalInfo,
  });
  
  /// 성공 결과 생성
  factory AnimalRegistrationResult.success({required AnimalInfo animalInfo}) {
    return AnimalRegistrationResult._(
      isSuccess: true,
      animalInfo: animalInfo,
    );
  }
  
  /// 실패 결과 생성
  factory AnimalRegistrationResult.error({
    required String errorCode,
    required String errorMessage,
  }) {
    return AnimalRegistrationResult._(
      isSuccess: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

/// ============================================================
/// 동물 정보 모델
/// ============================================================
class AnimalInfo {
  /// 동물등록번호
  final String dogRegNo;
  
  /// RFID 코드
  final String? rfidCd;
  
  /// RFID 구분 (내장/외장)
  final String? rfidGubun;
  
  /// 반려동물 이름
  final String dogNm;
  
  /// 품종
  final String? kindNm;
  
  /// 성별 (수컷/암컷)
  final String? sexNm;
  
  /// 중성화 여부 (Y/N)
  final String? neuterYn;
  
  /// 생년월일 (YYYYMMDD)
  final String? birthDt;
  
  /// 등록기관
  final String? orgNm;
  
  /// 사무실 전화번호
  final String? officeTel;
  
  /// 등록일
  final String? regTm;
  
  /// 승인일
  final String? aprTm;
  
  /// 승인구분
  final String? aprGbNm;
  
  const AnimalInfo({
    required this.dogRegNo,
    this.rfidCd,
    this.rfidGubun,
    required this.dogNm,
    this.kindNm,
    this.sexNm,
    this.neuterYn,
    this.birthDt,
    this.orgNm,
    this.officeTel,
    this.regTm,
    this.aprTm,
    this.aprGbNm,
  });
  
  /// JSON에서 생성
  factory AnimalInfo.fromJson(Map<String, dynamic> json) {
    return AnimalInfo(
      dogRegNo: json['dogRegNo']?.toString() ?? '',
      rfidCd: json['rfidCd']?.toString(),
      rfidGubun: json['rfidGubun']?.toString(),
      dogNm: json['dogNm']?.toString() ?? '이름 없음',
      kindNm: json['kindNm']?.toString(),
      sexNm: json['sexNm']?.toString(),
      neuterYn: json['neuterYn']?.toString(),
      birthDt: json['birthDt']?.toString(),
      orgNm: json['orgNm']?.toString(),
      officeTel: json['officeTel']?.toString(),
      regTm: json['regTm']?.toString(),
      aprTm: json['aprTm']?.toString(),
      aprGbNm: json['aprGbNm']?.toString(),
    );
  }
  
  /// 중성화 여부 (boolean)
  bool get isNeutered => neuterYn?.toUpperCase() == 'Y';
  
  /// 성별 (PetGender 매칭용)
  /// 수컷 → male, 암컷 → female
  String get genderCode {
    if (sexNm == null) return 'unknown';
    if (sexNm!.contains('수') || sexNm!.toLowerCase().contains('male')) {
      return 'male';
    } else if (sexNm!.contains('암') || sexNm!.toLowerCase().contains('female')) {
      return 'female';
    }
    return 'unknown';
  }
  
  /// 생년월일 (DateTime)
  DateTime? get birthDate {
    if (birthDt == null || birthDt!.length < 8) return null;
    try {
      final year = int.parse(birthDt!.substring(0, 4));
      final month = int.parse(birthDt!.substring(4, 6));
      final day = int.parse(birthDt!.substring(6, 8));
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
  
  /// 생년월일 포맷팅 (YYYY.MM.DD)
  String get birthDateFormatted {
    if (birthDt == null || birthDt!.length < 8) return '정보 없음';
    try {
      return '${birthDt!.substring(0, 4)}.${birthDt!.substring(4, 6)}.${birthDt!.substring(6, 8)}';
    } catch (_) {
      return birthDt!;
    }
  }
  
  /// Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'dogRegNo': dogRegNo,
      'rfidCd': rfidCd,
      'rfidGubun': rfidGubun,
      'dogNm': dogNm,
      'kindNm': kindNm,
      'sexNm': sexNm,
      'neuterYn': neuterYn,
      'birthDt': birthDt,
      'orgNm': orgNm,
      'officeTel': officeTel,
      'regTm': regTm,
      'aprTm': aprTm,
      'aprGbNm': aprGbNm,
    };
  }
}
