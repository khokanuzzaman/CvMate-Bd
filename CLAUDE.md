# CLAUDE.md — CvMate

## What this app is
CvMate (id `careermatebd`, package `com.khokan.careermatebd`) is a mobile-first, AI-powered
career copilot: CV/resume builder + per-job tailoring + ATS checker + cover letters +
interview prep + job tracker. We are evolving it from a Bangladesh-only tool into a global,
multilingual product. Target: mobile-first job seekers in the South Asia → Gulf/SEA corridor
first, global English second.

## The product truth (build around this)
Per-job TAILORING is the core loop: "paste a job post → ATS score + tailored CV + matched
cover letter → export." Tailored resumes get far higher response rates and ~99% of employers
use ATS keyword filters. Make tailoring effortless and central; other features orbit it.

## Architecture (do not violate)
Feature-first + layered: presentation → domain → data. State = Riverpod. Nav = GoRouter.
Local storage = Hive. Auth = Firebase. PDF = `pdf` + `printing`. Network = `dio`. AI goes
through the service layer in lib/shared/services/ai/.

## Hard rules
- Match existing folder/layer structure and neighboring-file patterns before inventing new ones.
- No business logic in widgets — use Riverpod providers + repositories + services.
- Always handle loading/empty/error/success (reuse core/widgets/).
- NEVER hardcode secrets/keys/private URLs. AI keys stay behind the proxy
  (EnvConfig.openAiProxyUrl); never ship keys in the client.
- Don't remove existing functionality unless told. Minimal, focused changes. Small files.
- Null-safety correct; readable over clever.
- Add/update tests under test/ mirroring the feature path. Run `flutter analyze` and
  `flutter test` before finishing and report results.
- UI strings should be localization-ready (i18n arrives in Phase 2).

## Definition of done (every session)
Compiles, `flutter analyze` clean (no new warnings), relevant tests pass, change is
self-contained, and you end with a short summary of what changed and why.
