import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';

/// In-memory [CvRepository] so builder tests need neither Hive nor Firebase.
class FakeCvRepository implements CvRepository {
  FakeCvRepository([Iterable<CvProfile> initial = const []]) {
    for (final profile in initial) {
      store[profile.id] = profile;
    }
  }

  final Map<String, CvProfile> store = {};
  int saveCount = 0;

  /// The most recently saved copy of [id].
  CvProfile? saved(String id) => store[id];

  @override
  Future<List<CvProfile>> getAllCvs() async => store.values.toList();

  @override
  Future<CvProfile?> getCvById(String id) async => store[id];

  @override
  Future<CvProfile> saveCv(CvProfile profile) async {
    store[profile.id] = profile;
    saveCount++;
    return profile;
  }

  @override
  Future<CvProfile> createEmptyCv({String? title}) async {
    final profile = CvProfile.empty().copyWith(title: title ?? 'New CV');
    store[profile.id] = profile;
    return profile;
  }

  @override
  Future<CvProfile> duplicateCv(String id) async => store[id]!;

  @override
  Future<void> deleteCv(String id) async => store.remove(id);

  @override
  Future<void> clearAllCvs() async => store.clear();
}
