class LanguageInfo {
  const LanguageInfo({required this.id, this.name = '', this.proficiency = ''});

  final String id;
  final String name;
  final String proficiency;

  factory LanguageInfo.empty({String? id}) =>
      LanguageInfo(id: id ?? DateTime.now().microsecondsSinceEpoch.toString());

  LanguageInfo copyWith({String? id, String? name, String? proficiency}) {
    return LanguageInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
    );
  }
}
