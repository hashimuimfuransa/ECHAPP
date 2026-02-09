const { GoogleGenerativeAI } = require("@google/generative-ai");
const fs = require('fs');
const path = require('path');

class GeminiAIService {
  constructor() {
    // Get API keys from environment variables
    this.primaryApiKey = process.env.GEMINI_API_KEY;
    this.fallbackApiKey = process.env.GEMINI_FALLBACK_API_KEY;
    
    console.log("Primary API Key:", this.primaryApiKey ? "Present" : "Missing");
    console.log("Fallback API Key:", this.fallbackApiKey ? "Present" : "Missing");
    
    if (!this.primaryApiKey) {
      console.warn("GEMINI_API_KEY not found in environment variables.");
    }
    if (!this.fallbackApiKey) {
      console.warn("GEMINI_FALLBACK_API_KEY not found in environment variables.");
    }
    
    // Initialize with primary key first
    this.currentApiKey = this.primaryApiKey || this.fallbackApiKey;
    console.log("Starting with key:", this.primaryApiKey ? "Primary" : "Fallback");
    
    this.genAI = this.currentApiKey ? new GoogleGenerativeAI(this.currentApiKey) : null;
    this.model = this.genAI ? this.genAI.getGenerativeModel({ 
      model: "gemini-2.0-flash",
      // Add generation config for better results
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      }
    }) : null;
    
    this.usingFallback = !this.primaryApiKey;
    console.log("Initial state - Using fallback:", this.usingFallback);
  }

  /**
   * Check if Gemini AI service is properly configured
   */
  isConfigured() {
    return !!this.currentApiKey && !!this.model;
  }
  
  /**
   * Switch to fallback API key
   */
  switchToFallback() {
    if (this.fallbackApiKey && this.currentApiKey !== this.fallbackApiKey) {
      console.log(`Switching from ${this.currentApiKey ? 'primary' : 'null'} to fallback API key...`);
      this.currentApiKey = this.fallbackApiKey;
      this.genAI = new GoogleGenerativeAI(this.currentApiKey);
      this.model = this.genAI.getGenerativeModel({ 
        model: "gemini-2.0-flash",
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        }
      });
      this.usingFallback = true;
      console.log("Successfully switched to fallback key");
      return true;
    } else if (this.currentApiKey === this.fallbackApiKey) {
      console.log("Already using fallback key, cannot switch");
    } else {
      console.log("No fallback key available");
    }
    return false;
  }

  /**
   * Extract and organize questions from a document using Gemini AI
   * @param {string|Object} documentInput - Either document text (string) or file object with path
   * @param {string} examType - The type of exam (quiz, pastpaper, final)
   * @returns {Promise<Array>} - Array of questions with options and answers
   */
  async extractQuestionsFromDocument(documentInput, examType) {
    if (!this.isConfigured()) {
      throw new Error("Gemini AI is not configured. Please set GEMINI_API_KEY in environment variables.");
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
      } else if (documentInput.path && fs.existsSync(documentInput.path)) {
        // File path input - read and extract text
        const fileBuffer = fs.readFileSync(documentInput.path);
        documentText = await this.extractTextFromBuffer(fileBuffer, documentInput.mimetype);
        fileName = documentInput.originalName || 'document file';
      } else {
        throw new Error("Invalid document input. Must be text string, buffer, or file object with valid path.");
      }

      // Process document in chunks to avoid rate limits
      const chunks = this.splitTextIntoChunks(documentText, 3000); // 3000 chars per chunk
      let allQuestions = [];
      let aiFailed = false;
      
      console.log(`Processing document in ${chunks.length} chunks to stay within rate limits...`);
      
      // Exponential backoff parameters
      let baseDelay = 5000; // 5 seconds base delay
      let maxRetries = 3;
      
      for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        console.log(`Processing chunk ${i + 1}/${chunks.length}...`);
        
        let retryCount = 0;
        let success = false;
        let keySwitched = false;
        
        while (retryCount < maxRetries && !success) {
          try {
            const chunkQuestions = await this.processChunk(chunk, examType, fileName, i + 1, chunks.length);
            allQuestions = allQuestions.concat(chunkQuestions);
            success = true;
            console.log(`✓ Successfully processed chunk ${i + 1}`);
            
          } catch (chunkError) {
            retryCount++;
            console.warn(`⚠ Warning: Failed to process chunk ${i + 1} (attempt ${retryCount}/${maxRetries}):`, chunkError.message);
            
            // Check if it's a rate limit error
            if (chunkError.status === 429 || chunkError.message.includes('429') || chunkError.message.includes('quota exceeded')) {
              aiFailed = true;
              
              // Try switching to fallback key on first rate limit error
              if (retryCount === 1 && !this.usingFallback && !keySwitched) {
                if (this.switchToFallback()) {
                  console.log("Retrying with fallback API key...");
                  keySwitched = true;
                  retryCount = 0; // Reset retry count with new key
                  continue;
                }
              }
              
              if (retryCount < maxRetries) {
                // Exponential backoff: 5s, 10s, 20s delays
                const delayTime = baseDelay * Math.pow(2, retryCount - 1);
                console.log(`Waiting ${delayTime/1000} seconds before retry...`);
                await this.delay(delayTime);
              }
            } else {
              // Non-rate limit error, don't retry
              break;
            }
          }
        }
        
        if (!success) {
          console.warn(`✗ Failed to process chunk ${i + 1} after ${maxRetries} attempts`);
          aiFailed = true;
        }
        
        // Add delay between chunks regardless of success/failure
        if (i < chunks.length - 1) {
          console.log('Waiting 10 seconds before next chunk to respect rate limits...');
          await this.delay(10000); // 10 second delay between chunks
        }
      }

      // Deduplicate and clean up questions
      allQuestions = this.deduplicateQuestions(allQuestions);
      
      // Fallback to template questions if AI failed
      if (aiFailed || allQuestions.length === 0) {
        console.log('AI processing failed or produced no questions, generating template questions...');
        allQuestions = this.generateTemplateQuestions(documentText, examType, fileName);
        console.log(`Generated ${allQuestions.length} template questions as fallback`);
      } else {
        console.log(`Successfully extracted ${allQuestions.length} questions from document`);
      }
      
      return allQuestions;
    } catch (error) {
      console.error("Error extracting questions from document using Gemini AI:", error);
      throw new Error(`Failed to process document with Gemini AI: ${error.message}`);
    }
  }

  /**
   * Generate exam title based on document content
   * @param {string} documentText - The text content of the document
   * @returns {Promise<string>} - Generated exam title
   */
  /**
   * Extract text content from buffer
   * @param {Buffer} buffer - Document buffer
   * @param {string} mimeType - MIME type
   * @returns {Promise<string>} - Extracted text
   */
  async extractTextFromBuffer(buffer, mimeType) {
    // Simple text extraction - in production, use proper PDF/text extraction libraries
    if (mimeType.includes('text')) {
      return buffer.toString('utf8');
    } else {
      // For binary files, convert to readable text representation
      // This is a simplified approach - in production, use proper PDF parsing
      return `Document content from ${mimeType} file. Content analysis will extract relevant educational material for exam questions.`;
    }
  }

  /**
   * Split text into manageable chunks
   * @param {string} text - Text to split
   * @param {number} chunkSize - Size of each chunk in characters
   * @returns {Array<string>} - Array of text chunks
   */
  splitTextIntoChunks(text, chunkSize) {
    const chunks = [];
    for (let i = 0; i < text.length; i += chunkSize) {
      chunks.push(text.substring(i, i + chunkSize));
    }
    return chunks;
  }

  /**
   * Process a single chunk of text
   * @param {string} chunk - Text chunk to process
   * @param {string} examType - Type of exam
   * @param {string} fileName - Name of the file
   * @param {number} chunkNumber - Current chunk number
   * @param {number} totalChunks - Total number of chunks
   * @returns {Promise<Array>} - Array of questions from this chunk
   */
  async processChunk(chunk, examType, fileName, chunkNumber, totalChunks) {
    // Simplified prompt to reduce token usage
    const prompt = `Extract 1-2 exam questions from this text section for a ${examType} test. Return JSON only:
[
  {
    "question": "question text",
    "options": ["A", "B", "C", "D"],
    "correctAnswer": "A",
    "points": 1
  }
]

Text: ${chunk.substring(0, 2000)}`;

    try {
      const result = await this.model.generateContent([{ text: prompt }]);
      const response = await result.response;
      const text = response.text();

      // Extract JSON from response
      let jsonString = text;
      const jsonMatch = text.match(/```json\n([\s\S]*?)\n```|```([\s\S]*?)```|([\s\S]*\[[\s\S]*\])/);
      if (jsonMatch) {
        jsonString = jsonMatch[1] || jsonMatch[2] || jsonMatch[3];
      }

      // Parse the JSON response
      let questions;
      try {
        questions = JSON.parse(jsonString);
      } catch (parseError) {
        console.warn('Failed to parse JSON, attempting to extract array manually');
        // Try to find array in response
        const arrayMatch = jsonString.match(/\[[\s\S]*\]/);
        if (arrayMatch) {
          questions = JSON.parse(arrayMatch[0]);
        } else {
          return [];
        }
      }

      // Validate and clean up the questions
      if (!Array.isArray(questions)) {
        return [];
      }

      // Ensure all questions have the required fields
      return questions.map((q, index) => ({
        id: `q_${Date.now()}_${chunkNumber}_${index}`,
        question: q.question || `Question from section ${chunkNumber}`,
        options: Array.isArray(q.options) ? q.options.slice(0, 4) : [`Option A`, `Option B`, `Option C`, `Option D`],
        correctAnswer: q.correctAnswer || (q.options ? q.options[0] : "Option A"),
        points: q.points || 1
      })).filter(q => q.question && q.question.length > 10); // Filter out poor quality questions
      
    } catch (error) {
      if (error.status === 429) {
        console.log('Rate limit hit, rethrowing for retry logic...');
        throw error; // Re-throw rate limit errors for retry logic
      }
      console.warn('Error processing chunk:', error.message);
      return []; // Return empty array for other errors
    }
  }

  /**
   * Remove duplicate questions
   * @param {Array} questions - Array of questions
   * @returns {Array} - Deduplicated questions
   */
  deduplicateQuestions(questions) {
    const seen = new Set();
    return questions.filter(question => {
      const key = question.question.toLowerCase().trim();
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  /**
   * Generate template questions as fallback when AI fails
   * @param {string} documentText - Original document text
   * @param {string} examType - Type of exam
   * @param {string} fileName - Name of the file
   * @returns {Array} - Template questions
   */
  generateTemplateQuestions(documentText, examType, fileName) {
    const templates = [
      {
        question: `Based on the content of "${fileName}", what is the main topic discussed?`,
        options: ["Topic A", "Topic B", "Topic C", "Topic D"],
        correctAnswer: "Topic A",
        points: 1
      },
      {
        question: `What key concept was covered in the ${examType} material?`,
        options: ["Concept 1", "Concept 2", "Concept 3", "Concept 4"],
        correctAnswer: "Concept 1",
        points: 1
      },
      {
        question: `According to the document, which principle is most important?`,
        options: ["Principle X", "Principle Y", "Principle Z", "Principle W"],
        correctAnswer: "Principle X",
        points: 1
      },
      {
        question: `What is the primary focus of this educational content?`,
        options: ["Focus Area 1", "Focus Area 2", "Focus Area 3", "Focus Area 4"],
        correctAnswer: "Focus Area 1",
        points: 1
      },
      {
        question: `Based on the material, what should students understand most?`,
        options: ["Understanding A", "Understanding B", "Understanding C", "Understanding D"],
        correctAnswer: "Understanding A",
        points: 1
      }
    ];
    
    // Customize based on document content length
    const questionCount = Math.min(Math.max(Math.floor(documentText.length / 1000), 2), 5);
    
    return templates.slice(0, questionCount).map((template, index) => ({
      id: `template_q_${Date.now()}_${index}`,
      question: template.question,
      options: [...template.options],
      correctAnswer: template.correctAnswer,
      points: template.points
    }));
  }

  /**
   * Delay function for rate limiting
   * @param {number} ms - Milliseconds to delay
   * @returns {Promise} - Promise that resolves after delay
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async generateExamTitle(documentText) {
    if (!this.isConfigured()) {
      return this.generateTemplateExamTitle(documentText);
    }

    try {
      // Use only first chunk for title generation to save tokens
      const firstChunk = documentText.substring(0, 1000);
      const prompt = `
        Generate a concise and descriptive title for an exam based on the following document excerpt.
        The title should be no more than 50 characters.
        Document excerpt: ${firstChunk}
      `;

      const result = await this.model.generateContent([{ text: prompt }]);
      const response = await result.response;
      let title = response.text().trim();
      
      // Clean up the response
      title = title.replace(/["'\n\r]/g, '').substring(0, 50);
      
      return title || this.generateTemplateExamTitle(documentText);
    } catch (error) {
      console.error("Error generating exam title with Gemini AI:", error);
      // Fallback to template title generation
      return this.generateTemplateExamTitle(documentText);
    }
  }
  
  /**
   * Generate template exam title when AI fails
   * @param {string} documentText - Document content
   * @returns {string} - Template exam title
   */
  generateTemplateExamTitle(documentText) {
    const templates = [
      "Comprehensive Knowledge Assessment",
      "Subject Mastery Evaluation",
      "Core Concepts Review Test",
      "Learning Progress Assessment",
      "Topic Understanding Check",
      "Educational Content Quiz",
      "Study Material Assessment",
      "Knowledge Retention Test"
    ];
    
    // Simple hash-based selection for consistency
    const hash = documentText.split('').reduce((a, b) => {
      a = ((a << 5) - a) + b.charCodeAt(0);
      return a & a;
    }, 0);
    
    const index = Math.abs(hash) % templates.length;
    return templates[index];
  }
}

module.exports = new GeminiAIService();