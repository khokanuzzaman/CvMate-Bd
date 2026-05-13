enum CvTemplate { classic, modern, minimal, professional, fresher }

extension CvTemplateX on CvTemplate {
  String get label => switch (this) {
    CvTemplate.classic => 'Classic',
    CvTemplate.modern => 'Modern',
    CvTemplate.minimal => 'Minimal',
    CvTemplate.professional => 'Professional',
    CvTemplate.fresher => 'Fresher',
  };

  String get description => switch (this) {
    CvTemplate.classic => 'Balanced layout with clear section separation.',
    CvTemplate.modern => 'Sharper headline styling for recent applicants.',
    CvTemplate.minimal => 'Compact, text-first layout for ATS readability.',
    CvTemplate.professional => 'Formal structure for corporate applications.',
    CvTemplate.fresher => 'Highlights projects and education over experience.',
  };
}
