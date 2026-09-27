/// Shared constant vocabularies for the rule-based ATS engine.
///
/// These lists are intentionally role-agnostic so the engine scores CVs for any
/// profession (healthcare, finance, sales, trades, admin, creative, tech, ...),
/// not just software roles. They are plain data with no dependencies so they can
/// be reused and unit-tested in isolation.
library;

/// A broad, role-agnostic set of strong resume action verbs.
///
/// Bullet points that start with one of these read as concrete achievements to
/// both recruiters and ATS parsers. Kept lowercase for case-insensitive checks.
const Set<String> atsActionVerbs = {
  // General achievement / leadership
  'achieved', 'advanced', 'championed', 'completed', 'delivered', 'directed',
  'drove', 'earned', 'exceeded', 'executed', 'led', 'managed', 'orchestrated',
  'organized', 'oversaw', 'owned', 'spearheaded', 'succeeded',
  // Building / creating
  'built', 'created', 'designed', 'developed', 'engineered', 'established',
  'formed', 'founded', 'implemented', 'initiated', 'introduced', 'launched',
  'produced', 'shaped',
  // Improvement / optimization
  'accelerated', 'boosted', 'enhanced', 'expanded', 'grew', 'improved',
  'increased', 'maximized', 'modernized', 'optimized', 'reduced', 'refined',
  'reorganized', 'restructured', 'revamped', 'streamlined', 'strengthened',
  'transformed', 'upgraded',
  // Analysis / problem solving
  'analyzed', 'assessed', 'audited', 'diagnosed', 'evaluated', 'examined',
  'forecasted', 'identified', 'investigated', 'measured', 'monitored',
  'researched', 'resolved', 'reviewed', 'solved', 'tested', 'troubleshot',
  'validated',
  // Coordination / operations / support
  'administered', 'arranged', 'automated', 'consolidated', 'coordinated',
  'facilitated', 'handled', 'maintained', 'operated', 'processed', 'scheduled',
  'supervised', 'supported',
  // Sales / customer / communication
  'advised', 'advocated', 'closed', 'communicated', 'consulted', 'counseled',
  'educated', 'generated', 'guided', 'influenced', 'marketed', 'negotiated',
  'onboarded', 'persuaded', 'pitched', 'presented', 'promoted', 'recruited',
  'retained', 'served', 'sold', 'trained',
  // Healthcare / care
  'assisted', 'cared', 'documented', 'prescribed', 'rehabilitated', 'treated',
  // Finance / accounting / compliance
  'allocated', 'balanced', 'budgeted', 'calculated', 'reconciled',
  // Creative / content
  'authored', 'branded', 'composed', 'crafted', 'edited', 'illustrated',
  'published', 'wrote',
  // Teaching / mentoring
  'coached', 'instructed', 'mentored', 'tutored',
};

/// Common English function words plus recruiting boilerplate that should never
/// be treated as salient job-post keywords. Kept lowercase.
const Set<String> atsStopWords = {
  // Articles / determiners / pronouns
  'a', 'an', 'the', 'this', 'that', 'these', 'those', 'it', 'its', 'we', 'our',
  'us', 'you', 'your', 'yours', 'they', 'them', 'their', 'theirs', 'i', 'me',
  'my', 'he', 'she', 'his', 'her', 'who', 'whom', 'whose', 'which', 'what',
  // Conjunctions / prepositions
  'and', 'or', 'but', 'nor', 'so', 'yet', 'of', 'to', 'in', 'on', 'at', 'by',
  'for', 'with', 'without', 'within', 'from', 'into', 'onto', 'over', 'under',
  'about', 'across', 'through', 'between', 'among', 'per', 'via', 'plus', 'as',
  'than', 'then', 'because', 'while', 'during', 'after', 'before', 'up', 'off',
  // Auxiliary / common verbs
  'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being', 'has', 'have', 'had',
  'do', 'does', 'did', 'will', 'would', 'shall', 'should', 'can', 'could', 'may',
  'might', 'must', 'get', 'got', 'using', 'use', 'used', 'include', 'includes',
  'including', 'ensure', 'ensuring', 'help', 'helping',
  // Generic filler
  'more', 'most', 'less', 'least', 'very', 'much', 'many', 'some', 'any', 'all',
  'each', 'every', 'other', 'such', 'good', 'great', 'strong', 'able', 'well',
  'high', 'highly', 'new', 'both', 'also', 'not', 'only', 'here', 'there',
  'when', 'where', 'why', 'how', 'etc',
  // Recruiting / job-post boilerplate
  'job', 'jobs', 'role', 'roles', 'position', 'positions', 'candidate',
  'candidates', 'applicant', 'applicants', 'apply', 'application', 'hiring',
  'hire', 'seeking', 'looking', 'wanted', 'needed', 'need', 'needs', 'require',
  'required', 'requires', 'requirement', 'requirements', 'responsibility',
  'responsibilities', 'duty', 'duties', 'qualification', 'qualifications',
  'qualified', 'preferred', 'preferable', 'desirable', 'bonus', 'ideal',
  'company', 'team', 'teams', 'department', 'work', 'working', 'experience',
  'experienced', 'skill', 'skills', 'ability', 'abilities', 'knowledge',
  'understanding', 'proficiency', 'proficient', 'familiar', 'familiarity',
  'expertise', 'competency', 'year', 'years', 'month', 'months', 'day', 'days',
  'week', 'weeks', 'full', 'part', 'time', 'salary', 'benefit', 'benefits',
  'join', 'joining', 'opportunity', 'environment', 'comfortable',
};

/// Display-form overrides for keywords whose natural title-casing looks wrong.
/// Keyed by the lowercase phrase. Anything not listed falls back to acronym-aware
/// title-casing, so this only needs the tricky special cases.
const Map<String, String> atsKeywordDisplayOverrides = {
  'api': 'API',
  'api integration': 'API Integration',
  'github': 'GitHub',
  'gitlab': 'GitLab',
  'go router': 'GoRouter',
  'ios': 'iOS',
  'javascript': 'JavaScript',
  'typescript': 'TypeScript',
  'nodejs': 'Node.js',
  'node.js': 'Node.js',
  'node js': 'Node.js',
  'power bi': 'Power BI',
  'problem solving': 'Problem Solving',
  'rest api': 'REST API',
  'spring boot': 'Spring Boot',
  'ui': 'UI',
  'ux': 'UX',
  'ui/ux': 'UI/UX',
};

/// Keywords that a "Training / Certifications" section can plausibly cover.
/// Kept small and role-agnostic (extend as new certifiable skills come up).
const Set<String> atsTrainableKeywords = {
  'excel', 'firebase', 'flutter', 'git', 'github', 'power bi', 'rest api',
  'sql', 'ui/ux', 'first aid', 'cpr', 'accounting', 'bookkeeping', 'quickbooks',
  'photoshop', 'illustrator', 'autocad',
};
