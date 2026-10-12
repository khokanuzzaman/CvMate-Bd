import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';

/// Match bands for the score headline on page 2.
const int kStrongMatchPercent = 80;
const int kGoodMatchPercent = 50;

String matchHeadline(int percent) {
  if (percent >= kStrongMatchPercent) {
    return AppStrings.tailorMatchStrong;
  }
  if (percent >= kGoodMatchPercent) {
    return AppStrings.tailorMatchGood;
  }
  return AppStrings.tailorMatchLow;
}

String matchBody({required bool hasMissingKeywords}) => hasMissingKeywords
    ? AppStrings.tailorMatchBodyMissing
    : AppStrings.tailorMatchBodyCovered;

/// Whether [skill] is new to the CV (so the result page highlights it as one
/// the tailoring brought forward) rather than a skill the CV already lists.
bool isNewSkill(CvProfile? cv, String skill) {
  final key = skill.trim().toLowerCase();
  if (cv == null) {
    return false;
  }
  return !cv.skills.any(
    (existing) => existing.name.trim().toLowerCase() == key,
  );
}
