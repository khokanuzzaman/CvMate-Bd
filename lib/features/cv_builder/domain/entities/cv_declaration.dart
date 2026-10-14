enum DeclarationLanguage {
  english,
  bangla;

  static DeclarationLanguage? tryParse(Object? raw) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

/// The "I hereby declare…" block common on Bangladeshi and government CVs.
/// Whether it is printed is `PersonalField.declaration` in the CV's shown fields.
class CvDeclaration {
  const CvDeclaration({
    this.text = '',
    this.language = DeclarationLanguage.english,
    this.place = '',
    this.date = '',
  });

  /// Empty means "the default wording for [language]".
  final String text;
  final DeclarationLanguage language;
  final String place;

  /// Empty means "the date of export".
  final String date;

  static const String defaultEnglish =
      'I hereby declare that the information given above is true and correct '
      'to the best of my knowledge.';
  static const String defaultBangla =
      'আমি এতদ্বারা ঘোষণা করছি যে উপরে প্রদত্ত তথ্য আমার জানামতে সত্য ও সঠিক।';

  static String defaultFor(DeclarationLanguage language) =>
      language == DeclarationLanguage.bangla ? defaultBangla : defaultEnglish;

  String get effectiveText => text.trim().isEmpty ? defaultFor(language) : text;

  /// The text the user typed. Typing the default wording back keeps it as "the
  /// default", so it follows the language chips.
  CvDeclaration withEditedText(String value) =>
      copyWith(text: value.trim() == defaultFor(language) ? '' : value);

  /// Switching language switches to that language's default wording.
  CvDeclaration withLanguage(DeclarationLanguage value) =>
      copyWith(language: value, text: '');

  CvDeclaration copyWith({
    String? text,
    DeclarationLanguage? language,
    String? place,
    String? date,
  }) {
    return CvDeclaration(
      text: text ?? this.text,
      language: language ?? this.language,
      place: place ?? this.place,
      date: date ?? this.date,
    );
  }
}
