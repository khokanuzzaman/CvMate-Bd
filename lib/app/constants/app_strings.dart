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

  // CV picker (shared)
  static const String cvPickerChoose = 'Choose a CV';
  static String cvPickerTemplate(String template) => '$template template';

  // Tailor 1 — paste
  static const String tailorWhichCv = 'Which CV?';
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

  // ATS Checker
  static const String atsTitle = 'ATS Checker';
  static const String atsLoading = 'Loading your saved CVs...';
  static const String atsLoadErrorTitle = 'Could not load ATS Checker';
  static const String atsNoCvTitle = 'No CV available yet';
  static const String atsNoCvBody =
      'Create your first CV before checking ATS-friendly quality and '
      'job-post match.';
  static const String atsCreateCv = 'Create CV';
  static const String atsNoSelectionTitle = 'No CV selected';
  static const String atsNoSelectionBody =
      'Please reload the screen and select a saved CV.';
  static const String atsScoreStrong = 'Looking ATS-friendly';
  static const String atsScoreFair = 'A few fixes will help';
  static const String atsScoreLow = 'Needs work';
  static String atsScoreOutOf(int score) => '$score / 100';
  static const String atsScoreNote =
      'A rule-based improvement score, not a guarantee of ATS approval or '
      'shortlisting.';
  static String atsWords(int count) => '$count words';
  static const String atsOpenBuilder = 'CV Builder';
  static const String atsOpenAiImprove = 'AI Improve';
  static const String atsMatchTitle = 'Job post match';
  static const String atsMatchBody =
      'Paste a job post to compare its keywords with your CV and get honest '
      'suggestions.';
  static const String atsJobPostLabel = 'Job post';
  static const String atsJobPostHint =
      'Paste responsibilities, required skills, tools and keywords.';
  static const String atsCheckMatch = 'Check match';
  static const String atsChecking = 'Checking match...';
  static const String atsRecheck = 'Re-check match';
  static const String atsCopySuggestions = 'Copy suggestions';
  static const String atsPasteFirst =
      'Paste a full job post, then tap Check match.';
  static const String atsReadyToCheck =
      'Ready. Tap Check match to extract keywords and see how well your CV '
      'fits.';
  static const String atsMatchScore = 'Job match';
  static const String atsMatchStrong =
      'Strong base. Fine-tune the wording for a tighter match.';
  static const String atsMatchModerate =
      'Moderate match. Update your most relevant sections before applying.';
  static const String atsMatchLow =
      'Low match. Rework your role-focused wording before sending this CV.';
  static const String atsHonestNote =
      'Only add skills, tools, projects or achievements that are true.';
  static const String atsSectionsToImprove = 'Sections to improve';
  static const String atsNoSections = 'No priority sections suggested.';
  static const String atsExtracted = 'Keywords in the post';
  static const String atsNoKeywords = 'No keywords found.';
  static const String atsMatched = 'Matched';
  static const String atsNoMatched = 'No matched keywords yet.';
  static const String atsMissing = 'Missing';
  static const String atsNoMissing = 'No missing keywords detected.';
  static const String atsDetected = 'Skills you can add honestly';
  static const String atsNoDetected =
      'No additional already-supported skills detected.';
  static const String atsApplySkills = 'Apply detected skills to CV';
  static const String atsAiTitle = 'Optional AI improvement';
  static const String atsAiBody =
      'Generate an editable ATS-friendly summary or objective. Review it '
      'before applying.';
  static const String atsAiImprove = 'Improve with AI';
  static const String atsAiGenerating = 'Generating...';
  static const String atsAiSuggestionLabel = 'AI suggestion';
  static const String atsAiApply = 'Apply to CV';
  static const String atsAiCopy = 'Copy';
  static const String atsCategoriesTitle = 'Results by category';
  static const String atsNotChecked = 'Not checked';
  static String atsCategoryScore(int score) => '$score/100';
  static const String atsNoIssues =
      'No major ATS-friendly issues found in this category right now.';
  static const String atsJobMatchPlaceholder =
      'Paste a job post above to see job-match issues and keyword '
      'suggestions.';
  static const String severityHigh = 'High';
  static const String severityMedium = 'Medium';
  static const String severityLow = 'Low';

  // Shared
  static const String commonEnglish = 'English';
  static const String commonBangla = 'Bangla';
  static const String commonStartOver = 'Start over';

  // Interview Prep
  static const String interviewTitle = 'Interview Prep';
  static const String interviewLoading = 'Loading interview prep...';
  static const String interviewLoadErrorTitle = 'Could not load Interview Prep';
  static const String interviewNoCvTitle = 'No saved CV yet';
  static const String interviewNoCvBody =
      'You can still practise with a target role and job post, but a CV makes '
      'the questions more personal.';
  static const String interviewCreateCv = 'Create CV';
  static const String interviewSetupTitle = 'Interview setup';
  static const String interviewSetupBody =
      'Pick a saved CV for personal questions, or continue with just a role '
      'and job details.';
  static const String interviewNoCv = 'Continue without CV';
  static const String interviewJobTitleLabel = 'Target job title';
  static const String interviewJobTitleHint = 'e.g. Flutter Developer';
  static const String interviewCompanyLabel = 'Company';
  static const String interviewCompanyHint = 'e.g. CareerMate BD';
  static const String interviewJobPostLabel = 'Job post / details';
  static const String interviewJobPostHint =
      'Paste responsibilities, required skills or role context.';
  static const String interviewOptional = '(optional)';
  static const String interviewTypeLabel = 'Interview type';
  static const String interviewLanguageLabel = 'Language';
  static const String interviewStyleLabel = 'Answer style';
  static const String interviewGenerate = 'Generate interview questions';
  static const String interviewGenerating = 'Generating...';
  static const String interviewOpenBuilder = 'CV Builder';
  static const String interviewOpenCvList = 'CV list';
  static const String interviewOpenAiImprove = 'AI Improve';
  static const String interviewSessionsTitle = 'Recent sessions';
  static String interviewSessionMeta(String subtitle, String updated) =>
      '$subtitle • Updated $updated';
  static const String interviewQuickTitle = 'Common quick practice';
  static const String interviewQuickBody =
      'Built-in questions you can use any time, even before generating a '
      'personal set.';
  static const String interviewCopyQuestion = 'Copy question';
  static const String interviewQuestionCopied = 'Question copied.';
  static const String interviewResultsTitle = 'Generated interview set';
  static const String interviewResultsBody =
      'Answers are editable. Review everything before using it in a real '
      'interview, and never claim skills or experience you do not have.';
  static const String interviewCopyAllQuestions = 'Copy questions';
  static const String interviewCopyAllAnswers = 'Copy answers';
  static const String interviewSaveSession = 'Save session';
  static const String interviewSaving = 'Saving...';
  static const String interviewGeneratingMessage =
      'Generating interview questions...';
  static const String interviewEmptyTitle = 'No interview set yet';
  static const String interviewEmptyBody =
      'Pick a CV or enter a target role, then generate a set to start '
      'practising.';
  static String interviewAnswerTip(String tip) => 'Answer tip: $tip';
  static const String interviewAnswerLabel = 'Editable sample answer';
  static const String interviewCopyAnswer = 'Copy answer';
  static const String interviewFavorite = 'Save favorite';
  static const String interviewUnfavorite = 'Unfavorite';
  static const String interviewShowAnswer = 'Show answer';
  static const String interviewHideAnswer = 'Hide answer';

  // Job Tracker — list
  static const String trackerTitle = 'Job Tracker';
  static const String trackerLoading = 'Loading your job applications...';
  static const String trackerLoadErrorTitle = 'Could not load applications';
  static const String trackerLoadErrorBody =
      'Something went wrong. Please try again.';
  static const String trackerAddJob = 'Add job';
  static const String trackerSummaryTotal = 'Total';
  static const String trackerSummaryTotalNote = 'Tracked applications';
  static const String trackerSummaryFollowUp = 'Follow-up';
  static const String trackerSummaryFollowUpNote = 'Due or overdue';
  static const String trackerSummaryInterview = 'Interview';
  static const String trackerSummaryInterviewNote = 'Scheduled now';
  static const String trackerSummaryOffers = 'Offers';
  static const String trackerSummaryOffersNote = 'Positive outcomes';
  static const String trackerSearchLabel = 'Search';
  static const String trackerSearchHint = 'Company or job title';
  static const String trackerFilterAll = 'All';
  static const String trackerClearFilters = 'Clear filters';
  static const String trackerEmptyTitle = 'No job applications yet';
  static const String trackerEmptyBody =
      'Track your first application to keep an eye on follow-ups, interviews '
      'and the CV you used.';
  static const String trackerAddApplication = 'Add application';
  static const String trackerNoMatchTitle = 'No matching applications';
  static const String trackerNoMatchBody =
      'Try another company name, job title or status.';
  static const String trackerUntitledRole = 'Untitled role';
  static const String trackerUnknownCompany = 'Unknown company';
  static String trackerApplied(String date) => 'Applied $date';
  static String trackerInterviewOn(String date) => 'Interview $date';
  static const String trackerLinkedCv = 'Linked CV';
  static const String trackerLinkedCoverLetter = 'Linked cover letter';
  static const String trackerFollowUpDue = 'Follow-up due';

  // Job Tracker — form
  static const String jobFormAddTitle = 'Add application';
  static const String jobFormEditTitle = 'Edit application';
  static const String jobFormLoading = 'Loading application form...';
  static const String jobFormLoadErrorTitle = 'Could not load application';
  static const String jobFormBasics = 'Application basics';
  static const String jobFormCompany = 'Company name';
  static const String jobFormCompanyHint = 'BRAC Bank, Unilever Bangladesh';
  static const String jobFormJobTitle = 'Job title';
  static const String jobFormJobTitleHint =
      'Management Trainee, Flutter Developer';
  static const String jobFormSource = 'Job source';
  static const String jobFormLinked = 'Linked assets';
  static const String jobFormLinkedBody =
      'Connect the CV and cover letter you used for this application.';
  static const String jobFormLinkedCv = 'Linked CV';
  static const String jobFormNoLinkedCv = 'No linked CV';
  static const String jobFormLinkedCoverLetter = 'Linked cover letter';
  static const String jobFormNoLinkedCoverLetter = 'No linked cover letter';
  static const String jobFormTimeline = 'Timeline and status';
  static const String jobFormStatus = 'Status';
  static const String jobFormAppliedDate = 'Applied date';
  static const String jobFormDeadlineDate = 'Deadline date';
  static const String jobFormInterviewDate = 'Interview date';
  static const String jobFormFollowUpDate = 'Follow-up reminder date';
  static const String jobFormOptional = 'Optional';
  static const String jobFormClearDate = 'Clear date';
  static const String jobFormReference = 'Reference details';
  static const String jobFormLink = 'Job post link';
  static const String jobFormSalary = 'Salary range';
  static const String jobFormContactPerson = 'Contact person';
  static const String jobFormContactEmail = 'Contact email';
  static const String jobFormNotes = 'Notes';
  static const String jobFormNotesHint =
      'Interview rounds, recruiter messages, next follow-up, salary '
      'expectations.';
  static const String jobFormSave = 'Save application';
  static const String jobFormSaving = 'Saving...';

  // Job Tracker — details
  static const String jobDetailsTitle = 'Application details';
  static const String jobDetailsEdit = 'Edit application';
  static const String jobDetailsNotFoundTitle = 'Application not found';
  static const String jobDetailsNoIdBody =
      'A valid application ID was not provided.';
  static const String jobDetailsMissingBody =
      'This saved application could not be found.';
  static const String jobDetailsLoading = 'Loading application details...';
  static const String jobDetailsLoadErrorTitle = 'Could not load application';
  static String jobDetailsCreated(String date) => 'Created $date';
  static const String jobDetailsUpdateStatus = 'Update status';
  static const String jobDetailsNotAdded = 'Not added';
  static const String jobDetailsApplied = 'Applied date';
  static const String jobDetailsDeadline = 'Deadline';
  static const String jobDetailsInterview = 'Interview date';
  static const String jobDetailsFollowUp = 'Follow-up reminder';
  static const String jobDetailsLink = 'Job post link';
  static const String jobDetailsSalary = 'Salary range';
  static const String jobDetailsContact = 'Contact person';
  static const String jobDetailsEmail = 'Contact email';
  static const String jobDetailsLinkedCv = 'Linked CV';
  static const String jobDetailsLinkedCvMissing = 'Saved CV not found';
  static const String jobDetailsNoLinkedCv = 'No linked CV';
  static const String jobDetailsLinkedCoverLetter = 'Linked cover letter';
  static const String jobDetailsLinkedCoverLetterMissing =
      'Saved cover letter not found';
  static const String jobDetailsNoLinkedCoverLetter = 'No linked cover letter';
  static const String jobDetailsNotes = 'Notes';
  static const String jobDetailsNoNotesTitle = 'No notes yet';
  static const String jobDetailsNoNotesBody =
      'Add recruiter messages, interview instructions or follow-up reminders '
      'in the application form.';
  static const String jobDetailsTemplates = 'Quick copy templates';
  static const String jobDetailsTemplatesBody =
      'Local templates for a follow-up, an interview confirmation and a polite '
      'status check.';
  static const String jobDetailsArchive = 'Archive';
  static const String jobDetailsRestore = 'Mark as Applied';
  static const String jobDetailsDelete = 'Delete';
  static const String jobDetailsDeleteTitle = 'Delete application';
  static String jobDetailsDeleteBody(String title) =>
      'Delete "$title" from local storage? This cannot be undone.';
  static const String jobDetailsCancel = 'Cancel';
  static String jobDetailsStatusUpdated(String status) =>
      'Status updated to $status.';
  static String jobDetailsTemplateCopied(String label) => '$label copied.';
}
