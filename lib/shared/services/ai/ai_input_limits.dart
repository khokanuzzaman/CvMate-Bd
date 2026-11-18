/// Client-side limits on the free text sent to the AI server, checked before
/// any request so an over-long paste fails fast with a message that says how
/// much to cut (instead of the server's bare 413).
abstract final class AiInputLimits {
  /// Max characters of a pasted job post (Tailor, ATS, cover letter, ...).
  /// Well inside the server body limit even for 3-byte UTF-8 (Bangla) text.
  static const int jobPostMaxChars = 12000;

  /// Max characters of the text being improved (a bullet, a project
  /// description).
  static const int inputTextMaxChars = 4000;

  /// The AI server's whole-request limit (cvmate-api `bodyLimit`,
  /// src/app.ts).
  static const int serverBodyLimitKb = 64;
}
