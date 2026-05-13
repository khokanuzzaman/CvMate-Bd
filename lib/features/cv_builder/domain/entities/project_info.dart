class ProjectInfo {
  const ProjectInfo({
    required this.id,
    this.title = '',
    this.role = '',
    this.description = '',
    this.technologies = const [],
    this.link = '',
  });

  final String id;
  final String title;
  final String role;
  final String description;
  final List<String> technologies;
  final String link;

  factory ProjectInfo.empty({String? id}) =>
      ProjectInfo(id: id ?? DateTime.now().microsecondsSinceEpoch.toString());

  ProjectInfo copyWith({
    String? id,
    String? title,
    String? role,
    String? description,
    List<String>? technologies,
    String? link,
  }) {
    return ProjectInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      role: role ?? this.role,
      description: description ?? this.description,
      technologies: technologies ?? this.technologies,
      link: link ?? this.link,
    );
  }
}
