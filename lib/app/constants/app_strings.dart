abstract final class AppStrings {
  static const String appName = 'CareerMate BD';
  static const String playStoreTitle = 'CareerMate BD: AI CV Builder';
  static const String shortTagline = 'AI Career Assistant for Bangladesh';
  static const String longTagline =
      'Create ATS-friendly CVs, cover letters, and track job applications with AI-powered Bangla career guidance.';

  // Brand / splash
  static const String brandName = 'CvMate';
  static const String splashTagline = 'Tailor. Apply. Get hired.';

  // Onboarding
  static const String onboardingHeadline =
      'Tailor your CV to every job — and get past the ATS.';
  static const String onboardingBody =
      'Paste a job post, and CvMate rewrites your CV and cover letter to '
      'match — truthfully, in your language, in about a minute.';
  static const String onboardingSkip = 'Skip';
  static const String onboardingGetStarted = 'Get started';
  static const String onboardingAtsMatchLabel = 'ATS match';
  static const String onboardingAtsMatchValue = '92%';

  // Auth — shared
  static const String authEmailLabel = 'Email';
  static const String authEmailHint = 'you@email.com';
  static const String authPasswordLabel = 'Password';
  static const String authOr = 'or';
  static const String authLogIn = 'Log in';
  static const String authHaveAccount = 'Already have an account?';
  static const String authShowPassword = 'Show password';
  static const String authHidePassword = 'Hide password';
  static const String authGoogleComingSoon = 'Google sign-in is coming soon';

  // Auth — login
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Log in to pick up where you left off.';
  static const String loginPasswordHint = '••••••••';
  static const String loginForgot = 'Forgot?';
  static const String loginSubmitting = 'Logging in...';
  static const String loginGoogle = 'Continue with Google';
  static const String loginNewHere = 'New here?';
  static const String createAccount = 'Create account';

  // Auth — register
  static const String registerHeadline = 'Start landing interviews';
  static const String registerSubtitle =
      'Free to build. Your first export is on us.';
  static const String registerNameLabel = 'Full name';
  static const String registerNameHint = 'Your name';
  static const String registerPasswordHint = 'At least 8 characters';
  static const String registerTermsPrefix = 'I agree to the ';
  static const String registerTerms = 'Terms';
  static const String registerTermsAnd = ' and ';
  static const String registerPrivacy = 'Privacy Policy';
  static const String registerTermsSuffix = '.';
  static const String registerTermsRequired =
      'Please accept the Terms and Privacy Policy to continue.';
  static const String registerSubmitting = 'Creating account...';
  static const String registerGoogle = 'Sign up with Google';
  static const String passwordStrengthLabel = 'Password strength';
  static const String passwordStrengthEmpty = 'not entered';
  static const String passwordStrengthWeak = 'weak';
  static const String passwordStrengthFair = 'fair';
  static const String passwordStrengthStrong = 'strong';

  static const String routeErrorTitle = 'Screen not found';
  static const String routeErrorMessage =
      'This route is not available in the current build.';

  // Home — header
  static const String homeWelcomeEyebrow = 'Welcome back';
  static const String homeTitle = 'Ready to apply?';

  // Home — hero "Tailor to a Job" card
  static const String homeHeroEyebrow = 'Tailor to a job';
  static const String homeHeroCardTitle = 'Match your CV to any job post';
  static const String homeHeroCardBody =
      'Paste a job post — get an ATS score, a tailored CV and a matching '
      'cover letter in about a minute.';
  static const String homeHeroCta = 'Start tailoring';

  // Home — sections
  static const String homeQuickActions = 'Quick actions';
  static const String homeYourCvs = 'Your CVs';
  static const String homeNewCv = 'New';
  static const String homeCvsEmptyTitle = 'No CVs yet';
  static const String homeCvsEmptyBody = 'Create your first CV to see it here.';
  static const String homeCvsError = 'Could not load your CVs.';
  static const String homeRetry = 'Retry';

  // Home — quick action labels
  static const String actionCreateCv = 'Create CV';
  static const String actionAtsCheck = 'ATS Check';
  static const String actionCoverLetter = 'Cover Letter';
  static const String actionImproveCv = 'Improve CV';
  static const String actionInterview = 'Interview';
  static const String actionTrackJob = 'Track Job';

  static const String settings = 'Settings';

  // CV builder — chrome
  static const String builderChipPersonal = 'Personal';
  static const String builderChipEducation = 'Education';
  static const String builderChipExperience = 'Experience';
  static const String builderChipSkills = 'Skills';
  static const String builderChipProjects = 'Projects';
  static const String builderChipTraining = 'Training';
  static const String builderChipSummary = 'Summary';
  static const String builderSectionPersonal = 'Personal';
  static const String builderSectionEducation = 'Education';
  static const String builderSectionExperience = 'Experience';
  static const String builderSectionSkills = 'Skills & languages';
  static const String builderSectionProjects = 'Projects';
  static const String builderSectionTraining = 'Training / certifications';
  static const String builderSectionSummary = 'Summary';
  static const String builderBack = 'Back';
  static const String builderContinue = 'Continue';
  static const String builderPreviewCv = 'Preview CV';
  static const String builderPreparing = 'Preparing your CV draft...';
  static const String builderNoDraftTitle = 'No CV draft ready';
  static const String builderNoDraftBody =
      'Create a new CV or open a saved one from your CV list.';
  static const String builderRemoveEntry = 'Remove';
  static const String builderImproveWithAi = 'Improve with AI';
  static const String builderGenerateWithAi = 'Generate with AI';

  static String builderStepLabel(int step, int total, String section) =>
      'Step $step of $total · $section';

  // CV builder — personal
  static const String builderPhotoTitle = 'Profile photo';
  static const String builderPhotoHint = 'Optional · omit for Western/ATS CVs';
  static const String builderPhotoUpload = 'Upload';
  static const String builderPhotoComingSoon = 'Photo upload is coming soon';
  static const String builderFullName = 'Full name';
  static const String builderFullNameHint = 'e.g. Ayesha Rahman';
  static const String builderHeadline = 'Headline';
  static const String builderHeadlineHint = 'e.g. Frontend Developer';
  static const String builderPhone = 'Phone';
  static const String builderPhoneHint = '+880 1…';
  static const String builderLocation = 'Location';
  static const String builderLocationHint = 'Dhaka, BD';
  static const String builderWebsite = 'Website / LinkedIn';
  static const String builderWebsiteHint = 'https://linkedin.com/in/…';
  static const String builderEmail = 'Email';
  static const String builderEmailHint = 'name@email.com';
  static const String builderPortfolio = 'Portfolio / GitHub';
  static const String builderPortfolioHint = 'https://github.com/username';
  static const String builderCvTitle = 'CV title';
  static const String builderCvTitleHint = 'Frontend Developer CV';

  // CV builder — shared entry fields
  static const String builderDates = 'Dates';
  static const String builderLocationOpt = 'Location (opt)';
  static const String builderBulletsHint = '• Describe what you did…';

  // CV builder — education
  static String builderDegreeTitle(int n) => 'Degree $n';
  static const String builderDegree = 'Degree';
  static const String builderDegreeHint = 'BSc in Computer Science';
  static const String builderInstitution = 'Institution';
  static const String builderInstitutionHint = 'University name';
  static const String builderEducationDatesHint = '2018 — 2022';
  static const String builderGrade = 'Grade (opt)';
  static const String builderGradeHint = 'CGPA 3.7';
  static const String builderFieldOfStudy = 'Field of study (opt)';
  static const String builderAddFirstDegree = 'Add a degree';
  static const String builderAddAnotherDegree = 'Add another degree';

  // CV builder — experience
  static String builderRoleTitle(int n) => 'Role $n';
  static const String builderJobTitle = 'Job title';
  static const String builderJobTitleHint = 'Frontend Developer';
  static const String builderCompany = 'Company';
  static const String builderCompanyHint = 'Acme Ltd.';
  static const String builderExperienceDatesHint = '2022 — Now';
  static const String builderWhatYouDid = 'What you did';
  static const String builderAddFirstRole = 'Add a role';
  static const String builderAddAnotherRole = 'Add another role';

  // CV builder — projects
  static String builderProjectTitle(int n) => 'Project $n';
  static const String builderProjectName = 'Project name';
  static const String builderProjectNameHint = 'Expense Tracker App';
  static const String builderTechRole = 'Tech / role';
  static const String builderTechHint = 'React, Firebase';
  static const String builderRoleOpt = 'Your role (opt)';
  static const String builderLink = 'Link (opt)';
  static const String builderLinkHint = 'https://github.com/…';
  static const String builderWhatItDoes = 'What it does';
  static const String builderAddFirstProject = 'Add a project';
  static const String builderAddAnotherProject = 'Add another project';

  // CV builder — training / certifications
  static String builderTrainingCardTitle(int n) => 'Training $n';
  static const String builderTrainingName = 'Title';
  static const String builderTrainingNameHint = 'Flutter bootcamp';
  static const String builderOrganization = 'Organization';
  static const String builderOrganizationHint = 'Institute or platform';
  static const String builderYear = 'Year';
  static const String builderYearHint = '2024';
  static const String builderDetailsOpt = 'Details (opt)';
  static const String builderAddFirstTraining = 'Add training or certification';
  static const String builderAddAnotherTraining = 'Add another';

  // CV builder — skills & languages
  static const String builderSkillsLabel = 'Skills';
  static const String builderSkillInputHint = 'Type a skill and press enter';
  static const String builderAddSkill = 'Add skill';
  static const String builderSuggested = 'Suggested for this CV';
  static String builderRemoveSkill(String name) => 'Remove $name';
  static String builderAddSkillNamed(String name) => 'Add $name';
  static const String builderLanguagesLabel = 'Languages';
  static const String builderAddLanguage = 'Add language';
  static const String builderEditLanguage = 'Edit language';
  static const String builderLanguageName = 'Language';
  static const String builderLanguageNameHint = 'Bangla';
  static const String builderProficiency = 'Proficiency';
  static const String builderSaveLanguage = 'Save language';
  static const String builderUpdateLanguage = 'Update language';
  static const String builderDeleteLanguage = 'Remove language';

  // CV builder — summary
  static const String builderToggleSummary = 'Summary';
  static const String builderToggleObjective = 'Objective (fresher)';
  static const String builderProfessionalSummary = 'Professional summary';
  static const String builderCareerObjective = 'Career objective';
  static const String builderSummaryHint =
      'Write 2–3 lines about your strengths, tools and experience.';
  static const String builderObjectiveHint =
      'State the role you want and how you plan to contribute.';
  static const String builderSummaryTip =
      'Keep it to 2–3 lines · recruiters skim this first.';
  static const String builderAllDone =
      "All sections done — you're ready to preview & export.";

  // CV preview + template picker
  static const String previewTitle = 'Preview';
  static const String previewTemplate = 'Template';
  static const String previewExport = 'Export PDF';
  static const String previewChangeTemplate = 'Change template';
  static const String previewMoreOptions = 'More options';
  static const String previewPrint = 'Print';
  static const String previewLoading = 'Loading your CV preview...';
  static const String previewNoDraftBody =
      'Open a saved CV or create a new one before previewing.';
  static const String previewOpenCvList = 'Open CV list';
  static const String previewSummary = 'Summary';
  static const String previewObjective = 'Objective';
  static const String previewExperience = 'Experience';
  static const String previewSkills = 'Skills';
  static const String previewEducation = 'Education';
  static const String previewProjects = 'Projects';
  static const String previewTraining = 'Training / certifications';
  static const String previewLanguages = 'Languages';
  static String previewWarningsSummary(int count) =>
      count == 1 ? '1 thing to fix' : '$count things to fix';
  static const String previewWarningsExpand = 'Show details';
  static const String previewWarningsCollapse = 'Hide details';
  static const String templateTitle = 'Choose a template';
  static const String templateAtsBadge = 'ATS';
  static String templateUse(String name) => 'Use $name template';

  // Tailor — shared
  static const String tailorTitle = 'Tailor to a job';
  static String tailorStepPill(int step) => 'Step $step/3';
  static const String tailorBack = 'Back';

  // Tailor 1 — paste
  static const String tailorWhichCv = 'Which CV?';
  static const String tailorChooseCv = 'Choose a CV';
  static String tailorTemplateSubtitle(String template) => '$template template';
  static const String tailorPasteLabel = 'Paste the job post';
  static const String tailorPasteHint =
      "Paste the full job description here — responsibilities, requirements, "
      "skills. We'll pull the keywords automatically.";
  static const String tailorWorksForAnyRole =
      'Works for any role — nurse, accountant, driver, developer.';
  static const String tailorJobTitleLabel = 'Job title';
  static const String tailorJobTitleHint = 'e.g. React Developer';
  static const String tailorCompanyLabel = 'Company';
  static const String tailorCompanyHint = 'e.g. Acme Inc.';
  static const String tailorOptional = '(optional)';
  static const String tailorAnalyze = 'Analyze match';
  static const String tailorAnalyzing = 'Analyzing...';
  static const String tailorLoadingCvs = 'Loading your CVs...';
  static const String tailorNoCvTitle = 'No CV to tailor yet';
  static const String tailorNoCvBody =
      'Create a CV first, then paste a job post here to tailor it and '
      'generate a matched cover letter.';

  // Tailor 2 — match
  static const String tailorMatchTitle = 'Match results';
  static const String tailorMatchStrong = 'ATS match: strong';
  static const String tailorMatchGood = 'ATS match: good start';
  static const String tailorMatchLow = 'ATS match: needs work';
  static const String tailorMatchBodyMissing =
      'Add the missing keywords below and your score jumps toward 90%.';
  static const String tailorMatchBodyCovered =
      'Your CV already covers the keywords in this job post.';
  static const String tailorMatched = 'Matched';
  static const String tailorMissing = 'Missing — add these';
  static const String tailorTruthfulPrefix =
      'We weave these into your summary and skills ';
  static const String tailorTruthfulEmphasis = 'truthfully';
  static const String tailorTruthfulSuffix =
      " — never inventing experience you don't have.";
  static const String tailorTailorMyCv = 'Tailor my CV';
  static const String tailorTailoring = 'Tailoring your CV...';

  // Tailor 3 — result
  static const String tailorResultTitle = 'Your tailored CV';
  static String tailorMatchBadge(int percent) => 'Match $percent%';
  static const String tailorSummaryLabel = 'Professional summary';
  static const String tailorAiTailored = 'AI tailored';
  static const String tailorEdit = 'Edit';
  static const String tailorDone = 'Done';
  static const String tailorSkillsLabel = 'Skills emphasized for this role';
  static const String tailorSkillsEditHint = 'Comma separated, e.g. React, Git';
  static const String tailorBulletsLabel = 'Experience — rewritten bullet';
  static const String tailorBulletsReview =
      'Review each rewrite before saving. Keep only what is true.';
  static const String tailorBulletWas = 'Original bullet';
  static const String tailorBulletNow = 'Rewritten bullet';
  static const String tailorCoverLetter = 'Cover letter';
  static const String tailorSaveExport = 'Save & export';
  static const String tailorSavesAsCopy =
      'Saves as a new tailored copy — your original CV stays untouched.';
  static String tailorSavedSnack(String title) => 'Saved "$title".';
  static const String tailorMoreOptions = 'More options';
  static const String tailorPrint = 'Print';
  static const String tailorStartOver = 'Start over';
  static const String tailorStartOverTitle = 'Start over?';
  static const String tailorStartOverBody =
      'This clears the job post, the match and your tailored CV. Your saved '
      'CVs are not affected.';
  static const String tailorCancel = 'Cancel';

  // Cover letter
  static const String coverLetterTitle = 'Cover letter';
  static const String coverLetterShare = 'Share';
  static const String coverLetterMoreOptions = 'More options';
  static const String coverLetterCopyToClipboard = 'Copy to clipboard';
  static String coverLetterAlignedTo(String target) => 'Aligned to $target';
  static const String coverLetterChangeDetails = 'Change details';
  static const String coverLetterTone = 'Tone';
  static const String coverLetterToneProfessional = 'Professional';
  static const String coverLetterToneFriendly = 'Friendly';
  static const String coverLetterToneConfident = 'Confident';
  static const String coverLetterEdit = 'Edit';
  static const String coverLetterDoneEditing = 'Done';
  static const String coverLetterRegenerate = 'Regenerate';
  static const String coverLetterExport = 'Export';
  static const String coverLetterGenerating = 'Writing your cover letter...';
  static const String coverLetterSubject = 'Subject';
  static const String coverLetterCopy = 'Copy';
  static const String coverLetterSaveDraft = 'Save draft';
  static const String coverLetterLoading =
      'Loading CVs and cover letter drafts...';
  static const String coverLetterNewDraft = 'New draft';
  static const String coverLetterViewLetter = 'View letter';
  static const String coverLetterSetupTitle = 'Cover letter generator';
  static const String coverLetterSetupBody =
      'Generate editable cover letters, job application emails, and LinkedIn '
      'messages from a saved CV or a short summary of your own.';
  static const String coverLetterEditingDraft = 'Editing saved draft';
  static const String coverLetterNoCvs =
      'No saved CV found yet. You can still generate content manually, or '
      'create a CV first for stronger role-based results.';
  static String coverLetterSelectedCv(String title, String role) =>
      'Selected CV: $title • $role';
  static String coverLetterTailoredCv(String title) =>
      'Using the tailored version of $title';
  static const String coverLetterCreateCv = 'Create CV';
  static const String coverLetterCreateAnotherCv = 'Create another CV';
  static const String coverLetterOpenSelectedCv = 'Open selected CV';
  static const String coverLetterRecentDrafts = 'Recent drafts';
  static String coverLetterDraftMeta(String type, String updated) =>
      '$type • Updated $updated';
  static String coverLetterDraftCv(String title) => 'Using CV: $title';
  static const String coverLetterOpenDraft = 'Open draft';
  static const String coverLetterDeleteDraft = 'Delete draft';
  static const String coverLetterDeleteTitle = 'Delete draft';
  static String coverLetterDeleteBody(String title) =>
      'Delete "$title" from local storage? This cannot be undone.';
  static const String coverLetterCancel = 'Cancel';
  static const String coverLetterDelete = 'Delete';
  static const String coverLetterOpenBadge = 'Open';
  static const String coverLetterCandidate = 'Candidate source';
  static const String coverLetterSelectCv = 'Select CV';
  static const String coverLetterManualCv =
      'No CV selected, use manual summary';
  static const String coverLetterOutputType = 'Output type';
  static const String coverLetterLanguage = 'Language';
  static const String coverLetterEnglish = 'English';
  static const String coverLetterBangla = 'Bangla';
  static const String coverLetterJobDetails = 'Job details';
  static const String coverLetterCompanyLabel = 'Target company name';
  static const String coverLetterCompanyHint = 'BRAC Bank, DataPath, Shohoz';
  static const String coverLetterJobTitleLabel = 'Job title';
  static const String coverLetterJobTitleHint =
      'Flutter Developer, Marketing Executive';
  static const String coverLetterJobPostLabel = 'Job post or job details';
  static const String coverLetterJobPostHint =
      'Paste responsibilities, skills, company expectations, or a short job '
      'description.';
  static const String coverLetterManagerLabel = 'Hiring manager name';
  static const String coverLetterManagerHint = 'Optional';
  static const String coverLetterSummaryLabel = 'Candidate summary';
  static const String coverLetterSummaryHint =
      'Optional if a CV is selected. Add fresher strengths, projects, or a '
      'quick profile summary.';
  static const String coverLetterSummaryNeeded =
      'Required when you are generating without a selected CV.';
  static const String coverLetterSummaryReuse =
      'Leave blank to reuse the selected CV summary or objective.';
  static const String coverLetterGenerate = 'Generate';
  static const String coverLetterSubjectLabel = 'Subject line';
  static const String coverLetterSubjectHint = 'Application for the role';

  // Paywall
  static const String paywallClose = 'Close';
  static const String paywallTitle = 'Unlock unlimited exports';
  static const String paywallBodyPrefix = "You've used your ";
  static const String paywallBodyEmphasis = 'free export';
  static const String paywallBodySuffix =
      '. Go Pro for unlimited tailored CVs — or pay once for just this one.';
  static const String paywallBenefitTailoring =
      'Unlimited job tailoring & AI rewrites';
  static const String paywallBenefitTemplates =
      'All templates, clean exports — no watermark';
  static const String paywallBenefitCloud =
      'Cover letters, cloud sync across devices';
  static const String paywallMonthly = 'Monthly';
  static const String paywallYearly = 'Yearly';
  static const String paywallPerMonth = '/mo';
  static const String paywallPerYear = '/yr';
  static String paywallSave(int percent) => 'SAVE $percent%';
  static const String paywallOneTimeTitle = 'Just this CV — one-time';
  static const String paywallOneTimeSubtitle = 'No subscription';
  static const String paywallNotAvailable =
      "Pro isn't available yet — nothing is charged today.";
  static const String paywallCta = 'Coming soon';
  static const String paywallFooter = 'No auto-renew tricks · cancel anytime';
  static const String paywallRestore = 'Restore purchase';
}
