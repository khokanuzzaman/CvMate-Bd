class EducationInfo {
  const EducationInfo({
    required this.id,
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.startYear = '',
    this.endYear = '',
    this.result = '',
    this.location = '',
    this.isOngoing = false,
  });

  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startYear;
  final String endYear;
  final String result;
  final String location;
  final bool isOngoing;

  factory EducationInfo.empty({String? id}) =>
      EducationInfo(id: id ?? DateTime.now().microsecondsSinceEpoch.toString());

  EducationInfo copyWith({
    String? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    String? startYear,
    String? endYear,
    String? result,
    String? location,
    bool? isOngoing,
  }) {
    return EducationInfo(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      result: result ?? this.result,
      location: location ?? this.location,
      isOngoing: isOngoing ?? this.isOngoing,
    );
  }
}
