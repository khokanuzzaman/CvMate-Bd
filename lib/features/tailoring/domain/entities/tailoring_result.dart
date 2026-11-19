/// A single experience bullet rewritten for the target job post.
///
/// [experienceId] ties the suggestion back to the source experience entry so
/// the rewrite can be applied to the correct bullet without inventing new ones.
class TailoredBullet {
  const TailoredBullet({
    required this.experienceId,
    required this.original,
    required this.suggested,
  });

  final String experienceId;
  final String original;
  final String suggested;

  TailoredBullet copyWith({
    String? experienceId,
    String? original,
    String? suggested,
  }) {
    return TailoredBullet(
      experienceId: experienceId ?? this.experienceId,
      original: original ?? this.original,
      suggested: suggested ?? this.suggested,
    );
  }
}

/// The editable output of tailoring a CV to a job post: a role-aligned summary,
/// emphasized (existing) skills, rewritten experience bullets, and a matched
/// cover letter. Every field is editable in the UI before saving or exporting.
class TailoringResult {
  const TailoringResult({
    required this.tailoredSummary,
    required this.emphasizedSkills,
    required this.rewrittenBullets,
  });

  factory TailoringResult.empty() => const TailoringResult(
    tailoredSummary: '',
    emphasizedSkills: [],
    rewrittenBullets: [],
  );

  final String tailoredSummary;
  final List<String> emphasizedSkills;
  final List<TailoredBullet> rewrittenBullets;

  bool get hasTailoredContent =>
      tailoredSummary.trim().isNotEmpty ||
      emphasizedSkills.isNotEmpty ||
      rewrittenBullets.isNotEmpty;

  TailoringResult copyWith({
    String? tailoredSummary,
    List<String>? emphasizedSkills,
    List<TailoredBullet>? rewrittenBullets,
  }) {
    return TailoringResult(
      tailoredSummary: tailoredSummary ?? this.tailoredSummary,
      emphasizedSkills: emphasizedSkills ?? this.emphasizedSkills,
      rewrittenBullets: rewrittenBullets ?? this.rewrittenBullets,
    );
  }
}
