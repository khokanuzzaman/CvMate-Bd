class TrainingInfo {
  const TrainingInfo({
    required this.id,
    this.title = '',
    this.organization = '',
    this.completionYear = '',
    this.details = '',
  });

  final String id;
  final String title;
  final String organization;
  final String completionYear;
  final String details;

  factory TrainingInfo.empty({String? id}) =>
      TrainingInfo(id: id ?? DateTime.now().microsecondsSinceEpoch.toString());

  TrainingInfo copyWith({
    String? id,
    String? title,
    String? organization,
    String? completionYear,
    String? details,
  }) {
    return TrainingInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      completionYear: completionYear ?? this.completionYear,
      details: details ?? this.details,
    );
  }
}
