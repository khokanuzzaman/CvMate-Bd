/* eslint-disable require-jsdoc */

import OpenAI from "openai";
import * as logger from "firebase-functions/logger";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const openAiApiKey = defineSecret("OPENAI_API_KEY");

const callableRegion = "us-central1";
const openAiModel = "gpt-4o-mini";
const genericFailureMessage = "AI generation failed. Please try again.";

const supportedActions = [
  "generateProfessionalSummary",
  "generateCareerObjective",
  "improveExperienceBullet",
  "improveProjectDescription",
  "suggestSkills",
  "generateCoverLetter",
  "generateJobApplicationEmail",
  "generateLinkedInMessage",
  "generateInterviewQuestions",
  "generateAtsSuggestions",
  "analyzeJobPost",
  "calculateCvJobMatch",
] as const;

type CareerAiAction = (typeof supportedActions)[number];
type LanguageCode = "english" | "bangla";
type ToneCode = "professional" | "formal" | "simple" | "confident";
type JsonObject = Record<string, unknown>;

interface StructuredSchema {
  name: string;
  schema: Record<string, unknown>;
}

interface CareerAiResponseEnvelope {
  success: boolean;
  action: CareerAiAction;
  content?: unknown;
  suggestions?: string[];
  usage?: {
    model: string;
    inputTokens?: number;
    outputTokens?: number;
    totalTokens?: number;
  };
  error?: string;
}

const textSuggestionSchema: StructuredSchema = {
  name: "career_text_suggestion",
  schema: {
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "originalText",
      "suggestedText",
      "guidancePoints",
      "language",
    ],
    properties: {
      title: {type: "string"},
      originalText: {type: "string"},
      suggestedText: {type: "string"},
      guidancePoints: {
        type: "array",
        items: {type: "string"},
      },
      language: {
        type: "string",
        enum: ["english", "bangla"],
      },
    },
  },
};

const skillSuggestionSchema: StructuredSchema = {
  name: "career_skill_suggestions",
  schema: {
    type: "object",
    additionalProperties: false,
    required: ["items"],
    properties: {
      items: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["name", "reason"],
          properties: {
            name: {type: "string"},
            reason: {type: "string"},
          },
        },
      },
    },
  },
};

const documentDraftSchema: StructuredSchema = {
  name: "career_document_draft",
  schema: {
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "subjectLine",
      "body",
      "highlights",
      "language",
      "tone",
    ],
    properties: {
      title: {type: "string"},
      subjectLine: {type: "string"},
      body: {type: "string"},
      highlights: {
        type: "array",
        items: {type: "string"},
      },
      language: {
        type: "string",
        enum: ["english", "bangla"],
      },
      tone: {
        type: "string",
        enum: ["professional", "formal", "simple", "confident"],
      },
    },
  },
};

const interviewQuestionSchema: StructuredSchema = {
  name: "career_interview_questions",
  schema: {
    type: "object",
    additionalProperties: false,
    required: ["title", "language", "questions"],
    properties: {
      title: {type: "string"},
      language: {
        type: "string",
        enum: ["english", "bangla"],
      },
      questions: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: [
            "question",
            "whyItMatters",
            "answerTip",
            "sampleAnswer",
          ],
          properties: {
            question: {type: "string"},
            whyItMatters: {type: "string"},
            answerTip: {type: "string"},
            sampleAnswer: {type: "string"},
          },
        },
      },
    },
  },
};

const atsSuggestionSchema: StructuredSchema = {
  name: "career_ats_suggestions",
  schema: {
    type: "object",
    additionalProperties: false,
    required: ["headline", "strengths", "suggestions"],
    properties: {
      headline: {type: "string"},
      strengths: {
        type: "array",
        items: {type: "string"},
      },
      suggestions: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["title", "description", "severity"],
          properties: {
            title: {type: "string"},
            description: {type: "string"},
            severity: {
              type: "string",
              enum: ["high", "medium", "low"],
            },
          },
        },
      },
    },
  },
};

const jobPostAnalysisSchema: StructuredSchema = {
  name: "career_job_post_analysis",
  schema: {
    type: "object",
    additionalProperties: false,
    required: [
      "roleTitle",
      "companyName",
      "summary",
      "requiredSkills",
      "preferredSkills",
      "keywords",
    ],
    properties: {
      roleTitle: {type: "string"},
      companyName: {type: "string"},
      summary: {type: "string"},
      requiredSkills: {
        type: "array",
        items: {type: "string"},
      },
      preferredSkills: {
        type: "array",
        items: {type: "string"},
      },
      keywords: {
        type: "array",
        items: {type: "string"},
      },
    },
  },
};

const cvJobMatchSchema: StructuredSchema = {
  name: "career_cv_job_match",
  schema: {
    type: "object",
    additionalProperties: false,
    required: [
      "matchScore",
      "assessment",
      "matchedSkills",
      "missingSkills",
      "suggestedSummary",
      "priorityActions",
    ],
    properties: {
      matchScore: {type: "integer"},
      assessment: {type: "string"},
      matchedSkills: {
        type: "array",
        items: {type: "string"},
      },
      missingSkills: {
        type: "array",
        items: {type: "string"},
      },
      suggestedSummary: {type: "string"},
      priorityActions: {
        type: "array",
        items: {type: "string"},
      },
    },
  },
};

export const generateCareerAiContent = onCall(
  {
    region: callableRegion,
    secrets: [openAiApiKey],
    maxInstances: 10,
  },
  async (request): Promise<CareerAiResponseEnvelope> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Please login to use AI features.",
      );
    }

    const payload = asObject(request.data);
    if (payload === null) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid AI request payload.",
      );
    }

    const action = parseAction(payload.action);
    const language = parseLanguage(payload.language);
    const tone = parseTone(payload.tone);
    const inputText = readString(payload.inputText);
    const jobPost = readString(payload.jobPost);
    const metadata = asObject(payload.metadata) ?? {};
    const cvData = normalizeCvData(payload.cvData);

    validateRequest({
      action,
      inputText,
      jobPost,
      cvData,
      metadata,
    });

    logger.info("career_ai_request_received", {
      uid,
      action,
      language,
      tone,
      hasCvData: cvData !== null,
      inputLength: inputText.length,
      jobPostLength: jobPost.length,
      metadataKeys: Object.keys(metadata),
    });

    // TODO(careermatebd): Add per-user AI credit deduction or rate limiting
    // here before invoking the model in production monetization flows.

    try {
      const client = new OpenAI({
        apiKey: openAiApiKey.value(),
      });

      const prompt = buildPrompt({
        action,
        language,
        tone,
        cvData,
        inputText,
        jobPost,
        metadata,
      });

      const schema = schemaForAction(action);
      const response = await client.responses.create({
        model: openAiModel,
        input: [
          {
            role: "system",
            content: prompt.system,
          },
          {
            role: "user",
            content: prompt.user,
          },
        ],
        text: {
          format: {
            type: "json_schema",
            name: schema.name,
            strict: true,
            schema: schema.schema,
          },
        },
      });

      const rawOutput = response.output_text.trim();
      if (rawOutput.length === 0) {
        logger.warn("career_ai_empty_output", {uid, action});
        return failureEnvelope(action, genericFailureMessage);
      }

      const parsed = JSON.parse(rawOutput) as unknown;
      const content = unwrapStructuredContent(action, parsed);

      return {
        success: true,
        action,
        content,
        usage: {
          model: openAiModel,
          inputTokens: response.usage?.input_tokens,
          outputTokens: response.usage?.output_tokens,
          totalTokens: response.usage?.total_tokens,
        },
      };
    } catch (error) {
      logger.error("career_ai_generation_failed", {
        uid,
        action,
        message: error instanceof Error ? error.message : "unknown_error",
      });

      return failureEnvelope(action, genericFailureMessage);
    }
  },
);

function parseAction(value: unknown): CareerAiAction {
  const action = readString(value);
  if (supportedActions.includes(action as CareerAiAction)) {
    return action as CareerAiAction;
  }

  throw new HttpsError("invalid-argument", "Unsupported AI action.");
}

function parseLanguage(value: unknown): LanguageCode {
  return readString(value).toLowerCase() === "bangla" ? "bangla" : "english";
}

function parseTone(value: unknown): ToneCode {
  switch (readString(value).toLowerCase()) {
  case "formal":
    return "formal";
  case "simple":
    return "simple";
  case "confident":
    return "confident";
  default:
    return "professional";
  }
}

function validateRequest({
  action,
  inputText,
  jobPost,
  cvData,
  metadata,
}: {
  action: CareerAiAction;
  inputText: string;
  jobPost: string;
  cvData: JsonObject | null;
  metadata: JsonObject;
}): void {
  switch (action) {
  case "generateProfessionalSummary":
  case "generateCareerObjective":
  case "suggestSkills":
  case "generateInterviewQuestions":
  case "generateAtsSuggestions":
    ensureCvData(cvData);
    return;
  case "improveExperienceBullet":
    ensureCvData(cvData);
    ensureMinLength(inputText, 8, "Your input is too short.");
    return;
  case "improveProjectDescription":
    ensureCvData(cvData);
    ensureMinLength(inputText, 12, "Your input is too short.");
    return;
  case "generateCoverLetter":
  case "generateJobApplicationEmail":
  case "generateLinkedInMessage":
    ensureMinLength(
      readString(metadata.companyName),
      2,
      "Please enter the target company name.",
    );
    ensureMinLength(
      readString(metadata.jobTitle),
      2,
      "Please enter the job title.",
    );
    if (!hasMeaningfulCvData(cvData)) {
      ensureMinLength(
        readString(metadata.candidateSummary),
        20,
        "Your input is too short.",
      );
    }
    return;
  case "analyzeJobPost":
    ensureMinLength(jobPost, 30, "Your input is too short.");
    return;
  case "calculateCvJobMatch":
    ensureCvData(cvData);
    ensureMinLength(jobPost, 30, "Your input is too short.");
    return;
  default:
    return;
  }
}

function ensureCvData(cvData: JsonObject | null): void {
  if (!hasMeaningfulCvData(cvData)) {
    throw new HttpsError(
      "invalid-argument",
      "Please select a CV or add more profile details first.",
    );
  }
}

function hasMeaningfulCvData(cvData: JsonObject | null): boolean {
  if (cvData === null) {
    return false;
  }

  const textFields = [
    readString(cvData.title),
    readString(cvData.desiredRole),
    readString(cvData.professionalSummary),
    readString(cvData.careerObjective),
  ];
  if (textFields.some((value) => value.length > 0)) {
    return true;
  }

  const listKeys = [
    "education",
    "experiences",
    "skills",
    "projects",
    "trainings",
    "languages",
  ];

  return listKeys.some((key) => {
    const value = cvData[key];
    return Array.isArray(value) && value.length > 0;
  });
}

function ensureMinLength(
  value: string,
  minLength: number,
  message: string,
): void {
  if (value.trim().length < minLength) {
    throw new HttpsError("invalid-argument", message);
  }
}

function buildPrompt({
  action,
  language,
  tone,
  cvData,
  inputText,
  jobPost,
  metadata,
}: {
  action: CareerAiAction;
  language: LanguageCode;
  tone: ToneCode;
  cvData: JsonObject | null;
  inputText: string;
  jobPost: string;
  metadata: JsonObject;
}): {system: string; user: string} {
  const system = [
    "You are CareerMate BD AI, a practical career writing assistant for",
    "Bangladeshi job seekers.",
    "Return only content that matches the provided JSON schema.",
    language === "bangla" ?
      "Write user-facing text in natural Bangla." :
      "Write user-facing text in clear English.",
    `Use a ${tone} tone when appropriate.`,
    "Keep responses professional, editable, concise, and realistic.",
    "Do not invent company names, degrees, certifications, years of",
    "experience, measurable achievements, salaries, or job offers.",
    "If user input is weak, improve wording only and stay honest.",
    "Never promise guaranteed ATS passing or guaranteed hiring outcomes.",
  ].join(" ");

  const contextLines = [
    `Action: ${action}`,
    `Language: ${language}`,
    `Tone: ${tone}`,
  ];

  if (cvData !== null) {
    contextLines.push(`CV snapshot: ${JSON.stringify(cvData, null, 2)}`);
  }
  if (inputText.trim().length > 0) {
    contextLines.push(`Input text: ${inputText.trim()}`);
  }
  if (jobPost.trim().length > 0) {
    contextLines.push(`Job post: ${jobPost.trim()}`);
  }
  if (Object.keys(metadata).length > 0) {
    contextLines.push(`Metadata: ${JSON.stringify(metadata, null, 2)}`);
  }
  contextLines.push(instructionForAction(action, metadata));

  return {
    system,
    user: contextLines.join("\n\n"),
  };
}

function instructionForAction(
  action: CareerAiAction,
  metadata: JsonObject,
): string {
  switch (action) {
  case "generateProfessionalSummary":
    return [
      "Write a concise ATS-friendly professional summary.",
      "Keep it to 2 or 3 focused lines.",
      "Include 2 short guidance points for editing.",
    ].join(" ");
  case "generateCareerObjective":
    return [
      "Write a short, practical career objective.",
      "Make it fresher-friendly when the profile is early-career.",
      "Include 2 short guidance points for editing.",
    ].join(" ");
  case "improveExperienceBullet":
    return [
      "Rewrite the experience bullet with stronger action verbs.",
      "Do not add metrics or achievements unless they are already supported.",
      "Include 2 short guidance points for editing.",
    ].join(" ");
  case "improveProjectDescription":
    return [
      "Rewrite the project description so it sounds clearer and more",
      "professional.",
      "Do not invent features or technologies.",
      "Include 2 short guidance points for editing.",
    ].join(" ");
  case "suggestSkills":
    return [
      "Suggest relevant, ATS-friendly skills to highlight next.",
      "Keep suggestions realistic for the candidate profile.",
      `Return no more than ${readPositiveInt(metadata.maxSuggestions, 5)}`,
      "skill suggestions.",
    ].join(" ");
  case "generateCoverLetter":
    return readBool(metadata.isShortVersion) ?
      "Write a short editable cover letter for a quick application." :
      "Write a formal editable cover letter tailored to the target role.";
  case "generateJobApplicationEmail":
    return [
      "Write a respectful job application email.",
      "Keep it concise and suitable for direct submission.",
    ].join(" ");
  case "generateLinkedInMessage":
    return [
      "Write a short LinkedIn message that feels human, respectful,",
      "and not pushy.",
    ].join(" ");
  case "generateInterviewQuestions":
    return [
      "Generate practical interview questions based on the CV and job",
      "context.",
      "For each question, include why it matters, one answer tip,",
      "and a short sample answer.",
    ].join(" ");
  case "generateAtsSuggestions":
    return [
      "Provide ATS-friendly suggestions only.",
      "Use honest wording like may improve clarity or may improve matching.",
    ].join(" ");
  case "analyzeJobPost":
    return [
      "Analyze the job post and extract the most important role details,",
      "skills, and keywords.",
    ].join(" ");
  case "calculateCvJobMatch":
    return [
      "Estimate a realistic CV match score between 0 and 100.",
      "Highlight matched skills, missing skills, a suggested summary,",
      "and practical priority actions.",
      "Do not claim a guaranteed shortlist or guaranteed outcome.",
    ].join(" ");
  default:
    return "Provide a structured, practical response.";
  }
}

function schemaForAction(action: CareerAiAction): StructuredSchema {
  switch (action) {
  case "generateProfessionalSummary":
  case "generateCareerObjective":
  case "improveExperienceBullet":
  case "improveProjectDescription":
    return textSuggestionSchema;
  case "suggestSkills":
    return skillSuggestionSchema;
  case "generateCoverLetter":
  case "generateJobApplicationEmail":
  case "generateLinkedInMessage":
    return documentDraftSchema;
  case "generateInterviewQuestions":
    return interviewQuestionSchema;
  case "generateAtsSuggestions":
    return atsSuggestionSchema;
  case "analyzeJobPost":
    return jobPostAnalysisSchema;
  case "calculateCvJobMatch":
    return cvJobMatchSchema;
  default:
    return textSuggestionSchema;
  }
}

function unwrapStructuredContent(
  action: CareerAiAction,
  parsed: unknown,
): unknown {
  if (action !== "suggestSkills") {
    return parsed;
  }

  const map = asObject(parsed);
  return map?.items ?? [];
}

function failureEnvelope(
  action: CareerAiAction,
  message: string,
): CareerAiResponseEnvelope {
  return {
    success: false,
    action,
    error: message,
  };
}

function normalizeCvData(raw: unknown): JsonObject | null {
  const map = asObject(raw);
  if (map === null) {
    return null;
  }

  return compactObject({
    title: readString(map.title),
    desiredRole: readString(map.desiredRole),
    professionalSummary: readString(map.professionalSummary),
    careerObjective: readString(map.careerObjective),
    education: normalizeEducationList(map.education),
    experiences: normalizeExperienceList(map.experiences),
    skills: normalizeSkillList(map.skills),
    projects: normalizeProjectList(map.projects),
    trainings: normalizeTrainingList(map.trainings),
    languages: normalizeLanguageList(map.languages),
  });
}

function normalizeEducationList(value: unknown): JsonObject[] {
  return readObjectList(value)
    .map((item) => compactObject({
      institution: readString(item.institution),
      degree: readString(item.degree),
      fieldOfStudy: readString(item.fieldOfStudy),
      result: readString(item.result),
      startYear: readString(item.startYear),
      endYear: readString(item.endYear),
    }))
    .filter((item) => Object.keys(item).length > 0);
}

function normalizeExperienceList(value: unknown): JsonObject[] {
  return readObjectList(value)
    .map((item) => compactObject({
      companyName: readString(item.companyName),
      jobTitle: readString(item.jobTitle),
      startDate: readString(item.startDate),
      endDate: readString(item.endDate),
      isCurrentRole: readBool(item.isCurrentRole),
      highlights: readStringList(item.highlights),
    }))
    .filter((item) => Object.keys(item).length > 0);
}

function normalizeSkillList(value: unknown): JsonObject[] {
  return readObjectList(value)
    .map((item) => compactObject({
      name: readString(item.name),
      level: readString(item.level),
    }))
    .filter((item) => Object.keys(item).length > 0);
}

function normalizeProjectList(value: unknown): JsonObject[] {
  return readObjectList(value)
    .map((item) => compactObject({
      title: readString(item.title),
      role: readString(item.role),
      description: readString(item.description),
      technologies: readStringList(item.technologies),
    }))
    .filter((item) => Object.keys(item).length > 0);
}

function normalizeTrainingList(value: unknown): JsonObject[] {
  return readObjectList(value)
    .map((item) => compactObject({
      title: readString(item.title),
      organization: readString(item.organization),
      completionYear: readString(item.completionYear),
      details: readString(item.details),
    }))
    .filter((item) => Object.keys(item).length > 0);
}

function normalizeLanguageList(value: unknown): JsonObject[] {
  return readObjectList(value)
    .map((item) => compactObject({
      name: readString(item.name),
      proficiency: readString(item.proficiency),
    }))
    .filter((item) => Object.keys(item).length > 0);
}

function compactObject(input: JsonObject): JsonObject {
  const output: JsonObject = {};

  for (const [key, value] of Object.entries(input)) {
    if (typeof value === "string" && value.trim().length === 0) {
      continue;
    }

    if (Array.isArray(value) && value.length === 0) {
      continue;
    }

    output[key] = value;
  }

  return output;
}

function readObjectList(value: unknown): JsonObject[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => asObject(item))
    .filter((item): item is JsonObject => item !== null);
}

function readStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => readString(item))
    .filter((item) => item.length > 0);
}

function readString(value: unknown): string {
  if (typeof value === "string") {
    return value.trim();
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  return "";
}

function readBool(value: unknown): boolean {
  return value === true;
}

function readPositiveInt(value: unknown, fallback: number): number {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.floor(value);
  }

  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (Number.isFinite(parsed) && parsed > 0) {
      return parsed;
    }
  }

  return fallback;
}

function asObject(value: unknown): JsonObject | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }

  return value as JsonObject;
}
