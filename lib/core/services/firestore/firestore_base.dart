import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

/// FirestoreService 도메인 mixin들이 공유하는 base 클래스
/// 
/// [firebase]와 [firestore] 접근자를 제공하여
/// 각 도메인 mixin이 Firestore 컬렉션에 접근할 수 있게 합니다.
/// 
/// 사용 예:
/// ```dart
/// mixin UserFirestore on FirestoreBase { ... }
/// class FirestoreService extends FirestoreBase with UserFirestore, PetFirestore { ... }
/// ```
abstract class FirestoreBase {
  final FirebaseService firebase = FirebaseService();
  
  FirebaseFirestore get firestore => firebase.firestore;
}
