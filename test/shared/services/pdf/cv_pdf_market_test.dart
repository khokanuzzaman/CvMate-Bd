import 'dart:convert';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../../helpers/pdf_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Gulf PDF: photo, passport details, Letter paper and Bangla all render',
    () async {
      final photo = img.encodeJpg(img.Image(width: 35, height: 45));
      final cv = CvProfile.empty().copyWith(
        personalInfo: const PersonalInfo(
          fullName: 'Rakibul Islam',
          desiredRole: 'Site Engineer',
          email: 'rakib@email.com',
          phone: '+971501234567',
        ),
        style: CvStyle.gulf,
        paperSize: PaperSize.letter,
        shownFields: CvStyle.gulf.defaultFields,
        photo: photo,
        details: const PersonalDetails(
          nationality: 'Bangladeshi',
          passportNumber: 'A01234567',
          passportExpiry: '2031',
          religion: 'Hidden religion', // not shown in the Gulf style
        ),
        declaration: const CvDeclaration(
          text: 'আমি এতদ্বারা ঘোষণা করছি',
          place: 'Dubai',
        ),
      );

      final bytes = await const CvPdfService().generateCvPdf(
        profile: cv.copyWith(
          shownFields: {...cv.shownFields, PersonalField.declaration},
        ),
        compress: false,
      );
      final raw = latin1.decode(bytes);
      final text = await pdfText(cv);

      expect(text, contains('Passport: A01234567 · 2031'));
      expect(text, contains('Nationality: Bangladeshi'));
      expect(text, isNot(contains('Hidden religion')));
      expect(raw, contains('/Subtype/Image'), reason: 'the photo is embedded');
      expect(raw, contains('MediaBox[0 0 612 792]'), reason: 'Letter paper');
      expect(
        raw,
        contains('NotoSansBengali'),
        reason: 'Bangla uses the bundled font instead of printing boxes',
      );
    },
  );
}
