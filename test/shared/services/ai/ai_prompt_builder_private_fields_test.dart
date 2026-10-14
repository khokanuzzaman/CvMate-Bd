import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('AI prompts never contain the private personal fields', () {
    final cv = CvProfile.empty().copyWith(
      personalInfo: const PersonalInfo(
        fullName: 'Rakibul Islam',
        desiredRole: 'Site Engineer',
      ),
      style: CvStyle.gulf,
      shownFields: PersonalField.values.toSet(),
      photo: img.encodeJpg(img.Image(width: 35, height: 45)),
      details: const PersonalDetails(
        dateOfBirth: '12 Mar 1996',
        nationality: 'Bangladeshi',
        passportNumber: 'A01234567',
        passportExpiry: '2031',
        visaStatus: 'Visit visa',
        maritalStatus: 'Married',
        religion: 'Zoroastrian',
        gender: 'Male',
        customRows: [DetailRow(id: 'r', label: 'Blood group', value: 'O+')],
      ),
    );

    const builder = AiPromptBuilder();
    final prompt = builder.generateProfessionalSummary(
      profile: cv,
      language: AiOutputLanguage.english,
      tone: AiTone.professional,
    );

    expect(prompt, contains('Rakibul Islam'), reason: 'sanity: name is sent');
    for (final private in [
      '12 Mar 1996',
      'A01234567',
      '2031',
      'Visit visa',
      'Married',
      'Zoroastrian',
      'Male',
      'Blood group',
      'Bangladeshi',
    ]) {
      expect(prompt, isNot(contains(private)), reason: private);
    }
  });
}
