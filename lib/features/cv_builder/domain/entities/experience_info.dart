class ExperienceInfo {
  const ExperienceInfo({
    required this.id,
    this.companyName = '',
    this.jobTitle = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrentRole = false,
    this.highlights = const [],
  });

  final String id;
  final String companyName;
  final String jobTitle;
  final String location;
  final String startDate;
  final String endDate;
  final bool isCurrentRole;
  final List<String> highlights;

  factory ExperienceInfo.empty({String? id}) => ExperienceInfo(
    id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
  );

  ExperienceInfo copyWith({
    String? id,
    String? companyName,
    String? jobTitle,
    String? location,
    String? startDate,
    String? endDate,
    bool? isCurrentRole,
    List<String>? highlights,
  }) {
    return ExperienceInfo(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrentRole: isCurrentRole ?? this.isCurrentRole,
      highlights: highlights ?? this.highlights,
    );
  }
}
