import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';

/// What a personal field is called when it is printed (preview).
String personalFieldLabel(PersonalField field) => switch (field) {
  PersonalField.photo => AppStrings.personalFieldPhoto,
  PersonalField.dateOfBirth => AppStrings.personalFieldDob,
  PersonalField.nationality => AppStrings.personalFieldNationality,
  PersonalField.passport => AppStrings.personalPassportLabel,
  PersonalField.visaStatus => AppStrings.personalFieldVisa,
  PersonalField.drivingLicence => AppStrings.personalFieldLicence,
  PersonalField.maritalStatus => AppStrings.personalFieldMarital,
  PersonalField.religion => AppStrings.personalFieldReligion,
  PersonalField.gender => AppStrings.personalFieldGender,
  PersonalField.declaration => AppStrings.declarationAdd,
  PersonalField.signature => AppStrings.signatureTitle,
};
