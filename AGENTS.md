# AGENTS.md

## Project Name

CareerMate BD

## App Identity

App Name: CareerMate BD  
Package Name: `com.khokan.careermatebd`  
Short Tagline: AI Career Assistant for Bangladesh  
Play Store Title: CareerMate BD: AI CV Builder  

Long Tagline:

Create ATS-friendly CVs, cover letters, and track job applications with AI-powered Bangla career guidance.

---

## Product Goal

Build a production-ready Flutter app for Bangladeshi job seekers.

CareerMate BD helps users:

- Create professional ATS-friendly CVs
- Generate cover letters and job application emails
- Improve CV content using AI
- Customize CVs based on job posts
- Track job applications
- Prepare for interviews in Bangla and English

This app must not feel like a generic CV maker. It should feel like a Bangladesh-focused AI Career Assistant.

---

## Target Users

Primary users:

- Fresh graduates
- Students
- Junior job seekers
- Internship seekers
- Career switchers
- Bangladeshi job seekers who need Bangla guidance
- Users applying through Bdjobs, LinkedIn, email, Facebook groups, and company career pages

Important user problems:

- They do not know how to write a professional CV
- They struggle with English CV writing
- They use the same CV for every job
- They do not know how to write a cover letter
- They forget where they applied
- They need interview preparation based on their CV

---

## Core Product Positioning

CareerMate BD should be positioned as:

> An AI-powered career assistant for Bangladeshi job seekers to create professional CVs, generate cover letters, prepare for interviews, and track job applications.

The app must feel:

- Practical
- Professional
- Trustworthy
- Clean
- Easy to use
- Useful for real job seekers

---

## Tech Stack

Use the following stack unless the task clearly requires otherwise:

- Flutter latest stable
- Dart latest stable
- Riverpod for state management
- GoRouter for navigation
- Firebase Auth for authentication
- Cloud Firestore for cloud data
- Firebase Storage for exported/generated files if needed
- Hive or Isar for offline/local drafts
- OpenAI API integration for AI features
- `pdf` package for PDF generation
- `printing` package for PDF preview/share
- `intl` for date/time formatting
- `freezed` and `json_serializable` for immutable models if needed
- `dio` for API/network calls
- `flutter_dotenv` for local environment variables
- `easy_localization` or Flutter localization if localization is implemented

Do not introduce unnecessary packages without a clear reason.

---

## Core Development Rules

1. Always write clean, scalable, production-ready Flutter code.
2. Prefer feature-first folder structure.
3. Use reusable widgets.
4. Avoid large widgets.
5. Avoid business logic inside UI widgets.
6. Use Riverpod providers for state and dependency management.
7. Use repository pattern for data access.
8. Use service classes for AI, PDF, auth, storage, and business logic.
9. Keep UI responsive and mobile-first.
10. Support Bangla and English content where relevant.
11. Do not hardcode secrets, API keys, tokens, or private URLs.
12. Never commit `.env` values.
13. Keep generated code organized.
14. Before changing existing code, inspect the current structure first.
15. Make minimal and focused changes.
16. Do not rewrite unrelated files.
17. Do not remove existing functionality unless explicitly requested.
18. Do not add fake data unless clearly marked as mock/demo.
19. Always handle loading, empty, error, and success states.
20. Prefer readable code over clever code.
21. Keep code modular and testable.
22. Do not duplicate existing utilities, widgets, or services.
23. Use null safety properly.
24. Keep files small and focused.
25. Follow Flutter and Dart best practices.

---

## Architecture

Use layered architecture.

```txt
Presentation Layer
- Screens
- Widgets
- Controllers / Notifiers

Application Layer
- Use cases
- Feature services
- Workflow logic

Domain Layer
- Entities
- Value objects
- Repository contracts
- Business rules

Data Layer
- DTOs
- Data sources
- Repository implementations
- API/Firebase/local storage implementation
```

---

## Recommended Folder Structure

Use this structure for the app:

```txt
lib/
  main.dart

  app/
    app.dart
    router/
      app_router.dart
      route_names.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_text_styles.dart
      app_spacing.dart
    localization/
    constants/
      app_constants.dart
      app_assets.dart
      app_strings.dart

  core/
    config/
      env_config.dart
      firebase_config.dart
    errors/
      app_exception.dart
      failure.dart
    extensions/
    network/
      dio_client.dart
      network_info.dart
    utils/
      result.dart
      validators.dart
      date_formatter.dart
    widgets/
      custom_button.dart
      custom_text_field.dart
      custom_app_bar.dart
      custom_loading_view.dart
      custom_error_view.dart
      custom_empty_state.dart
      custom_card.dart

  shared/
    models/
    services/
      ai/
        ai_career_service.dart
        ai_prompt_builder.dart
        ai_response_parser.dart
      pdf/
        cv_pdf_service.dart
      storage/
      notification/

  features/
    auth/
      data/
      domain/
      presentation/

    profile/
      data/
      domain/
      presentation/

    cv_builder/
      data/
        datasources/
        dtos/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/

    cover_letter/
      data/
      domain/
      presentation/

    job_tracker/
      data/
      domain/
      presentation/

    interview_prep/
      data/
      domain/
      presentation/

    ats_checker/
      data/
      domain/
      presentation/

    subscription/
      data/
      domain/
      presentation/
```

---

## Feature Folder Pattern

Each major feature should follow this structure:

```txt
features/feature_name/
  data/
    datasources/
    dtos/
    repositories/

  domain/
    entities/
    repositories/
    usecases/

  presentation/
    controllers/
    screens/
    widgets/
```

Example:

```txt
features/cv_builder/
  data/
    datasources/
      cv_remote_data_source.dart
      cv_local_data_source.dart
    dtos/
      cv_profile_dto.dart
    repositories/
      cv_repository_impl.dart

  domain/
    entities/
      cv_profile.dart
      education_info.dart
      experience_info.dart
      skill_info.dart
      project_info.dart
    repositories/
      cv_repository.dart
    usecases/
      create_cv_usecase.dart
      update_cv_usecase.dart
      get_user_cvs_usecase.dart
      delete_cv_usecase.dart

  presentation/
    controllers/
      cv_builder_controller.dart
      cv_list_controller.dart
    screens/
      cv_list_screen.dart
      cv_builder_screen.dart
      cv_preview_screen.dart
    widgets/
      cv_stepper.dart
      personal_info_step.dart
      education_step.dart
      experience_step.dart
      skills_step.dart
      projects_step.dart
      cv_template_card.dart
```

---

## Naming Convention

Use clear, consistent naming.

### Widgets

Use `Custom` prefix for global reusable widgets:

```txt
CustomTextField
CustomButton
CustomAppBar
CustomEmptyState
CustomLoadingView
CustomErrorView
CustomCard
CustomDropdownField
CustomDatePickerField
```

### Controllers

```txt
CvBuilderController
CvListController
CoverLetterController
JobTrackerController
InterviewPrepController
AtsCheckerController
```

### Providers

```txt
cvBuilderControllerProvider
cvListControllerProvider
cvRepositoryProvider
aiCareerServiceProvider
coverLetterControllerProvider
jobTrackerControllerProvider
```

### Models / Entities

```txt
CvProfile
PersonalInfo
EducationInfo
ExperienceInfo
SkillInfo
ProjectInfo
TrainingInfo
LanguageInfo
JobApplication
CoverLetterRequest
InterviewQuestion
AtsCheckResult
```

### File Names

Use `snake_case.dart`.

Examples:

```txt
cv_builder_screen.dart
cv_profile.dart
cv_repository.dart
cv_repository_impl.dart
ai_career_service.dart
job_application.dart
cover_letter_controller.dart
```

---

## Main App Features

## 1. CV Builder

The CV Builder is the core feature.

It must support:

- Personal information
- Career objective
- Professional summary
- Education
- Experience
- Skills
- Projects
- Training/certification
- Languages
- References, optional
- Template selection
- CV preview
- PDF export
- Multiple CV save/edit/delete

Important rules:

- Fresher-friendly flow is required.
- Users should be able to create a CV even if they have no experience.
- User should be able to save multiple CVs.
- User should preview CV before export.
- PDF design must be clean, professional, and ATS-friendly.
- Avoid overly graphical CV templates in MVP.
- Use simple, readable, professional layouts.

---

## 2. AI CV Improvement

The app must support AI-based CV improvement.

AI should help users:

- Improve professional summary
- Improve career objective
- Improve experience bullet points
- Improve project descriptions
- Suggest relevant skills
- Rewrite weak text into professional CV language
- Generate fresher-friendly content
- Generate English and Bangla guidance

Example:

User input:

```txt
I worked on Flutter appointment app.
```

Improved output:

```txt
Developed and maintained a Flutter-based appointment management application with API integration, responsive UI, and optimized user experience.
```

Important:

- AI output must be editable.
- User must review before saving.
- Do not auto-replace important user data without confirmation.
- Do not overpromise results.

---

## 3. Job Post Based CV Matching

User can paste a job post.

The app should provide:

- Match score
- Missing skills
- Suggested CV summary
- Suggested skills reorder
- Suggested project highlights
- Suggested experience bullet improvements
- Cover letter/email body
- Interview question suggestions

Safe wording:

Use:

```txt
AI suggestion
May improve CV quality
Review before sending
ATS-friendly suggestions
```

Avoid:

```txt
Guaranteed job
100% ATS pass
Instant hiring
Guaranteed shortlist
```

---

## 4. Cover Letter Generator

The app must support:

- Formal cover letter
- Short cover letter
- Job application email body
- LinkedIn message
- Fresher version
- Experienced version
- Internship version
- Role-specific version

Output must be editable by the user.

Cover letter inputs:

- User name
- Target company
- Job title
- Job post/details
- User experience summary
- Tone: formal, simple, confident
- Language: English or Bangla

---

## 5. Job Application Tracker

The app must help users track their job applications.

It must support:

- Company name
- Job title
- Job source
- Applied date
- Application status
- Notes
- Interview date
- Reminder date
- Salary range
- Related CV
- Related cover letter
- Contact person, optional
- Job post link, optional

Statuses:

```txt
Draft
Applied
Shortlisted
Interview
Offered
Rejected
Archived
```

Tracker dashboard should show:

- Total applied
- Interview scheduled
- Shortlisted
- Offered
- Rejected
- Pending follow-up

This feature is important for retention because users will return to the app regularly.

---

## 6. Interview Preparation

The app must generate interview preparation content.

It should generate:

- Common HR questions
- Role-based questions
- CV-based questions
- Fresher interview questions
- Technical interview questions, if role requires
- Bangla explanation
- English answer sample
- Short professional answer format

Example categories:

- Tell me about yourself
- Why should we hire you?
- What are your strengths?
- What are your weaknesses?
- Explain your project
- Why this company?
- Expected salary answer
- Career gap explanation

Output should be simple, practical, and editable.

---

## 7. ATS Checker

MVP can be rule-based first.

Check:

- Missing contact info
- Missing professional summary
- Weak career objective
- Too long CV
- Missing skills
- Missing measurable achievements
- Poor section structure
- Job post keyword match
- Missing education
- Missing project details
- Weak action verbs
- Formatting issues

Important:

- Do not build fake ATS claims.
- Do not claim real ATS engine compatibility unless implemented.
- Use wording like "ATS-friendly suggestions", not "guaranteed ATS pass".

---

## Recommended MVP Scope

Do not overbuild the first version.

MVP must include:

- Splash screen
- Onboarding screen
- Home screen
- Basic profile
- Create CV
- Edit CV
- CV list
- CV preview
- Export CV as PDF
- AI summary generator
- AI career objective generator
- AI experience bullet improver
- Cover letter generator
- Job application tracker
- Basic ATS-friendly checklist
- Light/dark theme support

Do not implement these in MVP unless explicitly requested:

- Payment gateway
- Full subscription system
- Complex analytics
- Social login
- Web admin panel
- Resume parsing from uploaded PDF
- Bdjobs/LinkedIn scraping
- Complex notification automation
- Full AI chat assistant
- Team account system

---

## Development Phases

## Phase 1 — Project Foundation

Build:

- Flutter project setup
- App theme
- App colors
- Typography
- Routing with GoRouter
- Core widgets
- Error handling
- Validators
- Local storage setup
- Firebase setup
- Auth basic flow, optional for MVP

Deliverables:

- App launches successfully
- Navigation works
- Theme works
- Core widgets ready
- Basic home screen ready

---

## Phase 2 — CV Builder MVP

Build:

- CV data models
- CV form stepper
- Personal info step
- Education step
- Experience step
- Skills step
- Projects step
- CV save/edit/delete
- CV preview
- PDF export

Deliverables:

- User can create a CV
- User can preview a CV
- User can export PDF
- User can save multiple CVs

---

## Phase 3 — AI Features

Build:

- AI service abstraction
- AI prompt builder
- AI response parser
- Summary generator
- Objective generator
- Experience bullet improver
- Project description improver
- Cover letter generator

Deliverables:

- User can generate AI summary
- User can generate AI career objective
- User can improve CV text
- User can generate cover letter

---

## Phase 4 — Job Tracker

Build:

- Job application model
- Add/edit/delete application
- Status flow
- Reminder date field
- Dashboard summary
- Application details screen

Deliverables:

- User can track applications
- User can update status
- User can view dashboard summary

---

## Phase 5 — ATS + Job Match

Build:

- Rule-based ATS checker
- Job post parser
- Keyword matching
- Missing skills suggestion
- CV match score
- Job post based improvement suggestion

Deliverables:

- User can check CV quality
- User can paste job post
- User can see match suggestions

---

## Phase 6 — Polish

Build:

- UI polish
- Empty states
- Error states
- Loading states
- Smooth animations
- Premium screen placeholder
- Play Store preparation assets/copy
- App icon integration

Deliverables:

- Production-like app experience
- Play Store ready MVP

---

## UI/UX Guidelines

Design style:

- Clean
- Modern
- Professional
- Trustworthy
- Mobile-first
- Student-friendly
- Easy for Bangladeshi users

Use:

- Cards
- Stepper forms
- Progress indicators
- Clear CTA buttons
- Empty states
- Error states
- Preview screens
- Smooth navigation
- Large readable text
- Clear section titles

Avoid:

- Overloaded screens
- Too much text in one place
- Random colors
- Tiny buttons
- Unclear icons
- Unnecessary animations
- Complex CV templates in MVP
- Too many settings

---

## Primary Screens

Required MVP screens:

```txt
SplashScreen
OnboardingScreen
LoginScreen
RegisterScreen
HomeScreen
ProfileScreen
CvListScreen
CvBuilderScreen
CvPreviewScreen
AiImproveScreen
CoverLetterScreen
JobTrackerScreen
JobApplicationDetailsScreen
InterviewPrepScreen
AtsCheckerScreen
SettingsScreen
```

Optional later screens:

```txt
SubscriptionScreen
PremiumTemplatesScreen
AiCreditsScreen
PdfHistoryScreen
LanguageSelectionScreen
NotificationSettingsScreen
```

---

## Home Screen Requirements

Home screen should show:

- Greeting
- Quick actions
- CV status
- Application tracker summary
- AI tools
- Recent CVs
- Recent job applications

Quick actions:

```txt
Create CV
Improve CV
Generate Cover Letter
Track Job
Interview Prep
ATS Check
```

---

## CV Builder UX Rules

CV builder should use a step-by-step flow.

Recommended steps:

```txt
1. Personal Info
2. Summary / Objective
3. Education
4. Experience
5. Skills
6. Projects
7. Training / Certifications
8. Languages
9. Template
10. Preview
```

Rules:

- Save draft automatically if possible.
- Allow skipping optional sections.
- Show progress indicator.
- Show validation errors clearly.
- Keep each step simple.
- Provide AI helper buttons where useful.
- Always allow user editing after AI generation.

---

## State Management Rules

Use Riverpod.

Preferred:

- `AsyncNotifier` for async feature state
- `Notifier` for sync feature state
- `FutureProvider` for simple async reads
- `Provider` for dependency injection
- `StateProvider` only for simple temporary UI state

Avoid:

- Business logic inside `setState`
- Large StatefulWidgets
- Global mutable variables
- Direct repository calls from widgets
- Direct Firebase calls from widgets

Every async feature must handle:

- Loading
- Success
- Empty
- Error

---

## Repository Pattern Rules

UI should not directly access Firebase, local database, or external APIs.

Correct:

```dart
final cvs = ref.watch(cvListControllerProvider);
```

Wrong:

```dart
FirebaseFirestore.instance.collection('cvs').get();
```

Repository contracts should be in domain layer.

Repository implementations should be in data layer.

---

## Firebase Rules

Use Firebase only through repositories/services.

Suggested Firestore collections:

```txt
users
cvs
job_applications
cover_letters
ai_generations
subscriptions
```

Every user-owned document must include:

```txt
userId
createdAt
updatedAt
```

Security rule mindset:

- User can only read/write their own documents.
- Never expose other users' data.
- Never store sensitive API secrets in Firestore.
- Avoid logging personal data.

---

## Local Storage Rules

Use local storage for:

- CV drafts
- Recently edited CVs
- App preferences
- Temporary form states
- Offline job application drafts

Local-first approach is preferred for MVP if Firebase is not ready.

The app should not lose user input during navigation.

---

## AI Integration Rules

AI features must go through a dedicated service.

Recommended structure:

```txt
shared/services/ai/
  ai_career_service.dart
  ai_prompt_builder.dart
  ai_response_parser.dart
```

Do not put prompts directly inside UI files.

All AI prompts must:

- Be clear
- Be reusable
- Include user intent
- Mention output language
- Avoid overpromising
- Ask AI to return structured output when needed
- Keep user privacy in mind

Never expose OpenAI API key in client code for production.

Production rule:

- Use backend/proxy/cloud function for OpenAI API.
- Client should call secure backend endpoint.

Development rule:

- `.env` can be used locally.
- Never commit real keys.

---

## AI Output Rules

AI-generated output should:

- Be professional
- Be concise
- Be editable
- Avoid fake claims
- Avoid invented experience
- Avoid guaranteed job promises
- Match user's experience level
- Support English and Bangla when requested

AI must not invent:

- Company names
- Degrees
- Certifications
- Years of experience
- Achievements
- Salary
- Job offers

If user input is weak, AI should improve wording but not create false information.

---

## AI Prompt Categories

Create reusable prompts for:

```txt
generateProfessionalSummary
generateCareerObjective
improveExperienceBullet
improveProjectDescription
suggestSkills
generateCoverLetter
generateJobApplicationEmail
generateLinkedInMessage
analyzeJobPost
calculateCvJobMatch
generateInterviewQuestions
generateInterviewAnswers
generateAtsSuggestions
```

---

## PDF Rules

PDF output must be:

- Clean
- ATS-friendly
- Black/white or minimal color
- Professional
- Readable
- Properly spaced
- Easy to scan
- Suitable for email submission

CV PDF should support:

- Preview
- Download
- Share
- Regenerate

Avoid:

- Heavy graphics
- Complex tables
- Too many colors
- Large icons
- Unreadable fonts
- Over-designed templates

MVP templates:

```txt
Classic
Modern
Minimal
Professional
Fresher
```

---

## Localization Rules

Design the app for Bangla and English support.

Initial priority:

- English UI acceptable
- Bangla AI guidance important
- Bangla/English output selection required for AI features

Rules:

- Do not scatter hardcoded user-facing text everywhere.
- Keep strings localization-ready.
- Use simple English.
- Use natural Bangla.
- Avoid overly formal Bangla unless used in official letters.

---

## Validation Rules

Forms must validate:

- Required fields
- Email format
- Phone number format
- Date format
- Empty education/experience states
- Too short AI input
- Invalid job application status
- Invalid salary range
- Invalid URL where needed

Bangladesh phone validation should support:

```txt
01XXXXXXXXX
+8801XXXXXXXXX
8801XXXXXXXXX
```

---

## Error Handling

Use app-level error handling.

Create:

```txt
core/errors/app_exception.dart
core/errors/failure.dart
core/utils/result.dart
```

Every repository should return predictable success/error result.

Do not silently fail.

Show user-friendly error messages:

```txt
Network error. Please check your internet connection.
Something went wrong. Please try again.
AI generation failed. Please try again.
PDF export failed. Please check your CV information.
Please fill in the required fields.
```

---

## Loading / Empty / Error State Rules

Every list screen must include:

- Loading state
- Empty state
- Error state
- Success state

Example empty messages:

```txt
No CV created yet. Create your first professional CV.
No job applications tracked yet. Add your first application.
No cover letter generated yet. Generate one for your next job.
```

---

## Security Rules

Never:

- Store API keys in source code
- Log sensitive user data
- Log AI prompts containing personal data in production
- Save passwords manually
- Expose Firestore documents without user ownership check
- Commit `.env`
- Commit Firebase private credentials
- Commit generated secrets

Use:

- Environment variables
- Secure backend for AI calls
- Firebase security rules
- User ownership checks

---

## Privacy Rules

This app handles sensitive career data.

Be careful with:

- User name
- Phone number
- Email
- Education history
- Employment history
- CV content
- Job applications
- AI prompts

User data must not be shared publicly.

Do not include personal data in analytics without consent.

---

## Monetization Plan

MVP can include premium placeholder only.

Possible future monetization:

Free plan:

- 1 CV
- Basic templates
- Limited AI generations
- Basic PDF export

Premium plan:

- Unlimited CVs
- No watermark
- Premium templates
- ATS checker
- Job post match
- Unlimited cover letters
- Interview question generator
- Cloud backup

AI credit model:

```txt
20 credits
50 credits
150 credits
```

Do not implement payment gateway unless explicitly requested.

---

## Play Store Policy Notes

Do not make misleading claims.

Avoid:

```txt
Guaranteed job
100% ATS pass
Get hired instantly
Official government job app
Official Bdjobs app
Official LinkedIn app
```

Use:

```txt
AI-powered suggestions
Helps improve your CV
Create professional CVs
Track your job applications
ATS-friendly CV suggestions
```

---

## App Copy Guidelines

Tone:

- Helpful
- Professional
- Simple
- Encouraging
- Honest

Avoid:

- Overpromising
- Fake urgency
- Too much marketing language
- Complex career jargon

Example good copy:

```txt
Create your first professional CV
Improve your CV with AI suggestions
Generate a cover letter for this job
Track where you applied
Prepare for your next interview
```

---

## Testing Rules

When adding important logic, add tests where practical.

Prioritize tests for:

- CV validation
- ATS score calculation
- Job post keyword matching
- AI prompt builder
- Repository mapping
- Date/status logic
- Phone/email validation
- PDF input mapping

Run before final response when possible:

```bash
dart format .
flutter analyze
flutter test
```

If unable to run, clearly mention why.

---

## Code Quality Checklist

Before finalizing any task:

- Run formatter
- Fix analyzer warnings
- Remove unused imports
- Remove dead code
- Check naming
- Check null safety
- Check responsive layout
- Check loading states
- Check empty states
- Check error states
- Check if any secret is accidentally added
- Check if UI works on small screens

Commands:

```bash
dart format .
flutter analyze
flutter test
```

---

## Git Rules

Use small, meaningful commits.

Branch naming examples:

```txt
feature/project-foundation
feature/cv-builder
feature/ai-cover-letter
feature/job-tracker
feature/ats-checker
fix/pdf-export
fix/auth-flow
refactor/ai-service
refactor/cv-models
```

Commit message examples:

```txt
feat: add project foundation
feat: add CV builder stepper
feat: implement AI summary generator
feat: implement cover letter generator
feat: add job application tracker
fix: handle empty CV list state
fix: resolve PDF export overflow
refactor: move AI prompts to prompt builder
```

---

## Development Workflow for Codex

When working on any task:

1. Inspect existing files first.
2. Understand current architecture.
3. Make a short implementation plan.
4. Implement only the requested feature/fix.
5. Reuse existing patterns.
6. Do not create duplicate utilities.
7. Do not introduce breaking changes.
8. Run formatter/analyzer/tests if possible.
9. Summarize changes clearly.

When uncertain:

- Make the safest reasonable assumption.
- Continue with minimal changes.
- Mention the assumption in the final summary.

---

## Codex Response Style

Keep responses short and useful.

Always include:

```txt
Summary
Changed files
Test result
Next recommended step
```

Avoid:

- Long theory
- Unrelated suggestions
- Repeating full code unless necessary
- Changing unrelated files
- Adding unnecessary packages
- Over-engineering simple tasks

---

## Current Build Priority

Start from fresh project.

Recommended first implementation order:

```txt
1. Create Flutter project foundation
2. Add app theme
3. Add GoRouter navigation
4. Add core reusable widgets
5. Add home screen
6. Add CV models
7. Add CV builder form
8. Add CV preview
9. Add PDF export
10. Add AI service abstraction
11. Add AI summary/objective generator
12. Add cover letter generator
13. Add job tracker
14. Add ATS checker
15. Polish UI/UX
```

---

## First Milestone

Milestone name:

```txt
MVP Foundation
```

Goal:

Set up a clean Flutter foundation for CareerMate BD with routing, theme, core widgets, and initial screens.

Required tasks:

```txt
- Initialize project structure
- Add app theme
- Add route management
- Add reusable widgets
- Add splash screen
- Add onboarding screen
- Add home screen
- Add settings screen
- Add placeholder screens for core features
```

---

## Second Milestone

Milestone name:

```txt
CV Builder MVP
```

Goal:

Allow users to create, edit, preview, and export a professional CV.

Required tasks:

```txt
- Create CV models
- Create CV builder stepper
- Add personal info form
- Add education form
- Add experience form
- Add skills form
- Add project form
- Add CV preview screen
- Add PDF export service
- Add local draft save
```

---

## Third Milestone

Milestone name:

```txt
AI Career Tools
```

Goal:

Add AI-powered career writing tools.

Required tasks:

```txt
- Create AI service abstraction
- Create AI prompt builder
- Add professional summary generator
- Add career objective generator
- Add experience bullet improver
- Add project description improver
- Add cover letter generator
- Add job application email generator
```

---

## Fourth Milestone

Milestone name:

```txt
Job Tracker
```

Goal:

Allow users to track job applications.

Required tasks:

```txt
- Create job application model
- Add job tracker list
- Add application create/edit form
- Add application details screen
- Add status update
- Add dashboard summary
```

---

## Fifth Milestone

Milestone name:

```txt
ATS and Job Match
```

Goal:

Provide CV improvement suggestions and job post matching.

Required tasks:

```txt
- Create ATS checker rules
- Add CV score screen
- Add job post paste screen
- Add keyword match logic
- Add missing skill suggestions
- Add AI improvement suggestions
```

---

## Final Product Reminder

CareerMate BD should not be treated as only a CV maker.

It is:

```txt
AI Career Assistant for Bangladesh
```

Every feature should support this direction.
