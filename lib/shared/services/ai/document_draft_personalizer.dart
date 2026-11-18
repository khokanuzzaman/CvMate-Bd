import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

/// Which kind of document an [AiDocumentDraft] is.
enum AiDocumentKind { coverLetter, jobApplicationEmail, linkedInMessage }

/// A bracketed fill-in such as "[Your Full Name]", "[Phone Number]" or
/// "[আপনার নাম]": square brackets around a short phrase that starts with a
/// letter. "[1]" or "[2 years]" do not match.
final RegExp bracketPlaceholderPattern = RegExp(
  r"\[\s*\p{L}[\p{L}\p{M}\p{N}'’ &/.,-]{0,48}\]",
  unicode: true,
);

/// The placeholder (its label in group 1) plus a separator after it, as in
/// "[Phone Number] | [Email Address]" (group 2).
final RegExp _placeholderWithSeparator = RegExp(
  r"\[\s*(\p{L}[\p{L}\p{M}\p{N}'’ &/.,-]{0,48})\](\s*[|–—•·/]\s*|\s+-\s+)?",
  unicode: true,
);

final RegExp _trailingSeparators = RegExp(r'[\s|–—•·/-]+$');

/// Labels ending in "name" that are not the candidate's name.
const List<String> _otherPeopleOrPlaces = [
  'manager',
  'hiring',
  'company',
  'recruiter',
  'recipient',
  'employer',
  'organization',
  'organisation',
  'person',
  'job',
  'position',
  'role',
  'university',
  'school',
];

/// Puts the candidate's own details into an AI draft, on the device.
///
/// The AI server never sends the name or contact details to the model, so the
/// model may leave fill-ins like "[Your Full Name]". This replaces them with
/// the CV's values (or removes them when the value is missing), signs cover
/// letters and job emails with the name (and phone | email when present), and
/// adds " – Name" to a job email's subject. The result never contains a
/// bracket placeholder.
AiDocumentDraft personalizeDocumentDraft(
  AiDocumentDraft draft, {
  required PersonalInfo info,
  required AiDocumentKind kind,
}) {
  final name = info.fullName.trim();
  var subject = fillPlaceholders(draft.subjectLine, info);
  var body = fillPlaceholders(draft.body, info);

  if (kind != AiDocumentKind.linkedInMessage) {
    body = _signed(body, info);
  }
  if (kind == AiDocumentKind.jobApplicationEmail &&
      subject.isNotEmpty &&
      name.isNotEmpty &&
      !_containsIgnoringCase(subject, name)) {
    subject = '$subject – $name';
  }

  return AiDocumentDraft(
    title: fillPlaceholders(draft.title, info),
    subjectLine: subject,
    body: body,
    highlights: draft.highlights
        .map((item) => fillPlaceholders(item, info))
        .where((item) => item.isNotEmpty)
        .toList(),
    language: draft.language,
    tone: draft.tone,
  );
}

/// Replaces each bracket placeholder in [text] with the matching value from
/// [info], or removes it (with the separator, blank line or dangling " – " it
/// leaves) when there is no value. Text without placeholders is unchanged.
String fillPlaceholders(String text, PersonalInfo info) {
  if (!bracketPlaceholderPattern.hasMatch(text)) {
    return text;
  }

  final lines = <String>[];
  for (final line in text.split('\n')) {
    if (!bracketPlaceholderPattern.hasMatch(line)) {
      lines.add(line);
      continue;
    }
    var cleaned = line
        .replaceAllMapped(_placeholderWithSeparator, (match) {
          final value = _valueFor(match.group(1)!, info);
          return value.isEmpty ? '' : '$value${match.group(2) ?? ''}';
        })
        .replaceAll(_trailingSeparators, '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAllMapped(RegExp(r'\s+([,.;:!?])'), (m) => m.group(1)!)
        .trim();
    if (RegExp(r'^dear\s*,$', caseSensitive: false).hasMatch(cleaned)) {
      cleaned = 'Dear Hiring Manager,';
    }
    if (cleaned.isNotEmpty) {
      lines.add(cleaned);
    }
  }

  return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String _valueFor(String label, PersonalInfo info) {
  final key = label
      .toLowerCase()
      .replaceAll(RegExp(r"['’]s\b"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (key.contains('phone') ||
      key.contains('mobile') ||
      key.contains('contact number')) {
    return info.phone.trim();
  }
  if (key.contains('email') || key.contains('e-mail')) {
    return info.email.trim();
  }
  if (key.contains('linkedin')) {
    return info.linkedInUrl.trim();
  }
  if (key == 'address' || key == 'your address') {
    return info.address.trim();
  }
  final isName =
      (key.endsWith('name') || key.contains('নাম')) &&
      !_otherPeopleOrPlaces.any(key.contains);
  return isName ? info.fullName.trim() : '';
}

/// Adds the name (and phone | email) under the sign-off unless the end of the
/// letter already has the name.
String _signed(String body, PersonalInfo info) {
  final name = info.fullName.trim();
  final trimmed = body.trimRight();
  if (name.isEmpty || trimmed.isEmpty) {
    return trimmed;
  }

  final lines = trimmed.split('\n');
  final tail = lines.skip(lines.length > 4 ? lines.length - 4 : 0).join('\n');
  if (_containsIgnoringCase(tail, name)) {
    return trimmed;
  }

  final contact = [
    info.phone.trim(),
    info.email.trim(),
  ].where((value) => value.isNotEmpty).join(' | ');
  return [trimmed, name, if (contact.isNotEmpty) contact].join('\n');
}

bool _containsIgnoringCase(String text, String part) =>
    text.toLowerCase().contains(part.toLowerCase());
