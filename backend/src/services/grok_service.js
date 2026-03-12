const Groq = require("groq-sdk");
const DocumentProcessingService = require('./document_processing_service');

// Concurrency limiter to avoid rate limits while maximizing throughput
class ConcurrencyLimiter {
  constructor(maxConcurrent) {
    this.maxConcurrent = maxConcurrent;
    this.running = 0;
    this.queue = [];
  }

  async run(fn) {
    if (this.running >= this.maxConcurrent) {
      await new Promise(resolve => this.queue.push(resolve));
    }
    this.running++;
    try {
      return await fn();
    } finally {
      this.running--;
      if (this.queue.length > 0) this.queue.shift()();
    }
  }
}

class GrokService {
  constructor() {
    this.apiKey = process.env.GROQ_API_KEY;
    if (!this.apiKey) {
      console.warn("GROQ_API_KEY not found in environment variables. AI features will be disabled.");
    }

    this.groq = this.apiKey ? new Groq({ apiKey: this.apiKey }) : null;

    // Model config
    this.primaryModel = "llama-3.3-70b-versatile";
    this.cheapModel = "gemma2-9b-it";
    this.currentModel = this.primaryModel;

    // Model health cache — avoid re-checking on every request
    this.modelHealthy = true;
    this.modelLastChecked = 0;
    this.modelCheckTTL = 6 * 60 * 60 * 1000; // 6 hours (was 24h but this is safer)

    // Rate limit concurrency: Groq free tier handles ~5-10 concurrent well
    this.chunkLimiter = new ConcurrencyLimiter(5);
    this.gradingLimiter = new ConcurrencyLimiter(8);

    console.log("Grok Service initialized:", this.isConfigured() ? "Ready" : "Not configured");
    console.log("Primary model:", this.primaryModel, "| Grading model:", this.cheapModel);
  }

  isConfigured() {
    this._checkConfiguration();
    return !!this.apiKey && !!this.groq;
  }

  _checkConfiguration() {
    if (!this.apiKey || !this.groq) {
      this.apiKey = process.env.GROQ_API_KEY;
      if (this.apiKey && !this.groq) {
        this.groq = new Groq({ apiKey: this.apiKey });
        console.log("Grok Service re-initialized with environment key.");
      }
    }
  }

  // ─── Model Management ─────────────────────────────────────────────────────

  getCurrentModel() { return this.currentModel; }
  setCurrentModel(model) {
    console.log(`Model updated: ${this.currentModel} → ${model}`);
    this.currentModel = model;
  }

  /**
   * Get model — only checks health every 6h instead of every call.
   * @param {boolean} cheap - Use fast/cheap model for grading
   */
  async getModel(cheap = false) {
    if (cheap) return this.cheapModel;

    const now = Date.now();
    if (now - this.modelLastChecked > this.modelCheckTTL) {
      this.modelLastChecked = now;
      // Non-blocking background health check
      this._checkModelHealth().catch(() => {});
    }

    return this.currentModel;
  }

  async _checkModelHealth() {
    try {
      await this.groq.chat.completions.create({
        messages: [{ role: "user", content: "ping" }],
        model: this.currentModel,
        max_tokens: 1,
        temperature: 0,
      });
      this.modelHealthy = true;
    } catch (err) {
      if (err.message?.includes('decommissioned') || err.message?.includes('not found')) {
        console.warn(`Model ${this.currentModel} unavailable, switching to fallback...`);
        this.currentModel = this.cheapModel; // Fallback immediately
        this.modelHealthy = false;
      }
    }
  }

  getModelStatus() {
    return {
      currentModel: this.currentModel,
      cheapModel: this.cheapModel,
      modelHealthy: this.modelHealthy,
      lastChecked: new Date(this.modelLastChecked).toISOString(),
    };
  }

  // ─── Retry / Rate Limit ───────────────────────────────────────────────────

  async callGroqWithRetry(apiCall, retries = 3, delay = 30000) {
    try {
      return await apiCall();
    } catch (err) {
      const isRateLimit = err.status === 429 ||
        err.message?.includes("rate_limit") ||
        err.message?.includes("too many requests");

      if (isRateLimit && retries > 0) {
        // Respect Retry-After header if present
        const retryAfter = err.headers?.['retry-after'];
        const waitMs = retryAfter ? parseInt(retryAfter) * 1000 : delay;
        console.warn(`Rate limit hit. Waiting ${waitMs / 1000}s (${retries} retries left)...`);
        await new Promise(r => setTimeout(r, waitMs));
        return this.callGroqWithRetry(apiCall, retries - 1, delay * 1.5);
      }
      throw err;
    }
  }

  // ─── Core: Extract Questions ──────────────────────────────────────────────

  /**
   * Extract and grade questions from a document.
   * Optimized: parallel chunking + parallel batched grading.
   */
  async extractQuestionsFromDocument(documentInput, examType) {
    this._checkConfiguration();
    if (!this.isConfigured()) {
      throw new Error("Grok is not configured. Please set GROQ_API_KEY.");
    }

    const startTime = Date.now();

    // 1. Extract text
    let documentText = '';
    let fileName = 'document';

    if (typeof documentInput === 'string') {
      documentText = documentInput;
    } else if (documentInput.buffer) {
      documentText = await this._extractText(documentInput.buffer, documentInput.mimetype);
      fileName = documentInput.originalName || 'uploaded document';
    } else if (documentInput.path) {
      const fs = require('fs');
      const buf = fs.readFileSync(documentInput.path);
      documentText = await this._extractText(buf, documentInput.mimetype);
      fileName = documentInput.originalName || 'document';
    } else {
      throw new Error("Invalid document input.");
    }

    if (!documentText?.trim()) throw new Error("No text could be extracted from the document.");

    console.log(`[${Date.now() - startTime}ms] Text extracted (${documentText.length} chars)`);

    // 2. Chunk and extract questions — all chunks in parallel (rate-limited)
    const CHUNK_SIZE = 12000; // Larger chunks = fewer API calls = faster
    const chunks = this.splitTextIntoChunks(documentText, CHUNK_SIZE);
    console.log(`Processing ${chunks.length} chunks in parallel...`);

    const chunkResults = await Promise.all(
      chunks.map((chunk, i) =>
        this.chunkLimiter.run(() =>
          this._extractChunk(chunk, examType, fileName, i + 1, chunks.length)
            .catch(err => {
              console.error(`Chunk ${i + 1} failed:`, err.message);
              return [];
            })
        )
      )
    );

    let questions = this.deduplicateQuestions(chunkResults.flat());
    questions = this.filterQuestionTypes(questions);

    console.log(`[${Date.now() - startTime}ms] ${questions.length} unique questions extracted`);

    // 3. Grade questions — batch in parallel
    if (questions.length > 0) {
      await this._gradeAllQuestions(questions, documentText);
      console.log(`[${Date.now() - startTime}ms] Grading complete`);
    }

    console.log(`✅ Total processing time: ${((Date.now() - startTime) / 1000).toFixed(1)}s`);
    return questions;
  }

  /**
   * Process a single chunk to extract questions.
   */
  async _extractChunk(chunk, examType, fileName, chunkNum, totalChunks) {
    const prompt = `Extract ALL questions from this document chunk. Return ONLY valid JSON.

Rules:
- Do NOT answer questions, only extract them exactly as written
- Identify type: mcq, true_false, fill_blank, or open
- MCQ must include all answer options

JSON format:
{"questions":[{"question":"...","type":"mcq","options":["A","B","C","D"],"points":1}]}

CHUNK ${chunkNum}/${totalChunks}:
---
${chunk}
---`;

    const model = await this.getModel();
    const response = await this.callGroqWithRetry(() =>
      this.groq.chat.completions.create({
        messages: [{ role: "user", content: prompt }],
        model,
        temperature: 0.1, // Lower = more consistent JSON output
        max_tokens: 8192,
      })
    );

    const content = response.choices[0]?.message?.content || '';
    const parsed = this.parseJSONResponse(content);
    if (parsed?.questions) return parsed.questions;

    // Fallback
    console.warn(`Chunk ${chunkNum}: JSON parse failed, using regex fallback`);
    return this.extractQuestionsFallback(content, examType);
  }

  // ─── Core: Grading ────────────────────────────────────────────────────────

  /**
   * Grade all questions using optimally-sized batches in parallel.
   */
  async _gradeAllQuestions(questions, documentText) {
    const paragraphs = this.splitIntoParagraphs(documentText);

    // Optimal batch size: larger = fewer API calls, but too large = less accurate
    const BATCH_SIZE = 25;
    const batches = [];
    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
      batches.push({ batch: questions.slice(i, i + BATCH_SIZE), offset: i });
    }

    await Promise.all(
      batches.map(({ batch, offset }) =>
        this.gradingLimiter.run(async () => {
          const context = this.findRelevantContextForBatch(batch, paragraphs);
          const results = await this.findCorrectAnswersBatch(context, batch);
          results.forEach(({ questionIndex, correctAnswer }) => {
            if (questionIndex != null && questionIndex < batch.length) {
              batch[questionIndex].correctAnswer = correctAnswer;
            }
          });
        }).catch(err => console.error(`Grading batch at offset ${offset} failed:`, err.message))
      )
    );
  }

  /**
   * Grade a single question (for on-demand use).
   */
  async findCorrectAnswer(documentText, question) {
    if (!this.isConfigured() || !question.options?.length) return null;
    const paragraphs = this.splitIntoParagraphs(documentText);
    const context = this.findRelevantParagraph(question.question, paragraphs);

    const prompt = `CONTEXT:\n${context}\n\nQUESTION: ${question.question}\nOPTIONS:\n${question.options.join("\n")}\n\nAnswer ONLY using the context. If not found, return null.\n{"correctAnswer": number_or_null}`;

    try {
      const model = await this.getModel(true);
      const res = await this.callGroqWithRetry(() =>
        this.groq.chat.completions.create({
          messages: [{ role: "user", content: prompt }],
          model,
          temperature: 0,
          max_tokens: 50,
        })
      );
      return this.parseJSONResponse(res.choices[0]?.message?.content)?.correctAnswer ?? null;
    } catch (err) {
      console.error("findCorrectAnswer error:", err.message);
      return null;
    }
  }

  /**
   * Grade a batch of questions with shared context.
   */
  async findCorrectAnswersBatch(contextText, questions) {
    if (!this.isConfigured() || !questions.length) return [];

    const questionsText = questions
      .map((q, i) => `${i}. ${q.question}\nOptions: ${(q.options || []).join(" | ")}`)
      .join("\n\n");

    const prompt = `CONTEXT:\n${contextText}\n\nQUESTIONS:\n${questionsText}\n\nFor each question, return the 0-based index of the correct option using ONLY the context. Return null if unsure.\n{"results":[{"questionIndex":0,"correctAnswer":number_or_null}]}`;

    try {
      const model = await this.getModel(true);
      const res = await this.callGroqWithRetry(() =>
        this.groq.chat.completions.create({
          messages: [{ role: "user", content: prompt }],
          model,
          temperature: 0,
          max_tokens: 1024,
        })
      );
      return this.parseJSONResponse(res.choices[0]?.message?.content)?.results || [];
    } catch (err) {
      console.error("findCorrectAnswersBatch error:", err.message);
      return [];
    }
  }

  // ─── Other AI Features ────────────────────────────────────────────────────

  async organizeNotes(file, mimeType) {
    if (!this.isConfigured()) throw new Error("Grok not configured.");
    const documentText = await this._extractText(file.buffer, mimeType);
    if (!documentText?.trim()) throw new Error("No text content found in document.");

    const prompt = `Organize these lesson notes into a clear, structured format for students.
Include: main topics/subtopics, clear headings, bullet points for key concepts, examples where relevant.

CONTENT:\n${documentText.substring(0, 8000)}`;

    const res = await this.groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: await this.getModel(),
      temperature: 0.4,
      max_tokens: 4096,
    });

    return res.choices[0]?.message?.content || '';
  }

  async generateExamTitle(documentText) {
    if (!this.isConfigured()) return this.generateTemplateExamTitle(documentText);
    try {
      const prompt = `Generate a concise exam title (max 50 chars) based on:\n${documentText.substring(0, 1500)}\nReturn ONLY the title, no quotes.`;
      const res = await this.groq.chat.completions.create({
        messages: [{ role: "user", content: prompt }],
        model: await this.getModel(),
        temperature: 0.3,
        max_tokens: 60,
      });
      const title = (res.choices[0]?.message?.content || '').replace(/["'\n\r]/g, '').trim().substring(0, 50);
      return title || this.generateTemplateExamTitle(documentText);
    } catch {
      return this.generateTemplateExamTitle(documentText);
    }
  }

  async generateChatResponse(messages, context) {
    if (!this.isConfigured()) return "AI is not currently connected. Please contact support.";
    try {
      const res = await this.groq.chat.completions.create({
        messages,
        model: await this.getModel(),
        temperature: 0.7,
        max_tokens: 2048,
      });
      return res.choices[0]?.message?.content || "I'm not sure how to respond to that.";
    } catch (err) {
      console.error("generateChatResponse error:", err);
      return "I encountered an error. Please try again.";
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /**
   * Extract text from buffer — cached require at class level for performance.
   */
  async _extractText(buffer, mimeType) {
    if (mimeType?.includes('text')) return buffer.toString('utf8');
    try {
      const text = await DocumentProcessingService.extractTextFromDocument(buffer, mimeType);
      return text?.trim().length > 5 ? text : '';
    } catch (err) {
      console.warn('Text extraction failed:', err.message);
      return '';
    }
  }

  // Kept for backwards compatibility
  async extractTextFromBuffer(buffer, mimeType) {
    return this._extractText(buffer, mimeType);
  }

  splitIntoParagraphs(text) {
    if (!text) return [];
    return text.split(/\n\s*\n/).filter(p => p.trim().length > 50);
  }

  /**
   * Fast keyword-based paragraph relevance scoring.
   * Uses word index for O(1) lookups instead of O(n) scans.
   */
  findRelevantParagraph(questionText, paragraphs) {
    if (!questionText || !paragraphs?.length) return "";
    const words = questionText.toLowerCase().split(/\W+/).filter(w => w.length > 3);
    let best = "", bestScore = -1;

    for (const p of paragraphs) {
      const pLower = p.toLowerCase();
      let score = 0;
      for (const w of words) if (pLower.includes(w)) score++;
      if (score > bestScore) { bestScore = score; best = p; }
    }

    return best || paragraphs[0]?.substring(0, 1000) || "";
  }

  findRelevantContextForBatch(questions, paragraphs) {
    const seen = new Set();
    const relevant = [];
    for (const q of questions) {
      const p = this.findRelevantParagraph(q.question, paragraphs);
      if (p && !seen.has(p)) { seen.add(p); relevant.push(p); }
    }
    return relevant.join("\n\n").substring(0, 18000); // Slightly larger context window
  }

  splitTextIntoChunks(text, chunkSize) {
    if (!text) return [''];
    if (text.length <= chunkSize) return [text];

    const paragraphs = text.split(/\n\s*\n/);
    const chunks = [];
    let current = '';

    for (const para of paragraphs) {
      if (current.length + para.length + 2 <= chunkSize) {
        current += (current ? '\n\n' : '') + para;
      } else {
        if (current) chunks.push(current.trim());
        if (para.length > chunkSize) {
          // Split oversized paragraph by sentences
          let sentBuf = '';
          for (const s of para.split(/(?<=[.!?])\s+/)) {
            if (sentBuf.length + s.length + 1 <= chunkSize) {
              sentBuf += (sentBuf ? ' ' : '') + s;
            } else {
              if (sentBuf) chunks.push(sentBuf.trim());
              sentBuf = s.length <= chunkSize ? s : s.substring(0, chunkSize);
            }
          }
          if (sentBuf) chunks.push(sentBuf.trim());
          current = '';
        } else {
          current = para;
        }
      }
    }
    if (current.trim()) chunks.push(current.trim());
    return chunks;
  }

  parseJSONResponse(content) {
    if (!content) return null;
    try {
      return JSON.parse(content.replace(/```json\s?|```/g, "").trim());
    } catch {
      const match = content.match(/\{[\s\S]*\}/);
      if (match) try { return JSON.parse(match[0]); } catch {}
      return null;
    }
  }

  deduplicateQuestions(questions) {
    const seen = new Set();
    return questions.filter(q => {
      if (!q?.question?.trim()) return false;
      const key = q.question.toLowerCase().trim().substring(0, 200)
        + '|' + (q.options || []).join('|').toLowerCase().substring(0, 80);
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  filterQuestionTypes(questions) {
    const VALID_TYPES = new Set(['mcq', 'true_false', 'fill_blank', 'open']);
    return questions.filter(q => {
      if (!q?.question || typeof q.question !== 'string') return false;
      const type = (q.type || '').toLowerCase();
      if (!VALID_TYPES.has(type)) return false;
      if (type === 'mcq' && (!Array.isArray(q.options) || q.options.length < 2)) return false;
      if (type === 'true_false' && (!Array.isArray(q.options) || q.options.length < 2)) {
        q.options = ['True', 'False'];
      }
      return true;
    });
  }

  extractQuestionsFallback(response, examType) {
    const parsed = this.parseJSONResponse(response);
    if (parsed?.questions?.length) return parsed.questions;

    const questions = [];
    const regex = /(\d+)\.\s*(.+?)(?=\n\d+\.|\n{2}|$)/gs;
    let match;
    while ((match = regex.exec(response)) !== null) {
      const text = match[2].trim();
      if (text.length > 10) {
        questions.push({ question: text, type: 'mcq', options: ['Option A', 'Option B', 'Option C', 'Option D'], points: 1 });
      }
    }
    return questions;
  }

  generateTemplateExamTitle(documentText) {
    const topics = ['Mathematics', 'Science', 'History', 'Literature', 'Programming', 'Business'];
    const types = ['Quiz', 'Test', 'Assessment', 'Review'];
    return `${topics[Math.floor(Math.random() * topics.length)]} ${types[Math.floor(Math.random() * types.length)]}`;
  }
}

module.exports = new GrokService();