const Groq = require("groq-sdk");

class GrokService {
  constructor() {
    this.apiKey = process.env.GROQ_API_KEY;
    if (!this.apiKey) {
      console.warn("GROQ_API_KEY not found. AI features will be disabled.");
    }

    this.groq = this.apiKey ? new Groq({ apiKey: this.apiKey }) : null;

    this.currentModel = "llama-3.3-70b-versatile";
    this.modelCache = new Map();
    this.lastModelCheck = null;
    this.modelCheckInterval = 24 * 60 * 60 * 1000; // 24 hours

    // Resolved once per extraction run — avoids mid-run model switches
    this._activeModel = null;

    console.log("GrokService initialized:", this.isConfigured() ? "Ready" : "Not configured");
    console.log("Current AI model:", this.currentModel);
  }

  // ─── Configuration ───────────────────────────────────────────────────────────

  isConfigured() {
    return !!this.apiKey && !!this.groq;
  }

  getCurrentModel() {
    return this.currentModel;
  }

  setCurrentModel(modelName) {
    console.log(`Updating model: ${this.currentModel} → ${modelName}`);
    this.currentModel = modelName;
  }

  // ─── Model Management ────────────────────────────────────────────────────────

  shouldCheckModel() {
    if (!this.lastModelCheck) return true;
    return Date.now() - this.lastModelCheck > this.modelCheckInterval;
  }

  async testModelAvailability(modelName) {
    const cached = this.modelCache.get(modelName);
    if (cached && Date.now() - cached.timestamp < this.modelCheckInterval) {
      return cached.available;
    }

    try {
      await this.groq.chat.completions.create({
        messages: [{ role: "user", content: "ping" }],
        model: modelName,
        max_tokens: 1,
        temperature: 0,
      });
      this.modelCache.set(modelName, { available: true, timestamp: Date.now() });
      return true;
    } catch (error) {
      this.modelCache.set(modelName, {
        available: false,
        timestamp: Date.now(),
        error: error.message,
      });
      if (error.message.includes("decommissioned") || error.message.includes("not found")) {
        console.warn(`Model ${modelName} is no longer available: ${error.message}`);
      }
      return false;
    }
  }

  async autoUpdateModel() {
    if (!this.shouldCheckModel()) return this.currentModel;

    console.log("Checking model availability...");
    this.lastModelCheck = Date.now();

    const currentWorks = await this.testModelAvailability(this.currentModel);
    if (currentWorks) return this.currentModel;

    console.log(`${this.currentModel} unavailable — searching for fallback...`);

    const candidates = [
      "llama-3.3-70b-versatile",
      "llama3-70b-8192",
      "llama3-8b-8192",
      "mixtral-8x7b-32768",
      "gemma-7b-it",
    ];

    for (const model of candidates) {
      if (model === this.currentModel) continue;
      if (await this.testModelAvailability(model)) {
        this.setCurrentModel(model);
        console.log(`✅ Auto-updated to: ${model}`);
        return model;
      }
    }

    console.error("No available fallback models found.");
    return this.currentModel;
  }

  /** Resolve model once and cache for the duration of an extraction run */
  async resolveModel() {
    if (!this._activeModel) {
      this._activeModel = await this.autoUpdateModel();
    }
    return this._activeModel;
  }

  async forceModelUpdate() {
    this.lastModelCheck = 0;
    this._activeModel = null;
    return this.autoUpdateModel();
  }

  getModelStatus() {
    return {
      currentModel: this.currentModel,
      lastCheck: this.lastModelCheck ? new Date(this.lastModelCheck).toISOString() : null,
      nextCheck: this.lastModelCheck
        ? new Date(this.lastModelCheck + this.modelCheckInterval).toISOString()
        : null,
      cachedModels: Array.from(this.modelCache.entries()).map(([model, data]) => ({
        model,
        available: data.available,
        lastChecked: new Date(data.timestamp).toISOString(),
        error: data.error,
      })),
    };
  }

  // ─── Question Extraction ─────────────────────────────────────────────────────

  /**
   * Extract and organize questions from a document using Groq AI.
   * @param {string|Object} documentInput - Text string, buffer object, or file-path object
   * @param {string} examType - "quiz" | "pastpaper" | "final"
   * @returns {Promise<Array>} Validated question objects
   */
  async extractQuestionsFromDocument(documentInput, examType) {
    if (!this.isConfigured()) {
      throw new Error("GrokService not configured — set GROQ_API_KEY.");
    }

    // Reset per-run model cache so we use one model throughout
    this._activeModel = null;

    let documentText;
    let fileName = "document";

    if (typeof documentInput === "string") {
      documentText = documentInput;
      fileName = "text document";
    } else if (documentInput.buffer) {
      documentText = await this.extractTextFromBuffer(
        documentInput.buffer,
        documentInput.mimetype
      );
      fileName = documentInput.originalName || "uploaded document";
    } else if (documentInput.path) {
      const fs = require("fs");
      if (!fs.existsSync(documentInput.path)) {
        throw new Error(`File not found: ${documentInput.path}`);
      }
      const fileBuffer = fs.readFileSync(documentInput.path);
      documentText = await this.extractTextFromBuffer(fileBuffer, documentInput.mimetype);
      fileName = documentInput.originalName || "document file";
    } else {
      throw new Error("Invalid documentInput — must be string, buffer object, or file object.");
    }

    if (!documentText || documentText.trim().length === 0) {
      throw new Error("Could not extract any text from the provided document.");
    }

    console.log(`Document preview: ${documentText.substring(0, 200)}...`);

    // 6 000 chars/chunk keeps prompt + response safely within token limits. 
    // 500 chars overlap prevents missing questions cut across chunks.
    const CHUNK_SIZE = 6000;
    const OVERLAP = 500;
    const chunks = this.splitTextIntoChunks(documentText, CHUNK_SIZE, OVERLAP);
    console.log(`Processing ${chunks.length} chunk(s) with model: ${await this.resolveModel()}`);

    const allQuestions = [];

    for (let i = 0; i < chunks.length; i++) {
      console.log(`→ Chunk ${i + 1}/${chunks.length}`);
      try {
        const questions = await this.processChunkWithRetry(
          chunks[i],
          examType,
          fileName,
          i + 1,
          chunks.length
        );
        console.log(`  ✓ ${questions.length} question(s) extracted`);
        allQuestions.push(...questions);
      } catch (err) {
        console.error(`  ✗ Chunk ${i + 1} failed: ${err.message}`);
      }
    }

    const unique = this.deduplicateQuestions(allQuestions);
    const valid = this.validateAndNormalizeQuestions(unique);
    console.log(`Extraction complete: ${valid.length} valid question(s) from ${allQuestions.length} raw`);
    return valid;
  }

  /**
   * Process a chunk with up to 2 retries on parse failure.
   */
  async processChunkWithRetry(chunk, examType, fileName, chunkNum, totalChunks, maxRetries = 2) {
    let lastError;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.processChunk(chunk, examType, fileName, chunkNum, totalChunks);
      } catch (err) {
        lastError = err;
        console.warn(`  Attempt ${attempt}/${maxRetries} failed: ${err.message}`);
        if (attempt < maxRetries) await this.sleep(500 * attempt);
      }
    }
    throw lastError;
  }

  /**
   * Send one chunk to the Groq API and return parsed questions.
   */
  async processChunk(chunk, examType, fileName, chunkNum, totalChunks) {
    // Deliberately compact prompt — less ambiguity, fewer hallucinations
    const prompt = `You are extracting exam questions from an educational document.

EXAM TYPE: ${examType}
FILE: ${fileName}
CHUNK: ${chunkNum} of ${totalChunks}

RULES:
1. Extract ONLY questions that literally appear in the text below.
2. Do NOT invent, paraphrase, or summarize questions. If it's not in the text, skip it.
3. VERBATIM: Copy question text exactly as it appears, including punctuation.
4. Some questions may have sub-questions labeled a, b, c, etc. Include them as "subQuestions" with their own type, options, and correctAnswer.
5. For MCQ: "correctAnswer" must be a zero-based integer index into "options".
6. For true_false: set options to ["True","False"] and correctAnswer to 0 or 1.
7. For fill_blank and open: omit "options"; set correctAnswer to the answer string.
8. If no questions are found, return {"questions":[]}.
9. Respond with ONLY valid JSON — no markdown fences, no explanation.
10. VERIFY: Double-check each extracted question against the text to ensure it matches exactly. Skip it if you are unsure.

QUESTION SCHEMA:
{
  "questions": [
    {
      "question": "<exact question text>",
      "type": "mcq | true_false | fill_blank | open",
      "options": ["A","B","C","D"],   // MCQ and true_false only
      "correctAnswer": 0,             // integer index for MCQ/true_false; string for others
      "points": 1,
      "subQuestions": [               // Optional
        {
          "label": "a",               // Optional (a, b, c, etc.)
          "question": "<sub-question text>",
          "type": "mcq | true_false | fill_blank | open",
          "options": ["A","B","C","D"],
          "correctAnswer": 0,
          "points": 1
        }
      ]
    }
  ]
}

DOCUMENT TEXT:
---
${chunk}
---`;

    const model = await this.resolveModel();
    const completion = await this.groq.chat.completions.create({
      model,
      messages: [{ role: "user", content: prompt }],
      temperature: 0.1,   // near-deterministic for extraction
      max_tokens: 4096,
    });

    const raw = completion.choices[0]?.message?.content ?? "";
    if (!raw.trim()) throw new Error("Empty response from Groq API");

    return this.parseQuestionsFromResponse(raw);
  }

  /**
   * Robustly parse a JSON response that may be wrapped in markdown fences
   * or contain leading/trailing prose.
   */
  parseQuestionsFromResponse(raw) {
    // 1. Try direct parse
    try {
      const parsed = JSON.parse(raw);
      return parsed.questions ?? [];
    } catch (_) { /* fall through */ }

    // 2. Strip markdown code fences and retry
    const stripped = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/, "").trim();
    try {
      const parsed = JSON.parse(stripped);
      return parsed.questions ?? [];
    } catch (_) { /* fall through */ }

    // 3. Extract the first {...} block
    const match = stripped.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        const parsed = JSON.parse(match[0]);
        return parsed.questions ?? [];
      } catch (_) { /* fall through */ }
    }

    // 4. Last resort — extract individual question objects from the text
    const questionBlocks = [];
    const objRegex = /\{[^{}]*"question"\s*:[^{}]*\}/g;
    let m;
    while ((m = objRegex.exec(stripped)) !== null) {
      try {
        questionBlocks.push(JSON.parse(m[0]));
      } catch (_) { /* skip malformed block */ }
    }

    if (questionBlocks.length > 0) {
      console.warn(`Partial parse: recovered ${questionBlocks.length} question object(s)`);
      return questionBlocks;
    }

    throw new Error("Could not parse any questions from Groq response");
  }

  // ─── Validation & Normalisation ──────────────────────────────────────────────

  /**
   * Validate structure and normalise correctAnswer so downstream code
   * always receives consistent types.
   */
  validateAndNormalizeQuestions(questions) {
    const validTypes = new Set(["mcq", "true_false", "fill_blank", "open"]);

    const normalize = (q) => {
      if (!q.question || typeof q.question !== "string" || !q.question.trim()) {
        return null;
      }

      const type = (q.type || "").toLowerCase();
      if (!validTypes.has(type)) {
        return null;
      }

      let normalized = { ...q, type, points: q.points ?? 1 };

      if (type === "mcq") {
        normalized.options = Array.isArray(q.options) && q.options.length >= 2
          ? q.options
          : ["A", "B", "C", "D"];
        
        let idx = parseInt(q.correctAnswer, 10);
        if (isNaN(idx)) {
          idx = normalized.options.findIndex(
            (o) => o.toLowerCase().trim() === String(q.correctAnswer).toLowerCase().trim()
          );
        }
        normalized.correctAnswer = (idx >= 0 && idx < normalized.options.length) ? idx : 0;
      } else if (type === "true_false") {
        normalized.options = Array.isArray(q.options) && q.options.length >= 2
          ? q.options
          : ["True", "False"];

        let idx = parseInt(q.correctAnswer, 10);
        if (isNaN(idx)) {
          const ans = String(q.correctAnswer).toLowerCase().trim();
          idx = (ans === "true" || ans === "0") ? 0 : 1;
        }
        normalized.correctAnswer = (idx === 0 || idx === 1) ? idx : 0;
      } else {
        normalized.correctAnswer = String(q.correctAnswer ?? "");
      }

      // Recursively normalize subQuestions if present
      if (Array.isArray(q.subQuestions) && q.subQuestions.length > 0) {
        normalized.subQuestions = q.subQuestions.map(normalize).filter(Boolean);
      }

      return normalized;
    };

    return questions.map(normalize).filter(Boolean);
  }

  // ─── Deduplication ───────────────────────────────────────────────────────────

  deduplicateQuestions(questions) {
    const seen = new Set();
    const result = [];

    const hashQuestion = (q) => {
      const text = (q.question || "").toLowerCase().trim();
      let key = text.substring(0, 200) +
                "|" + (Array.isArray(q.options) ? q.options[0]?.toLowerCase().trim() ?? "" : "");
      
      if (Array.isArray(q.subQuestions) && q.subQuestions.length > 0) {
        key += "|" + q.subQuestions.map(sq => hashQuestion(sq)).join("|");
      }
      return key;
    };

    for (const q of questions) {
      const key = hashQuestion(q);
      if (seen.has(key)) {
        console.log(`Duplicate skipped: ${(q.question || "").substring(0, 50)}…`);
        continue;
      }
      seen.add(key);
      result.push(q);
    }

    console.log(`Deduplication: ${questions.length} → ${result.length}`);
    return result;
  }

  // ─── Notes & Utilities ───────────────────────────────────────────────────────

  async organizeNotes(file, mimeType) {
    if (!this.isConfigured()) {
      throw new Error("GrokService not configured — set GROQ_API_KEY.");
    }

    const documentText = await this.extractTextFromBuffer(file.buffer, mimeType);
    if (!documentText?.trim()) throw new Error("No text content found in document");

    // Hard-limit to avoid token overflow — no inline comment leaking into prompt
    const contentPreview = documentText.substring(0, 8000);

    const prompt = `You are an expert educational content organizer. Organize the lesson notes below into a clear, structured format for student study.

Instructions:
- Identify main topics and subtopics with clear headings
- Use bullet points for key concepts
- Include examples where present in the source
- Keep language clear and accessible

NOTES:
${contentPreview}`;

    const completion = await this.groq.chat.completions.create({
      model: await this.resolveModel(),
      messages: [{ role: "user", content: prompt }],
      temperature: 0.4,
      max_tokens: 4096,
    });

    const result = completion.choices[0]?.message?.content;
    if (!result) throw new Error("Empty response from Groq AI");
    return result;
  }

  async generateExamTitle(documentText) {
    if (!this.isConfigured()) {
      return this.generateFallbackExamTitle();
    }

    try {
      const preview = documentText.substring(0, 1500);
      const prompt = `Generate a concise, professional exam title (maximum 50 characters) based on this content. Return ONLY the title — no quotes, no explanation.\n\nCONTENT:\n${preview}`;

      const completion = await this.groq.chat.completions.create({
        model: await this.resolveModel(),
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
        max_tokens: 60,
      });

      const title = (completion.choices[0]?.message?.content || "")
        .replace(/["'\n\r]/g, "")
        .trim()
        .substring(0, 50);

      return title || this.generateFallbackExamTitle();
    } catch (error) {
      console.error("generateExamTitle error:", error.message);
      return this.generateFallbackExamTitle();
    }
  }

  async generateChatResponse(messages, _context) {
    if (!this.isConfigured()) {
      return "AI is not currently available. Please contact support.";
    }

    try {
      const completion = await this.groq.chat.completions.create({
        model: await this.resolveModel(),
        messages,
        temperature: 0.7,
        max_tokens: 2048,
      });
      return completion.choices[0]?.message?.content ?? "I'm not sure how to respond to that.";
    } catch (error) {
      console.error("generateChatResponse error:", error.message);
      return "I encountered an error. Please try again.";
    }
  }

  // ─── Grading & Evaluation ────────────────────────────────────────────────────

  /**
   * Grade a batch of exam answers using Groq AI.
   * Handles MCQ, true_false, fill_blank, and open-ended questions.
   * @param {Array} questions - Original question objects from database
   * @param {Array} userAnswers - Student's submitted answers
   * @returns {Promise<Array>} Graded answers with earnedPoints and feedback
   */
  async gradeAnswers(questions, userAnswers) {
    if (!this.isConfigured()) {
      throw new Error("GrokService not configured for grading.");
    }

    // Format data for the prompt to minimize tokens
    const gradingData = userAnswers.map((ua) => {
      const q = questions.find((quest) => quest._id.toString() === ua.questionId);
      if (!q) return null;

      return {
        id: ua.questionId,
        type: q.type,
        question: q.question,
        options: q.options,
        correctAnswer: q.correctAnswer,
        studentAnswer: q.type === "mcq" || q.type === "true_false" 
          ? (q.options[ua.selectedOption] || ua.selectedOption)
          : (ua.answerText || ua.selectedOption),
        points: q.points || 1,
      };
    }).filter(Boolean);

    if (gradingData.length === 0) return [];

    const prompt = `You are an expert examiner grading a student's exam.
Grade the following answers objectively based on the correct answer provided.

RULES:
1. For MCQ and true_false: The answer must match the correct answer exactly (index or text).
2. For fill_blank: Allow minor spelling errors or case differences if the meaning is identical.
3. For open: Grade based on conceptual correctness and completeness. Give partial points if partially correct.
4. Provide a brief "feedback" string for each answer (max 15 words).
5. Respond ONLY with a JSON array of objects.

SCHEMA:
[
  {
    "id": "question_id",
    "earnedPoints": number,
    "feedback": "string",
    "isCorrect": boolean
  }
]

DATA TO GRADE:
${JSON.stringify(gradingData, null, 2)}`;

    try {
      const model = await this.resolveModel();
      const completion = await this.groq.chat.completions.create({
        model,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1,
        max_tokens: 4096,
      });

      const raw = completion.choices[0]?.message?.content ?? "";
      const gradedResults = this.parseGradingResponse(raw);

      // Map results back to the original userAnswers format
      return userAnswers.map((ua) => {
        const graded = gradedResults.find((g) => g.id === ua.questionId);
        const q = questions.find((quest) => quest._id.toString() === ua.questionId);
        
        if (graded) {
          return {
            ...ua,
            earnedPoints: graded.earnedPoints,
            feedback: graded.feedback,
            isCorrect: graded.isCorrect,
          };
        }

        // Fallback grading if AI missed a question
        return this.fallbackGrade(q, ua);
      });
    } catch (error) {
      console.error("AI Grading failed, using fallback:", error.message);
      return userAnswers.map((ua) => {
        const q = questions.find((quest) => quest._id.toString() === ua.questionId);
        return this.fallbackGrade(q, ua);
      });
    }
  }

  /**
   * Parse the JSON response from the grading prompt.
   */
  parseGradingResponse(raw) {
    try {
      // Clean markdown fences if present
      const cleaned = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/, "").trim();
      const match = cleaned.match(/\[[\s\S]*\]/);
      if (match) {
        return JSON.parse(match[0]);
      }
      return JSON.parse(cleaned);
    } catch (e) {
      console.error("Failed to parse grading response:", e.message);
      return [];
    }
  }

  /**
   * Deterministic fallback grading for simple question types.
   */
  fallbackGrade(question, userAnswer) {
    if (!question) return { ...userAnswer, earnedPoints: 0, isCorrect: false };

    let isCorrect = false;
    if (question.type === "mcq" || question.type === "true_false") {
      isCorrect = question.correctAnswer === userAnswer.selectedOption;
    } else if (question.type === "fill_blank") {
      isCorrect = String(question.correctAnswer).toLowerCase().trim() === 
                  String(userAnswer.answerText || "").toLowerCase().trim();
    }

    return {
      ...userAnswer,
      earnedPoints: isCorrect ? (question.points || 1) : 0,
      isCorrect,
      feedback: isCorrect ? "Correct." : "Incorrect.",
    };
  }

  // ─── Internal Helpers ────────────────────────────────────────────────────────

  async extractTextFromBuffer(buffer, mimeType) {
    if (mimeType && mimeType.includes("text")) {
      return buffer.toString("utf8");
    }
    try {
      const DocumentProcessingService = require("./document_processing_service");
      const text = await DocumentProcessingService.extractTextFromDocument(buffer, mimeType);
      if (!text || text.trim().length < 5) {
        console.warn(`Extracted text too short for ${mimeType}`);
        return "";
      }
      return text;
    } catch (error) {
      console.warn("extractTextFromBuffer failed:", error.message);
      return "";
    }
  }

  /**
   * Split text into chunks with optional overlap to prevent missing questions
   * that fall exactly on a chunk boundary.
   */
  splitTextIntoChunks(text, chunkSize, overlap = 0) {
    if (!text) return [];
    if (text.length <= chunkSize) return [text];

    const chunks = [];
    let start = 0;

    while (start < text.length) {
      let end = Math.min(start + chunkSize, text.length);

      // If we're not at the very end, try to find a natural break (double newline or single newline)
      if (end < text.length) {
        const lastDoubleNewline = text.lastIndexOf("\n\n", end);
        if (lastDoubleNewline > start + chunkSize * 0.7) {
          end = lastDoubleNewline + 2; // Split at paragraph
        } else {
          const lastNewline = text.lastIndexOf("\n", end);
          if (lastNewline > start + chunkSize * 0.7) {
            end = lastNewline + 1; // Split at line break
          }
        }
      }

      const chunk = text.substring(start, end).trim();
      if (chunk) chunks.push(chunk);

      // Move start back by overlap for the next chunk
      start = end - overlap;

      // Safety: ensure we always progress at least 10% of chunkSize
      const minStep = Math.max(1, Math.floor(chunkSize * 0.1));
      if (start <= (end - chunkSize + minStep)) {
        start = end;
      }
    }

    return chunks;
  }

  generateFallbackExamTitle() {
    const topics = ["Mathematics", "Science", "History", "Literature", "Programming", "Business"];
    const types = ["Quiz", "Test", "Assessment", "Review", "Practice"];
    return `${topics[Math.floor(Math.random() * topics.length)]} ${types[Math.floor(Math.random() * types.length)]}`;
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

module.exports = new GrokService();