import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final cvRemoteDataSourceProvider = Provider<CvRemoteDataSource>((ref) {
  return CvRemoteDataSource(ref.watch(firebaseFirestoreProvider));
});

/// Cloud mirror for CV profiles, stored per user at `users/{uid}/cvs/{cvId}`.
///
/// Reuses [CvProfileDto] for (de)serialization so the cloud copy uses the exact
/// same field format as the local Hive copy. All access is namespaced by uid;
/// callers must pass the signed-in user's uid and never a shared/other uid.
///
/// TODO(sync): cover letters and job-tracker data are NOT synced yet. When they
/// are, add sibling collections under `users/{uid}/` (e.g. `cover_letters`,
/// `job_applications`) rather than widening this CV-only source.
class CvRemoteDataSource {
  const CvRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _cvCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('cvs');
  }

  Future<void> upsert(String uid, CvProfileDto dto) {
    return _cvCollection(uid).doc(dto.profile.id).set(dto.toMap());
  }

  Future<void> delete(String uid, String id) {
    return _cvCollection(uid).doc(id).delete();
  }

  Future<List<CvProfileDto>> fetchAll(String uid) async {
    final snapshot = await _cvCollection(uid).get();
    return snapshot.docs.map((doc) => CvProfileDto.fromMap(doc.data())).toList();
  }
}
