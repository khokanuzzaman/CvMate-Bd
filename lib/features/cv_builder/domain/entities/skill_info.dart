class SkillInfo {
  const SkillInfo({required this.id, this.name = '', this.level = ''});

  final String id;
  final String name;
  final String level;

  factory SkillInfo.empty({String? id}) =>
      SkillInfo(id: id ?? DateTime.now().microsecondsSinceEpoch.toString());

  SkillInfo copyWith({String? id, String? name, String? level}) {
    return SkillInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }
}
