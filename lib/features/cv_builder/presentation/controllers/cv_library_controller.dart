import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cvLibraryControllerProvider =
    AsyncNotifierProvider<CvLibraryController, List<CvProfile>>(
      CvLibraryController.new,
    );

class CvLibraryController extends AsyncNotifier<List<CvProfile>> {
  @override
  Future<List<CvProfile>> build() {
    return ref.read(cvRepositoryProvider).getAllCvs();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cvRepositoryProvider).getAllCvs(),
    );
  }

  Future<CvProfile> duplicateCv(String id) async {
    final duplicated = await ref.read(cvRepositoryProvider).duplicateCv(id);
    await reload();
    return duplicated;
  }

  Future<void> deleteCv(String id) async {
    await ref.read(cvRepositoryProvider).deleteCv(id);
    await reload();
  }
}
