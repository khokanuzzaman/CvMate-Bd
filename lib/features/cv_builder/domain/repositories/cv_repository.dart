import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';

abstract class CvRepository {
  Future<List<CvProfile>> getAllCvs();

  Future<CvProfile?> getCvById(String id);

  Future<CvProfile> saveCv(CvProfile profile);

  Future<CvProfile> createEmptyCv({String? title});

  Future<CvProfile> duplicateCv(String id);

  Future<void> deleteCv(String id);

  Future<void> clearAllCvs();
}
