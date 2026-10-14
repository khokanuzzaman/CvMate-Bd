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

  // CV sections (reorder / hide / rename / custom)
  static const String sectionsTitle = 'Sections';
  static const String sectionsTooltip = 'Sections';
  static const String sectionsIntro =
      'Drag to reorder. Hidden sections stay in your CV data but are left out '
      'of the preview and the PDF.';
  static const String sectionsPersonalNote =
      'Your name and contact details always come first.';
  static const String sectionsDragHandle = 'Reorder';
  static String sectionsShow(String title) => 'Show $title';
  static const String sectionsHiddenTag = 'Hidden';
  static const String sectionsCustomTag = 'Custom';
  static const String sectionsEmptyTag = 'Empty';
  static const String sectionsRename = 'Rename';
  static const String sectionsRenameTitle = 'Rename section';
  static const String sectionsRenameLabel = 'Section title';
  static const String sectionsRenameHint = 'e.g. Work history';
  static const String sectionsResetToDefault = 'Reset to default';
  static const String sectionsSave = 'Save';
  static const String sectionsCancel = 'Cancel';
  static const String sectionsTitleRequired = 'Enter a title.';
  static const String sectionsAddCustom = 'Add custom section';
  static const String sectionsAddCustomTitle = 'New section';
  static const String sectionsCustomTitleLabel = 'Section title';
  static const String sectionsCustomTitleHint = 'e.g. Volunteering, Awards';
  static const String sectionsLayoutLabel = 'Layout';
  static const String sectionsLayoutTitledRows = 'Titled rows';
  static const String sectionsLayoutTitledRowsHint =
      'Each item has a bold title and a description.';
  static const String sectionsLayoutBullets = 'Bullet list';
  static const String sectionsLayoutBulletsHint = 'Each item is one bullet.';
  static const String sectionsCreate = 'Add section';
  static const String sectionsEditContent = 'Edit content';
  static const String sectionsDelete = 'Delete section';
  static const String sectionsDeleteTitle = 'Delete this section?';
  static String sectionsDeleteBody(String title) =>
      'Delete "$title" and everything in it? This cannot be undone.';
  static const String sectionsDeleteConfirm = 'Delete';
  static const String sectionsResetOrder = 'Reset order and titles';
  static const String sectionsResetOrderTitle = 'Reset the layout?';
  static const String sectionsResetOrderBody =
      'Sections go back to the template order, all shown, with their default '
      'titles. Your custom sections and all your content are kept.';
  static const String sectionsResetConfirm = 'Reset';
  static const String sectionsMoreOptions = 'More options';
  static const String sectionsCustomDefaultTitle = 'Additional';
  static const String sectionsNoSections = 'No sections yet.';

  // CV builder — custom section page
  static const String customSectionAddFirstRow = 'Add an item';
  static const String customSectionAddAnotherRow = 'Add another item';
  static String customSectionRowTitle(int n) => 'Item $n';
  static String customSectionBulletTitle(int n) => 'Bullet $n';
  static const String customSectionRowName = 'Title';
  static const String customSectionRowNameHint = 'e.g. Red Crescent';
  static const String customSectionRowDescription = 'Description (opt)';
  static const String customSectionBulletText = 'Bullet text';
  static const String customSectionBulletHint = 'e.g. Best Nurse Award 2024';
  static const String customSectionBulletDetails = 'Details (opt)';
  static const String customSectionMoveUp = 'Move up';
  static const String customSectionMoveDown = 'Move down';
  static const String customSectionEmptyHint =
      'Add at least one item. Empty sections are left out of the PDF.';
  static const String customSectionHiddenNote =
      'This section is hidden, so it is not in the preview or the PDF.';
  static const String customSectionFillOrRemove =
      'Fill in or remove the empty items in this section.';
  static const String customSectionEdit = 'Edit section';

  // CV style (market preset), personal details, photo, declaration
  static const String styleTitle = 'CV style';
  static const String styleTooltip = 'CV style';
  static const String styleIntro =
      "Where are you applying? We'll show the right personal details and "
      'layout for that market. You can change any field later.';
  static const String styleInternational = 'International';
  static const String styleInternationalBody =
      'Online portals, remote and Western employers. No photo, age or '
      'personal details.';
  static const String styleAtsSafe = 'ATS-SAFE';
  static const String styleGulf = 'Gulf (UAE, Saudi, Qatar…)';
  static const String styleGulfBody =
      'Photo, nationality, date of birth, passport and visa status, as Gulf '
      'recruiters expect.';
  static const String styleSouthAsia = 'Bangladesh / South Asia';
  static const String styleSouthAsiaBody =
      'Local companies and government jobs. Photo, personal details, '
      'declaration and signature.';
  static const String styleShortInternational = 'International';
  static const String styleShortGulf = 'Gulf';
  static const String styleShortSouthAsia = 'South Asia';
  static const String stylePaperTitle = 'Paper size';
  static const String stylePaperHint =
      'A4 for BD, Gulf, Europe · Letter for US';
  static const String paperA4 = 'A4';
  static const String paperLetter = 'Letter';
  static const String styleTip =
      'Keep one CV per market. Duplicate this CV and switch style for the '
      'other.';
  static String styleUse(String name) => 'Use $name style';

  static const String personalInfoHeader = 'Personal information';
  static const String personalShowOnCv = 'Show on CV';
  static const String personalNotAdded = 'Not added';
  static const String personalFieldPhoto = 'Photo';
  static const String personalFieldDob = 'Date of birth';
  static const String personalFieldNationality = 'Nationality';
  static const String personalFieldPassport = 'Passport no. · expiry';
  static const String personalPassportLabel = 'Passport';
  static const String personalFieldVisa = 'Visa status';
  static const String personalFieldLicence = 'Driving licence';
  static const String personalFieldMarital = 'Marital status';
  static const String personalFieldReligion = 'Religion';
  static const String personalFieldGender = 'Gender';
  static const String personalDobHint = '12 Mar 1996';
  static const String personalNationalityHint = 'Bangladeshi';
  static const String personalPassportNumberHint = 'Passport no.';
  static const String personalPassportExpiryHint = 'Expiry';
  static const String personalVisaHint = 'e.g. Visit visa · available now';
  static const String personalLicenceHint = 'e.g. UAE light vehicle';
  static const String personalMaritalHint = 'e.g. Single';
  static const String personalReligionHint = 'e.g. Islam';
  static const String personalGenderHint = 'e.g. Male';
  static const String personalMoreFields =
      'More fields (religion, gender, custom row)';
  static const String personalFewerFields = 'Fewer fields';
  static const String personalAddRow = 'Add custom row';
  static const String personalRowLabelHint = 'Label';
  static const String personalRowValueHint = 'Value';
  static const String personalRemoveRow = 'Remove row';
  static const String personalPrivacyNote =
      'Only share what the employer asks for. Never put your passport number '
      'on a CV you post publicly.';
  static const String personalDetailsPreview = 'Personal details';

  static const String photoPassportTitle = 'Passport-style photo';
  static const String photoPassportHint =
      'Plain background, face centred. We crop it to 35×45.';
  static const String photoTake = 'Take photo';
  static const String photoGallery = 'Gallery';
  static const String photoRemove = 'Remove photo';
  static const String photoCropTitle = 'Crop photo';
  static const String photoCropHint =
      'Drag and pinch to fit your face in the frame.';
  static const String photoCropUse = 'Use photo';
  static const String photoFailed =
      'Could not use that photo. Please try another one.';

  static const String declarationTile = 'Declaration & signature';
  static const String declarationTileHint =
      'A sign-off line and your signature, common on Bangladeshi CVs.';
  static const String declarationTitle = 'Declaration & signature';
  static const String declarationAdd = 'Add declaration';
  static const String declarationAddHint =
      'Common on Bangladeshi and government CVs';
  static const String declarationTextLabel = 'Declaration text';
  static const String declarationEnglish = 'English';
  static const String declarationBangla = 'বাংলা';
  static const String declarationPlace = 'Place';
  static const String declarationPlaceHint = 'e.g. Dhaka';
  static const String declarationDate = 'Date';
  static const String declarationDateOnExport = 'On export';
  static const String signatureTitle = 'Signature';
  static const String signatureDraw = 'Draw';
  static const String signatureUpload = 'Upload';
  static const String signatureClear = 'Clear';
  static const String signatureSignAbove = 'Sign above the line';
  static const String signatureNote =
      'This places an image of your signature on the PDF. It is not a '
      'digital certificate.';
  static const String signatureShow = 'Show signature on CV';
  static const String signaturePick = 'Choose an image';
  static const String signatureReplace = 'Choose another image';
  static const String declarationSave = 'Save';

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
  static const String coverLetterNewLetter = 'New letter';
  static const String coverLetterNewLetterTitle = 'Start a new letter?';
  static const String coverLetterNewLetterBody =
      'This letter is not saved yet. Export it first to keep it as a draft.';
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

  // ATS check
  static const String atsTitle = 'ATS check';
  static const String atsCheckedNow = 'Checked just now';
  static const String atsLoading = 'Checking your CV...';
  static const String atsLoadErrorTitle = 'Could not load the ATS check';
  static const String atsNoCvTitle = 'No CV to check yet';
  static const String atsNoCvBody =
      'Create a CV first, then come back to see how ATS-friendly it is.';
  static const String atsCreateCv = 'Create CV';
  static const String atsNoSelectionTitle = 'No CV selected';
  static const String atsNoSelectionBody =
      'Reload the screen and choose a saved CV.';
  static const String atsHeadlineStrong = 'Strong';
  static const String atsHeadlineGood = 'Good';
  static const String atsHeadlineNeedsWork = 'Needs work';
  static String atsHeadline(String band, int fixes) => fixes == 0
      ? band
      : fixes == 1
      ? '$band, with 1 fix'
      : '$band, with $fixes fixes';
  static const String atsBodyStrong =
      'This CV reads well. Review the items below to polish it further.';
  static const String atsBodyGood =
      'Most systems will read this CV. Fix the high-priority items first.';
  static const String atsBodyNeedsWork =
      'Some systems may struggle with this CV. Start with the high-priority '
      'items.';
  static const String atsWhatToFix = 'What to fix';
  static const String atsFix = 'Fix';
  static const String atsSeverityHigh = 'HIGH';
  static const String atsSeverityMed = 'MED';
  static const String atsSeverityLow = 'LOW';
  static const String atsNoIssues = 'No issues found — nice work.';
  static String atsExample(String text) => 'Example: $text';
  static const String atsDisclaimer =
      'A rule-based guide — not a guarantee of ATS approval or shortlisting.';
  static const String atsCheckAgainstJob = 'Check against a job post';
  static const String atsMenuImproveWithAi = 'Improve summary with AI';
  static const String atsMenuOpenAiImprove = 'Open AI Improve';
  static const String atsMenuApplySkills = 'Apply detected skills';
  static const String atsMenuCopySuggestions = 'Copy suggestions';
  static const String atsNeedsJobPost =
      'Paste a job post first — tap "Check against a job post".';
  static const String atsAiSheetTitle = 'Improve with AI';
  static const String atsAiSheetBody =
      'Generate an editable summary or objective. Review it and keep only '
      'what is true.';
  static const String atsAiSuggestionLabel = 'AI suggestion';
  static const String atsAiGenerate = 'Generate';
  static const String atsAiGenerating = 'Generating...';
  static const String atsAiApply = 'Apply to CV';
  static const String atsAiCopy = 'Copy';

  // Interview prep
  static const String interviewTitle = 'Interview prep';
  static const String interviewLoading = 'Loading interview prep...';
  static const String interviewLoadErrorTitle = 'Could not load interview prep';
  static String interviewContext({
    required bool fromCv,
    required String role,
    required String company,
  }) {
    final lead = fromCv ? 'From your CV' : 'From your target role';
    if (role.isEmpty) {
      return lead;
    }
    return company.isEmpty ? '$lead · $role' : '$lead · $role at $company';
  }

  static String interviewFilterAll(int count) => 'All $count';
  static String interviewQuestionLabel(String category, int number) =>
      '$category · Q$number';
  static const String interviewSuggestedAnswer = 'Suggested answer';
  static const String interviewStarSuffix = ' · STAR';
  static const String interviewNoAnswer = 'No suggested answer yet.';
  static const String interviewPractice = 'Practice answer';
  static const String interviewShowInBangla = 'বাংলায় দেখো';
  static const String interviewShowInEnglish = 'Show in English';
  static const String interviewGenerateMore = 'Generate more questions';
  static const String interviewGenerate = 'Generate questions';
  static const String interviewGenerating = 'Generating questions...';
  static String interviewMoreAdded(int count) =>
      count == 1 ? 'Added 1 new question.' : 'Added $count new questions.';
  static const String interviewNoNewQuestions =
      'No new questions this time. Try again or adjust the job details.';
  static const String interviewReplaceEditedTitle = 'Replace your answers?';
  static const String interviewReplaceEditedBody =
      'This replaces your edited answers. Continue?';
  static const String interviewReplaceEditedCancel = 'Keep my answers';
  static const String interviewReplaceEditedContinue = 'Continue';
  static const String interviewRegeneratedBangla =
      'Questions regenerated in Bangla.';
  static const String interviewRegeneratedEnglish =
      'Questions regenerated in English.';
  static const String interviewMoreOptions = 'More options';
  static const String interviewSaveSession = 'Save session';
  static const String interviewCopyAllQuestions = 'Copy all questions';
  static const String interviewCopyAllAnswers = 'Copy all answers';
  static const String interviewStartOver = 'Start over';
  static const String interviewSetupLabel = 'Set up your practice';
  static const String interviewNoCvSelected = 'No CV selected';
  static const String interviewWithoutCv = 'Continue without a CV';
  static const String interviewNoCvTitle = 'No saved CV yet';
  static const String interviewNoCvBody =
      'You can still practice with a target role and job post. A CV makes the '
      'questions more personal.';
  static const String interviewCreateCv = 'Create CV';
  static const String interviewRoleLabel = 'Target job title';
  static const String interviewRoleHint = 'e.g. Frontend Developer';
  static const String interviewCompanyLabel = 'Company';
  static const String interviewCompanyHint = 'e.g. Acme Inc.';
  static const String interviewJobPostLabel = 'Job post or details';
  static const String interviewJobPostHint =
      'Paste responsibilities, required skills or interview expectations.';
  static const String interviewTypeLabel = 'Interview type';
  static const String interviewLanguageLabel = 'Language';
  static const String interviewEnglish = 'English';
  static const String interviewBangla = 'Bangla';
  static const String interviewAnswerStyleLabel = 'Answer style';
  static const String interviewOptional = '(optional)';
  static const String interviewRecent = 'Recent sessions';
  static const String interviewQuickPractice = 'Quick practice';
  static const String interviewQuickPracticeBody =
      'Common questions you can rehearse any time.';
  static const String interviewCopyQuestion = 'Copy question';
  static const String interviewQuestionCopied = 'Question copied.';
  static const String interviewCopyAnswer = 'Copy answer';
  static const String interviewFavorite = 'Save favorite';
  static const String interviewUnfavorite = 'Remove favorite';
  static const String interviewPracticeTitle = 'Practice your answer';
  static const String interviewWhyItMatters = 'Why it matters';
  static String interviewAnswerTip(String tip) => 'Tip: $tip';
  static const String interviewYourAnswer = 'Your answer (editable)';
  static const String interviewTruthful =
      'Review everything before a real interview and never claim skills or '
      'experience you do not have.';

  // Job tracker
  static const String trackerTitle = 'Applications';
  static const String trackerAdd = 'Add application';
  static const String trackerSearch = 'Search applications';
  static const String trackerSearchHint = 'Company or job title';
  static const String trackerStatApplied = 'Applied';
  static const String trackerStatInterview = 'Interview';
  static const String trackerStatOffer = 'Offer';
  static const String trackerStatClosed = 'Closed';
  static const String trackerFilterAll = 'All';
  static const String trackerLoading = 'Loading your applications...';
  static const String trackerLoadErrorTitle = 'Could not load applications';
  static const String trackerLoadErrorBody =
      'Something went wrong. Please try again.';
  static const String trackerEmptyTitle = 'No applications yet';
  static const String trackerEmptyBody =
      'Track your first application to see interviews, follow-ups and linked '
      'CVs in one place.';
  static const String trackerNoMatchTitle = 'No matching applications';
  static const String trackerNoMatchBody =
      'Try another company, job title or status.';
  static const String trackerClearFilters = 'Clear filters';
  static const String trackerUntitledRole = 'Untitled role';
  static const String trackerUnknownCompany = 'Unknown company';
  static String trackerVia(String company, String source) =>
      '$company · via $source';
  static String trackerHintInterview(String when) =>
      'Interview $when · Prep now';
  static const String trackerToday = 'today';
  static const String trackerTomorrow = 'tomorrow';
  static const String trackerHintFollowUpDue =
      'Follow-up due · Send a follow-up';
  static String trackerHintApplied(int days) {
    final when = switch (days) {
      0 => 'Applied today',
      1 => 'Applied 1 day ago',
      _ => 'Applied $days days ago',
    };
    return days >= 7 ? '$when · Send a follow-up' : when;
  }

  // Profile & settings
  static const String profileTitle = 'Profile';
  static const String profileLoading = 'Loading account details...';
  static const String profileGuest = 'Guest';
  static const String profileGuestSubtitle = 'Using CvMate without an account';
  static const String planFree = 'Free';
  static const String planPro = 'Pro';
  static const String goProTitle = 'Go Pro';
  static const String goProBody = 'Unlimited tailoring and exports';
  static const String goProCta = 'See plans';
  static const String profilePreferences = 'Preferences';
  static const String profileAccount = 'Account';
  static const String profileAppLanguage = 'App language';
  static const String profileLanguageNote =
      'Saves your preferred language. The app itself is English-only for now.';
  static const String profileTheme = 'Theme';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeAuto = 'Auto';
  static const String themeComingSoon = 'Dark and Auto are coming soon.';
  static const String profileCloudBackup = 'Cloud backup';
  static const String profileCloudOn = 'On';
  static const String profileCloudOff = 'Off';
  static const String profileCloudOnNote = 'CVs only';
  static const String profileCloudOffNote = 'Sign in to back up your CVs';
  static const String profileComingSoon = 'Coming soon';
  static const String profilePrivacyTerms = 'Privacy & terms';
  static const String profileMoreSettings = 'More settings';
  static const String profileLogOut = 'Log out';
  static const String profileLogIn = 'Log in';
  static const String profileCreateAccount = 'Create account';
  static String profileVersion(String version) => 'CvMate $version';
  static const String logOutTitle = 'Log out';
  static const String logOutBody =
      'Log out now? Your local CVs and drafts will remain on this device.';
  static const String logOutCancel = 'Cancel';
  static const String legalClose = 'Close';
  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String privacyPolicyBody =
      'Privacy Policy placeholder\n\nCareerMate BD stores sensitive career '
      'information such as CV content, job applications, and interview prep '
      'notes. Review every future production privacy document carefully '
      'before release.';
  static const String termsTitle = 'Terms';
  static const String termsBody =
      'Terms placeholder\n\nCareerMate BD provides career writing and '
      'preparation tools. AI suggestions may help improve clarity, but users '
      'remain responsible for reviewing all content before sending it.';
}
