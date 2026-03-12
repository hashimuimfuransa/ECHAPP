const Groq = require("groq-sdk");

class GrokService {
  constructor() {
    // Get API key from environment variables
    this.apiKey = process.env.GROQ_API_KEY;
    if (!this.apiKey) {
      console.warn("GROQ_API_KEY not found in environment variables. AI features will be disabled.");
    }
    
    this.groq = this.apiKey ? new Groq({ apiKey: this.apiKey }) : null;
    
    // Model management system
    this.currentModel = "llama-3.3-70b-versatile";
    this.modelCache = new Map(); // Cache for model availability
    this.lastModelCheck = null;
    this.modelCheckInterval = 24 * 60 * 60 * 1000; // 24 hours
    
    console.log("Grok Service initialized:", this.isConfigured() ? "Ready" : "Not configured");
    console.log("Current AI model:", this.currentModel);
  }

  /**
   * Check if Grok service is properly configured
   */
  isConfigured() {
    this._checkConfiguration();
    return !!this.apiKey && !!this.groq;
  }

  /**
   * Internal helper to ensure configuration is loaded
   * (Needed because constructor may run before dotenv.config())
   */
  _checkConfiguration() {
    if (!this.apiKey || !this.groq) {
      this.apiKey = process.env.GROQ_API_KEY;
      if (this.apiKey && !this.groq) {
        this.groq = new Groq({ apiKey: this.apiKey });
        console.log("Grok Service re-initialized with environment key.");
      }
    }
  }

  /**
   * Get the current active model
   */
  getCurrentModel() {
    return this.currentModel;
  }

  /**
   * Set a new model
   */
  setCurrentModel(modelName) {
    console.log(`Updating AI model from ${this.currentModel} to ${modelName}`);
    this.currentModel = modelName;
  }

  /**
   * Check if it's time to verify model status
   */
  shouldCheckModel() {
    if (!this.lastModelCheck) return true;
    const timeSinceLastCheck = Date.now() - this.lastModelCheck;
    return timeSinceLastCheck > this.modelCheckInterval;
  }

  /**
   * Test if a model is available by making a small API call
   */
  async testModelAvailability(modelName) {
    // Check cache first
    if (this.modelCache.has(modelName)) {
      const cached = this.modelCache.get(modelName);
      if (Date.now() - cached.timestamp < this.modelCheckInterval) {
        return cached.available;
      }
    }

    try {
      // Make a simple test call
      await this.groq.chat.completions.create({
        messages: [{ role: "user", content: "test" }],
        model: modelName,
        max_tokens: 1,
        temperature: 0
      });
      
      // Cache successful result
      this.modelCache.set(modelName, { 
        available: true, 
        timestamp: Date.now() 
      });
      return true;
    } catch (error) {
      // Cache failed result
      this.modelCache.set(modelName, { 
        available: false, 
        timestamp: Date.now(),
        error: error.message 
      });
      
      // If model is decommissioned, log it
      if (error.message.includes('decommissioned') || error.message.includes('not found')) {
        console.warn(`Model ${modelName} is no longer available: ${error.message}`);
      }
      return false;
    }
  }

  /**
   * Get list of available models from Groq API
   */
  async getAvailableModels() {
    try {
      // Note: Groq doesn't have a public models endpoint
      // We'll maintain a list of known good models
      const knownModels = [
        "llama-3.3-70b-versatile",
        "llama3-70b-8192",
        "llama3-8b-8192",
        "mixtral-8x7b-32768",
        "gemma-7b-it"
      ];
      
      const availableModels = [];
      
      for (const model of knownModels) {
        const isAvailable = await this.testModelAvailability(model);
        if (isAvailable) {
          availableModels.push(model);
        }
      }
      
      return availableModels;
    } catch (error) {
      console.error("Error fetching available models:", error);
      return [this.currentModel]; // Return current model as fallback
    }
  }

  /**
   * Auto-update to the best available model
   */
  async autoUpdateModel() {
    // Only check periodically to avoid excessive API calls
    if (!this.shouldCheckModel()) {
      return this.currentModel;
    }

    console.log("Checking for model updates...");
    this.lastModelCheck = Date.now();

    try {
      // Test current model first
      const currentModelWorks = await this.testModelAvailability(this.currentModel);
      
      if (currentModelWorks) {
        console.log(`Current model ${this.currentModel} is still working`);
        return this.currentModel;
      }

      // Current model failed, find a replacement
      console.log(`Current model ${this.currentModel} is not available, searching for alternatives...`);
      const availableModels = await this.getAvailableModels();
      
      if (availableModels.length > 0) {
        const newModel = availableModels[0]; // Use the first available model
        this.setCurrentModel(newModel);
        console.log(`✅ Auto-updated to new model: ${newModel}`);
        return newModel;
      } else {
        console.error("No available models found!");
        return this.currentModel; // Keep current model
      }
    } catch (error) {
      console.error("Error during model auto-update:", error);
      return this.currentModel; // Keep current model on error
    }
  }

  /**
   * Get model with auto-update capability
   */
  async getModel() {
    await this.autoUpdateModel();
    return this.currentModel;
  }

  /**
   * Force immediate model check and update
   */
  async forceModelUpdate() {
    console.log("Force model update triggered");
    this.lastModelCheck = 0; // Reset to force check
    return await this.autoUpdateModel();
  }

  /**
   * Get model status information
   */
  getModelStatus() {
    return {
      currentModel: this.currentModel,
      lastCheck: this.lastModelCheck ? new Date(this.lastModelCheck).toISOString() : null,
      nextCheck: this.lastModelCheck ? new Date(this.lastModelCheck + this.modelCheckInterval).toISOString() : null,
      cachedModels: Array.from(this.modelCache.entries()).map(([model, data]) => ({
        model,
        available: data.available,
        lastChecked: new Date(data.timestamp).toISOString(),
        error: data.error
      }))
    };
  }

  /**
   * Extract and organize questions from a document using Grok AI
   * @param {string|Object} documentInput - Either document text (string) or file object with path
   * @param {string} examType - The type of exam (quiz, pastpaper, final)
   * @returns {Promise<Array>} - Array of questions with options and answers
   */
  async extractQuestionsFromDocument(documentInput, examType) {
    this._checkConfiguration();
    if (!this.isConfigured()) {
      throw new Error("Grok is not configured. Please set GROQ_API_KEY in environment variables.");
    }

    try {
      let documentText;
      let fileName = 'document';
      
      // Extract text content first
      if (typeof documentInput === 'string') {
        // Text input
        documentText = documentInput;
        fileName = 'text document';
      } else if (documentInput.buffer) {
        // Buffer input - extract text content
        documentText = await this.extractTextFromBuffer(documentInput.buffer, documentInput.mimetype);
        fileName = documentInput.originalName || 'uploaded document';
      } else if (documentInput.path && require('fs').existsSync(documentInput.path)) {
        // File path input - read and extract text
        const fs = require('fs');
        const fileBuffer = fs.readFileSync(documentInput.path);
        documentText = await this.extractTextFromBuffer(fileBuffer, documentInput.mimetype);
        fileName = documentInput.originalName || 'document file';
      } else {
        throw new Error("Invalid document input. Must be text string, buffer, or file object with valid path.");
      }

      // Process document in chunks to avoid context limits
      const chunks = this.splitTextIntoChunks(documentText, 10000); // Increase chunk size to capture more questions per chunk
      let allQuestions = [];
      
      console.log(`Document text extracted (first 200 chars): ${documentText.substring(0, 200)}...`);
      console.log(`Processing document in ${chunks.length} chunks with Grok...`);
      
      for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        console.log(`Processing chunk ${i + 1}/${chunks.length}...`);
        
        try {
          const chunkQuestions = await this.processChunkWithGrok(chunk, examType, fileName, i + 1, chunks.length);
          console.log(`Chunk ${i + 1}: Generated ${chunkQuestions.length} questions`);
          allQuestions = [...allQuestions, ...chunkQuestions];
        } catch (chunkError) {
          console.error(`Error processing chunk ${i + 1}:`, chunkError.message);
          // Continue with other chunks
        }
      }
      
      // Deduplicate questions and return
      let uniqueQuestions = this.deduplicateQuestions(allQuestions);
      
      // Filter out open-ended and fill-in-blank questions
      let filteredQuestions = this.filterQuestionTypes(uniqueQuestions);
      
      console.log(`Total unique questions extracted: ${uniqueQuestions.length}`);
      console.log(`Questions after filtering: ${filteredQuestions.length} (all types allowed)`);

      // Determine correct answers using separate Step 2 logic in batches for performance
      console.log(`Determining correct answers for ${filteredQuestions.length} questions in batches...`);
      
      const batchSize = 10;
      const questionBatches = [];
      for (let i = 0; i < filteredQuestions.length; i += batchSize) {
        questionBatches.push(filteredQuestions.slice(i, i + batchSize));
      }

      await Promise.all(questionBatches.map(async (batch, batchIdx) => {
        const batchResults = await this.findCorrectAnswersBatch(documentText, batch);
        
        batchResults.forEach(res => {
          if (res.questionIndex !== undefined && res.questionIndex < batch.length) {
            batch[res.questionIndex].correctAnswer = res.correctAnswer;
          }
        });
      }));
      
      return filteredQuestions;
    } catch (error) {
      console.error("Error extracting questions from document with Grok:", error);
      throw error;
    }
  }

  /**
   * Process a single chunk of text with Grok AI
   */
  async processChunkWithGrok(chunk, examType, fileName, chunkNumber, totalChunks) {
    const prompt = `
Extract all questions from the provided document content.

Rules:
- Do NOT answer the questions.
- Do NOT guess answers.
- Preserve the exact question and options.
- Identify the question type: mcq, true_false, fill_blank, open.
- Default to "mcq" if options are present.
- Return ONLY valid JSON.

Format:
{
 "questions": [
   {
     "question": "...",
     "type": "mcq",
     "options": ["Option A", "Option B", "Option C", "Option D"],
     "points": 1
   }
 ]
}

DOCUMENT CONTENT (CHUNK ${chunkNumber}/${totalChunks}):
---
${chunk}
---
`;

    const chatCompletion = await this.groq.chat.completions.create({
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
      model: await this.getModel(),
      temperature: 0.3,
      max_tokens: 8192, // Increase to allow more questions in the response
    });

    const response = chatCompletion.choices[0]?.message?.content;
    
    if (!response) {
      throw new Error("Empty response from Grok AI");
    }

    // Parse JSON response
    try {
      console.log("Attempting to parse raw response as JSON...");
      const jsonResponse = this.parseJSONResponse(response);
      if (jsonResponse) {
        console.log(`Successfully parsed JSON, found ${jsonResponse.questions?.length || 0} questions`);
        return jsonResponse.questions || [];
      }
      throw new Error("JSON parsing resulted in null");
    } catch (parseError) {
      console.error("Failed to parse raw Grok response as JSON:", parseError.message);
      
      // Try to extract questions using regex as fallback
      console.log("Falling back to regex-based question extraction...");
      return this.extractQuestionsFallback(response, examType);
    }
  }

  /**
   * Determine the correct answer for a question using the document content
   * @param {string} documentText - The full document content
   * @param {Object} question - The question object
   * @returns {Promise<number|null>} - Index of the correct answer or null
   */
  async findCorrectAnswer(documentText, question) {
    if (!this.isConfigured() || !question.options || question.options.length === 0) {
      return null;
    }

    const prompt = `
Use the document below to determine the correct answer.

DOCUMENT:
${documentText.substring(0, 8000)}

QUESTION:
${question.question}

OPTIONS:
${question.options.join("\n")}

Rules:
- The correct answer must come from the document.
- If the document does not contain the answer return null.
- Return ONLY the index of the correct option.
- Indexing starts at 0.

Response format (JSON ONLY):
{
 "correctAnswer": number
}
`;

    try {
      const response = await this.groq.chat.completions.create({
        messages: [{ role: "user", content: prompt }],
        model: await this.getModel(),
        temperature: 0
      });

      const content = response.choices[0]?.message?.content || "";
      const parsed = this.parseJSONResponse(content);
      return parsed?.correctAnswer ?? null;
    } catch (error) {
      console.error("Error finding correct answer:", error.message);
      return null;
    }
  }

  /**
   * Determine correct answers for a batch of questions
   * @param {string} documentText - The document text
   * @param {Array} questions - Array of question objects
   * @returns {Promise<Array>} - Array of results with correctAnswer
   */
  async findCorrectAnswersBatch(documentText, questions) {
    if (!this.isConfigured() || questions.length === 0) return [];

    const prompt = `
Use the document below to determine the correct answers for the following questions.

DOCUMENT (CONTEXT):
---
${documentText.substring(0, 10000)}
---

QUESTIONS:
${questions.map((q, idx) => `${idx + 1}. ${q.question}\nOptions: ${q.options.join(", ")}`).join("\n\n")}

Rules:
- The answers must come from the document.
- If not found, return null for that question.
- Return results in JSON format.

Response Format (JSON ONLY):
{
 "results": [
   { "questionIndex": 0, "correctAnswer": 0 },
   { "questionIndex": 1, "correctAnswer": 2 }
 ]
}
`;

    try {
      const response = await this.groq.chat.completions.create({
        messages: [{ role: "user", content: prompt }],
        model: await this.getModel(),
        temperature: 0
      });

      const content = response.choices[0]?.message?.content || "";
      const parsed = this.parseJSONResponse(content);
      return parsed?.results || [];
    } catch (error) {
      console.error("Error in batch grading:", error.message);
      return [];
    }
  }

  /**
   * Parse and clean JSON responses from AI
   */
  parseJSONResponse(content) {
    if (!content) return null;
    try {
      // Remove potential markdown blocks
      const cleaned = content.replace(/```json\s?|```/g, "").trim();
      return JSON.parse(cleaned);
    } catch (e) {
      const match = content.match(/\{[\s\S]*\}/);
      if (match) {
        try {
          return JSON.parse(match[0]);
        } catch (inner) {
          return null;
        }
      }
      return null;
    }
  }

  /**
   * Organize lesson notes using Grok AI
   * @param {Object} file - File object with buffer, mimetype, and originalname
   * @param {string} mimeType - MIME type of the document
   * @returns {Promise<string>} - Organized notes content
   */
  async organizeNotes(file, mimeType) {
    if (!this.isConfigured()) {
      throw new Error("Grok is not configured. Please set GROQ_API_KEY in environment variables.");
    }

    try {
      // Extract text content from the file
      const documentText = await this.extractTextFromBuffer(file.buffer, mimeType);
      
      if (!documentText || documentText.trim().length === 0) {
        throw new Error("No text content found in document");
      }

      const prompt = `
You are an expert educational content organizer. Your task is to organize the following lesson notes into a clear, structured format suitable for student learning.

DOCUMENT CONTENT:
${documentText.substring(0, 8000)} // Limit content to prevent token overflow

Please organize these notes by:
1. Identifying main topics and subtopics
2. Creating clear headings and sections
3. Adding bullet points for key concepts
4. Including examples where relevant
5. Making the content easy to understand and study

Return the organized notes in a clean, readable format with proper structure.
`;

      const chatCompletion = await this.groq.chat.completions.create({
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
        model: await this.getModel(),
        temperature: 0.4,
        max_tokens: 4096,
      });

      const organizedNotes = chatCompletion.choices[0]?.message?.content;
      
      if (!organizedNotes) {
        throw new Error("Empty response from Grok AI for notes organization");
      }

      return organizedNotes;
    } catch (error) {
      console.error("Error organizing notes with Grok:", error);
      throw error;
    }
  }

  /**
   * Generate exam title using Grok AI
   * @param {string} documentText - The document content
   * @returns {Promise<string>} - Generated exam title
   */
  async generateExamTitle(documentText) {
    if (!this.isConfigured()) {
      throw new Error("Grok is not configured. Please set GROQ_API_KEY in environment variables.");
    }

    try {
      const prompt = `
Based on the following educational content, generate a concise and descriptive exam title:

CONTENT:
${documentText.substring(0, 2000)}

Generate a professional exam title that reflects the main topic covered. Keep it under 50 characters.
`;

      const chatCompletion = await this.groq.chat.completions.create({
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
        model: await this.getModel(),
        temperature: 0.3,
        max_tokens: 100,
      });

      let title = chatCompletion.choices[0]?.message?.content || '';
      
      // Clean up the title
      title = title.replace(/["'\n\r]/g, '').substring(0, 50);
      
      return title || this.generateTemplateExamTitle(documentText);
    } catch (error) {
      console.error("Error generating exam title with Grok:", error);
      // Fallback to template title generation
      return this.generateTemplateExamTitle(documentText);
    }
  }

  /**
   * Generate a chat response using Grok AI
   * @param {Array} messages - Chat message history
   * @param {Object} context - Learning context
   * @returns {Promise<string>} - AI generated response
   */
  async generateChatResponse(messages, context) {
    if (!this.isConfigured()) {
      return "I'm sorry, my AI brain is not currently connected. Please contact support.";
    }

    try {
      const chatCompletion = await this.groq.chat.completions.create({
        messages: messages,
        model: await this.getModel(),
        temperature: 0.7,
        max_tokens: 2048,
      });

      return chatCompletion.choices[0]?.message?.content || "I'm not sure how to respond to that.";
    } catch (error) {
      console.error("Error generating chat response with Grok:", error);
      return "I encountered an error while processing your request. Please try again.";
    }
  }

  // Helper methods
  
  async extractTextFromBuffer(buffer, mimeType) {
    if (mimeType.includes('text')) {
      return buffer.toString('utf8');
    } else {
      // For PDF and other document types, use the document processing service
      try {
        const DocumentProcessingService = require('./document_processing_service');
        const text = await DocumentProcessingService.extractTextFromDocument(buffer, mimeType);
        if (!text || text.trim().length < 5) {
          console.warn(`Extracted text is empty or too short for ${mimeType}`);
          return '';
        }
        return text;
      } catch (error) {
        console.warn('Failed to extract text from document buffer:', error.message);
        return '';
      }
    }
  }

  splitTextIntoChunks(text, chunkSize) {
    if (!text || text.length <= chunkSize) {
      return [text || ''];
    }

    // Try to split by double newlines but preserve question structure
    const paragraphs = text.split(/\n\s*\n/);
    
    // If no paragraphs, split by single newlines
    const units = paragraphs.length <= 1 ? text.split(/\n/) : paragraphs;
    
    const chunks = [];
    let currentChunk = '';
    
    for (const unit of units) {
      if (currentChunk.length + unit.length <= chunkSize) {
        currentChunk += unit + (paragraphs.length <= 1 ? '\n' : '\n\n');
      } else {
        if (currentChunk.length > 0) {
          chunks.push(currentChunk.trim());
        }
        
        // If a single unit is too large, split it by characters as last resort
        if (unit.length > chunkSize) {
          for (let i = 0; i < unit.length; i += chunkSize) {
            chunks.push(unit.substring(i, i + chunkSize));
          }
          currentChunk = '';
        } else {
          currentChunk = unit + (paragraphs.length <= 1 ? '\n' : '\n\n');
        }
      }
    }
    
    if (currentChunk.length > 0) {
      chunks.push(currentChunk.trim());
    }
    
    return chunks;
  }
  
  /**
   * Split a large paragraph into smaller chunks
   */
  splitLargeParagraph(paragraph, chunkSize) {
    // Split by sentences to preserve meaning
    const sentences = paragraph.split(/(?<=[.!?])\s+/);
    const chunks = [];
    let currentChunk = '';
    
    for (const sentence of sentences) {
      if (currentChunk.length + sentence.length <= chunkSize) {
        currentChunk += sentence + ' ';
      } else {
        if (currentChunk.length > 0) {
          chunks.push(currentChunk.trim());
        }
        
        // If a single sentence is too long, fall back to character-based splitting
        if (sentence.length > chunkSize) {
          const sentenceChunks = [];
          for (let i = 0; i < sentence.length; i += chunkSize) {
            sentenceChunks.push(sentence.substring(i, i + chunkSize));
          }
          chunks.push(...sentenceChunks);
          currentChunk = '';
        } else {
          currentChunk = sentence + ' ';
        }
      }
    }
    
    if (currentChunk.length > 0) {
      chunks.push(currentChunk.trim());
    }
    
    return chunks;
  }

  deduplicateQuestions(questions) {
    const seen = new Set();
    const result = questions.filter(question => {
      // More robust question identification
      const questionText = question.question || '';
      if (!questionText.trim()) return false; // Skip empty questions
      
      // Create a more unique key that's less likely to cause false duplicates
      // Use more characters and include options to distinguish between similar questions
      let key = questionText.toLowerCase().trim().substring(0, 250); 
      
      // Add options to the key to distinguish questions with same start but different options
      if (Array.isArray(question.options)) {
        key += '|opts:' + question.options.join('|').toLowerCase().substring(0, 100);
      }
      
      if (question.type) {
        key += '|type:' + question.type.toLowerCase();
      }
      
      if (seen.has(key)) {
        console.log(`Skipping duplicate question: ${questionText.substring(0, 50)}...`);
        return false;
      }
      
      seen.add(key);
      return true;
    });
    
    console.log(`Deduplication result: ${questions.length} -> ${result.length} questions`);
    return result;
  }

  extractQuestionsFallback(response, examType) {
    // Simple regex-based fallback for question extraction
    const questions = [];
    
    console.log("Using fallback question extraction method");
    
    // Try to extract JSON-like structure first
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      try {
        const jsonResponse = JSON.parse(jsonMatch[0]);
        if (jsonResponse.questions && Array.isArray(jsonResponse.questions)) {
          console.log(`Found ${jsonResponse.questions.length} questions in JSON structure`);
          return jsonResponse.questions;
        }
      } catch (e) {
        console.log("JSON parsing failed in fallback, trying regex method");
      }
    }
    
    // Look for numbered questions as backup - only generate MCQ questions
    const questionRegex = /(\d+)\.\s*(.+?)(?=\n\d+\.|\n{2}|$)/gs;
    let match;
    let questionCount = 0;
    
    while ((match = questionRegex.exec(response)) !== null) {
      const questionText = match[2].trim();
      if (questionText.length > 10) {
        questionCount++;
        questions.push({
          question: questionText,
          type: 'mcq',
          options: [`Option A for: ${questionText.substring(0, 30)}...`, 'Option B', 'Option C', 'Option D'],
          correctAnswer: 'Option A',
          points: 1
        });
      }
    }
    
    console.log(`Extracted ${questionCount} questions using regex method`);
    
    return questions;
  }

  generateTemplateQuestions(documentText, examType, fileName) {
    const templates = [
      {
        question: `Based on the content of "${fileName}", what is the main topic discussed?`,
        type: 'mcq',
        options: ["Topic A", "Topic B", "Topic C", "Topic D"],
        correctAnswer: "Topic A",
        points: 1,
      }
    ];
    
    return templates;
  }

  filterQuestionTypes(questions) {
    // Allow all question types supported by the model
    
    const filtered = questions.filter(question => {
      // Validate basic question structure
      if (!question.question || typeof question.question !== 'string') {
        console.log(`Filtering out question with invalid question text`);
        return false;
      }
      
      // Supported question types in our system
      const validTypes = ['mcq', 'true_false', 'fill_blank', 'open'];
      
      const questionType = (question.type || '').toLowerCase();
      const isValidType = validTypes.includes(questionType);
      
      if (!isValidType) {
        console.log(`Filtering out unsupported question type: ${question.type}`);
        return false;
      }
      
      // MCQ questions need options
      if (questionType === 'mcq') {
        if (!Array.isArray(question.options) || question.options.length < 2) {
          console.log(`Filtering MCQ with insufficient options:`, question.question.substring(0, 50));
          return false;
        }
      }

      // True/False questions need exactly 2 options if provided, or we can default them
      if (questionType === 'true_false') {
        if (!Array.isArray(question.options) || question.options.length < 2) {
          question.options = ['True', 'False'];
        }
      }
      
      return true;
    });
    
    console.log(`Filtered questions: ${filtered.length} valid questions from ${questions.length} total`);
    return filtered;
  }

  generateTemplateExamTitle(documentText) {
    const topics = ['Mathematics', 'Science', 'History', 'Literature', 'Programming', 'Business'];
    const types = ['Quiz', 'Test', 'Assessment', 'Review', 'Practice'];
    
    const randomTopic = topics[Math.floor(Math.random() * topics.length)];
    const randomType = types[Math.floor(Math.random() * types.length)];
    
    return `${randomTopic} ${randomType}`;
  }
}

module.exports = new GrokService();