# App Store privacy label ("App Privacy" in App Store Connect)

These are the answers for CvMate 1.0, written from what the code does in this
branch, the server (cvmate-api) and the privacy policy
(https://api.khokan.me/cvmate/privacy). **You submit them; check every row
against the policy before you do.** The rows marked ⚠ are judgement calls
that you should confirm.

## Does the app track? **No.**

- No advertising identifier. iOS links `FirebaseAnalytics/Core` without
  IdentitySupport, so AdSupport is not linked and no IDFA is read.
- No App Tracking Transparency prompt.
- Nothing is shared with data brokers or used for targeted ads.

Therefore every data type below is **Used for tracking: No**.

## Do you collect data? **Yes.**

Apple counts data as "collected" when it leaves the device and is kept longer
than needed to answer the request in real time.

| Category → data type | Collected because | Linked to the user? | Purposes |
|---|---|---|---|
| **Contact Info → Email Address** | Firebase sign-in. The reply email on feedback, only if the user ticks it. The CV backup, if the CV contains an email. | Yes | App Functionality, Customer Support |
| **Contact Info → Name** | The CV backup in Firestore, if the user types a name in the CV. | Yes | App Functionality |
| **Contact Info → Phone Number** | The CV backup, if the CV contains a phone number. | Yes | App Functionality |
| **Contact Info → Physical Address** ⚠ | The CV backup, if the user types an address in the CV. | Yes | App Functionality |
| **User Content → Photos or Videos** | The CV photo, in the backup, only if the user adds one. | Yes | App Functionality |
| **User Content → Customer Support** | *Report a problem / Send feedback* messages, stored on our server under a hash of the user id. | Yes | Customer Support |
| **User Content → Other User Content** | CV text in the Firestore backup. CV text and job posts sent for AI features. Anthropic keeps these for a limited time for abuse checks. | Yes | App Functionality |
| **Sensitive Info** ⚠ | Optional CV fields (date of birth, nationality, marital status, religion, gender, passport) are in the CV backup when the user fills them in. They are never sent to the AI. Declare this if any of those fields can hold religion or similar data. | Yes | App Functionality |
| **Identifiers → User ID** | Firebase uid: sign-in, CV backup, server quota and plan, and the RevenueCat app user id. Crashlytics gets a SHA-256 hash of it. | Yes | App Functionality, Analytics |
| **Identifiers → Device ID** | The Firebase Analytics app-instance id, plus IDFV collection, which stays on. Not tied to the account, because we never set an Analytics user id. | No | Analytics |
| **Purchases → Purchase History** | The plan, Pro expiry, one-CV unlocks and RevenueCat purchase events on our server. | Yes | App Functionality |
| **Usage Data → Product Interaction** | Firebase Analytics events and screen views. Enums and buckets only, with no content. | No | Analytics |
| **Diagnostics → Crash Data** | Firebase Crashlytics: the error type and stack only, no message. | Yes (hashed user id) | App Functionality, Analytics |
| **Diagnostics → Performance Data** | AI latency buckets in Analytics. | No | Analytics |
| **Diagnostics → Other Diagnostic Data** | The optional "attach diagnostics" block on feedback: app, OS and device model and the last 20 event names. Non-fatal error codes in Crashlytics. | Yes | App Functionality, Customer Support |

### Not collected

Location (precise or coarse), Health & Fitness, Financial Info (Apple takes
payment; RevenueCat and our server never see card details), Contacts,
Browsing History, Search History, Emails or Text Messages, Audio, Gameplay
Content, Advertising Data, Other Data Types.

## Notes for the form

- **"Linked to the user"** means we, or a provider acting for us, can tie it
  to the account. Feedback uses `sha256(app_id, uid)`. That is still linkable,
  because we can hash a known uid, so it is declared linked.
- **Analytics opt-out.** Data that users can opt out of is still declared;
  the label has no "optional" column. The policy says that analytics and
  crash reports are on by default and how to turn them off.
- **Third parties** (Google Firebase, Anthropic, RevenueCat, Apple and
  Contabo) process data for us. Their collection on our behalf is part of
  the rows above, not separate entries.
- **Data deletion.** Settings > Delete account deletes:
  - the Firebase account;
  - the Firestore CV backup;
  - the server plan, quota, unlocks and feedback;
  - local data.

  It also resets the Analytics id. Apple asks for this in guideline
  5.1.1(v).
- **When anything changes** (a new SDK, a new event with a new kind of
  data), update this file, the privacy policy and App Store Connect
  together.
