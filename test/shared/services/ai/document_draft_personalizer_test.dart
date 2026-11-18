import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/document_draft_personalizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Any square-bracketed phrase that reads like a fill-in.
final _anyBracketPlaceholder = RegExp(
  r'\[[^\]\n]*\p{L}[^\]\n]*\]',
  unicode: true,
);

// The two real outputs seen on a device with the live model.
const _realSubject =
    'Application for Junior Flutter Developer Position – [Your Full Name]';
const _realBody =
    'Dear Hiring Manager,\n\n'
    'I am applying for the Junior Flutter Developer role at Acme.\n\n'
    'Yours sincerely,\n'
    '[Your Full Name]\n'
    '[Phone Number] | [Email Address]';

AiDocumentDraft _draft({
  String subject = _realSubject,
  String body = _realBody,
}) => AiDocumentDraft(
  title: 'Job application email',
  subjectLine: subject,
  body: body,
  highlights: const ['[Your Key Skill]', 'Flutter'],
  language: AiOutputLanguage.english,
  tone: AiTone.formal,
);

void main() {
  test('fills the CV name and contact, and never leaves a bracket '
      'placeholder', () {
    const info = PersonalInfo(
      fullName: 'Nusrat Jahan',
      phone: '+880 1711 000000',
      email: 'nusrat@example.com',
    );

    final email = personalizeDocumentDraft(
      _draft(),
      info: info,
      kind: AiDocumentKind.jobApplicationEmail,
    );
    expect(
      email.subjectLine,
      'Application for Junior Flutter Developer Position – Nusrat Jahan',
    );
    expect(
      email.body,
      endsWith(
        'Yours sincerely,\nNusrat Jahan\n+880 1711 000000 | nusrat@example.com',
      ),
    );

    // A clean draft (what the server now asks for) gets signed and the
    // subject gets the name, once.
    final clean = personalizeDocumentDraft(
      _draft(
        subject: 'Application for Junior Flutter Developer Position',
        body: 'Dear Hiring Manager,\n\nI am applying.\n\nYours sincerely,',
      ),
      info: info,
      kind: AiDocumentKind.jobApplicationEmail,
    );
    expect(clean.subjectLine, email.subjectLine);
    expect(clean.body, endsWith(email.body.split('\n\n').last));

    for (final draft in [email, clean]) {
      for (final text in [draft.subjectLine, draft.body, ...draft.highlights]) {
        expect(text, isNot(matches(_anyBracketPlaceholder)));
      }
    }
  });

  test('removes placeholders it cannot fill, with no leftover separators', () {
    const info = PersonalInfo(fullName: 'Rahim Uddin');

    final letter = personalizeDocumentDraft(
      _draft(body: '[Date]\n\nDear [Hiring Manager\'s Name],\n\n$_realBody'),
      info: info,
      kind: AiDocumentKind.coverLetter,
    );
    expect(letter.body, startsWith('Dear Hiring Manager,\n\n'));
    expect(letter.body, endsWith('Yours sincerely,\nRahim Uddin'));

    final noName = personalizeDocumentDraft(
      _draft(),
      info: const PersonalInfo(),
      kind: AiDocumentKind.jobApplicationEmail,
    );
    expect(
      noName.subjectLine,
      'Application for Junior Flutter Developer Position',
    );
    expect(noName.body, endsWith('Yours sincerely,'));

    for (final text in [letter.body, noName.subjectLine, noName.body]) {
      expect(text, isNot(matches(_anyBracketPlaceholder)));
    }
  });
}
