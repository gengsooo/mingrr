import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/marketplace_model.dart';
import '../../utils/app_logger.dart';
import 'firestore_base.dart';

/// 알바(Job) 도메인 Firestore CRUD mixin
mixin JobFirestore on FirestoreBase {

  Future<void> createJob(JobModel job) async {
    try {
      await firebase.jobsCollection.doc(job.id).set(job.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createJob (jobId: ${job.id})', e);
      rethrow;
    }
  }

  Future<JobModel?> getJob(String jobId) async {
    try {
      final doc = await firebase.jobsCollection.doc(jobId).get();
      if (!doc.exists) return null;
      return JobModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getJob (jobId: $jobId)', e);
      rethrow;
    }
  }

  Future<List<JobModel>> getJobs({int limit = 20, JobType? type}) async {
    try {
      Query<Map<String, dynamic>> query = firebase.jobsCollection
          .where('status', isEqualTo: 'recruiting');
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getJobs', e);
      rethrow;
    }
  }

  Stream<List<JobModel>> watchJobs({JobType? type}) {
    Query<Map<String, dynamic>> query = firebase.jobsCollection
        .where('status', isEqualTo: 'recruiting');
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await firebase.jobsCollection.doc(jobId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteJob (jobId: $jobId)', e);
      rethrow;
    }
  }

  /// 알바 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<JobModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getJobsPaginated({
    JobType? type,
    String? status,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.jobsCollection;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }
}
