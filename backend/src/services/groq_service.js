const Groq = require("groq-sdk");

class GroqService {
  constructor() {
    // Get API key from environment variables
    this.apiKey = process.env.GROQ_API_KEY;
    if (!this.apiKey) {
      console.warn("GROQ_API_KEY not found in environment variables. AI features will be disabled.");
    }
    
    this.groq = this.apiKey ? new Groq({ apiKey: this.apiKey }) : null;
    
    console.log("Groq Service initialized:", this.isConfigured() ? "Ready" : "Not configured");
  }

  /**
   * Check if Groq service is properly configured
   */
  isConfigured() {
    return !!this.apiKey && !!this.groq;
  }

  /**
   * Extract and organize questions from a document using Groq
   * @param {string|Object} documentInput - Either document text (string) or file object with path
   * @param {string} examType - The type of exam (quiz, pastpaper, final)
   * @returns {Promise<Array>} - Array of questions with options and answers
   */
  async extractQuestionsFromDocument(documentInput, examType) {
    if (!this.isConfigured()) {
      throw new Error("Groq is not configured. Please set GROQ_API_KEY in environment variables.");
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
      const chunks = this.splitTextIntoChunks(documentText, 8000); // 8000 chars per chunk for Mixtral
      let allQuestions = [];
      
      console.log(`Document text extracted (first 200 chars): ${documentText.substring(0, 200)}...`);
      console.log(`Processing document in ${chunks.length} chunks with Groq...`);
      
      for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        console.log(`Processing chunk ${i + 1}/${chunks.length}...`);
        
        try {
          const chunkQuestions = await this.processChunkWithGroq(chunk, examType, fileName, i + 1, chunks.length);
          allQuestions = allQuestions.concat(chunkQuestions);
          console.log(`✓ Successfully processed chunk ${i + 1} - Generated ${chunkQuestions.length} questions`);
        } catch (chunkError) {
          console.warn(`⚠ Warning: Failed to process chunk ${i + 1}:`, chunkError.message);
          // Continue with remaining chunks
        }
        
        // Small delay between chunks to respect rate limits
        if (i < chunks.length - 1) {
          await this.delay(1000); // 1 second delay
        }
      }

      // Deduplicate and clean up questions
      allQuestions = this.deduplicateQuestions(allQuestions);
      
      if (allQuestions.length === 0) {
        // Fallback to template questions if Groq fails
        console.log('Groq processing failed or produced no questions, generating template questions...');
        allQuestions = this.generateTemplateQuestions(documentText, examType, fileName);
        console.log(`Generated ${allQuestions.length} template questions as fallback`);
      } else {
        console.log(`Successfully extracted ${allQuestions.length} questions from document using Groq`);
      }
      
      return allQuestions;
    } catch (error) {
      console.error("Error extracting questions from document using Groq:", error);
      throw new Error(`Failed to process document with Groq: ${error.message}`);
    }
  }

  /**
   * Process a single chunk with Groq
   */
  async processChunkWithGroq(chunk, examType, fileName, chunkNumber, totalChunks) {
    const prompt = `Extract exam questions from this text section for a ${examType.toUpperCase()} test. Return 5-8 high-quality questions in JSON format only:

[
  {
    "question": "The question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": "Option A",
    "points": 1
  }
]

Text content from section ${chunkNumber} of ${fileName}:
${chunk}

Requirements:
- Extract relevant questions from this section only
- Create appropriate ${examType.toUpperCase()} exam questions
- Multiple choice with 4 options
- Clear and unambiguous questions
- JSON format only, no extra text
- Generate 5-8 comprehensive questions per section`;

    try {
      const completion = await this.groq.chat.completions.create({
        model: "llama-3.1-8b-instant",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.3,
        max_tokens: 4000
      });

      const response = completion.choices[0].message.content;
      
      console.log(`Groq API Response (first 300 chars): ${response.substring(0, 300)}...`);
      
      // Extract JSON from response - more robust parsing
      let jsonString = response.trim();
      
      // Try multiple JSON extraction patterns
      const patterns = [
        /```json\n([\s\S]*?)\n```/,  // ```json
        /```([\s\S]*?)```/,          // ```
        /\[([\s\S]*)\]/,             // Direct array
        /\{([\s\S]*)\}/              // Direct object containing array
      ];
      
      let extractedJson = null;
      for (const pattern of patterns) {
        const match = jsonString.match(pattern);
        if (match) {
          extractedJson = match[1] || match[0];
          break;
        }
      }
      
      // If no pattern matched, try the whole response
      if (!extractedJson) {
        extractedJson = jsonString;
      }
      
      // Clean up the JSON string
      let cleanJson = extractedJson.trim();
      
      // Parse the JSON response
      let questions;
      try {
        questions = JSON.parse(cleanJson);
      } catch (parseError) {
        console.warn('Failed to parse JSON:', parseError.message);
        console.warn('Response content:', cleanJson.substring(0, 300) + '...');
        
        // Try to find and extract just the array part
        const arrayStart = cleanJson.indexOf('[');
        let arrayEnd = cleanJson.lastIndexOf(']');
        
        // If we can't find a closing bracket, try to find the last complete JSON object
        if (arrayStart !== -1) {
          if (arrayEnd === -1 || arrayEnd <= arrayStart) {
            // Find the last complete object before any truncation
            const lastObjectEnd = cleanJson.lastIndexOf('}');
            if (lastObjectEnd > arrayStart) {
              arrayEnd = cleanJson.indexOf(']', lastObjectEnd);
              if (arrayEnd === -1) {
                // If no closing bracket, try to reconstruct valid JSON
                const lastCompleteObject = cleanJson.substring(arrayStart, lastObjectEnd + 1);
                // Try to close the array properly
                const reconstructedArray = lastCompleteObject.trim() + ']';
                try {
                  questions = JSON.parse(reconstructedArray);
                  console.log('Successfully parsed reconstructed JSON');
                  return this.validateAndCleanQuestions(questions);
                } catch (reconstructError) {
                  console.warn('Failed to parse reconstructed JSON:', reconstructError.message);
                }
              }
            }
          }
          
          if (arrayStart !== -1 && arrayEnd !== -1 && arrayEnd > arrayStart) {
            const arrayString = cleanJson.substring(arrayStart, arrayEnd + 1);
            try {
              questions = JSON.parse(arrayString);
              console.log('Successfully parsed extracted array');
              return this.validateAndCleanQuestions(questions);
            } catch (arrayParseError) {
              console.warn('Failed to parse extracted array:', arrayParseError.message);
            }
          }
        }
        
        // If all parsing fails, try line-by-line parsing
        console.log('Attempting line-by-line JSON parsing...');
        questions = this.parseQuestionsLineByLine(cleanJson);
        if (questions && questions.length > 0) {
          console.log(`Successfully parsed ${questions.length} questions line-by-line`);
          return this.validateAndCleanQuestions(questions);
        }
        
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
      console.error("Error processing chunk with Groq:", error);
      throw error;
    }
  }

  /**
   * Generate exam title using Groq
   */
  async generateExamTitle(documentText) {
    if (!this.isConfigured()) {
      return this.generateTemplateExamTitle(documentText);
    }

    try {
      // Use only first chunk for title generation
      const firstChunk = documentText.substring(0, 2000);
      
      const completion = await this.groq.chat.completions.create({
        model: "llama-3.1-8b-instant",
        messages: [
          {
            role: "user",
            content: `Generate a concise and descriptive title for an exam based on this document excerpt. Return only the title text (max 50 characters):\n\n${firstChunk}`
          }
        ],
        temperature: 0.7,
        max_tokens: 100
      });

      const response = completion.choices[0].message.content;
      let title = response.trim();
      
      // Clean up the response
      title = title.replace(/["'\n\r]/g, '').substring(0, 50);
      
      return title || this.generateTemplateExamTitle(documentText);
    } catch (error) {
      console.error("Error generating exam title with Groq:", error);
      // Fallback to template title generation
      return this.generateTemplateExamTitle(documentText);
    }
  }

  // Helper methods (same as Gemini service)
  
  async extractTextFromBuffer(buffer, mimeType) {
    if (mimeType.includes('text')) {
      return buffer.toString('utf8');
    } else {
      // For PDF and other document types, use the document processing service
      try {
        const DocumentProcessingService = require('./document_processing_service');
        const text = await DocumentProcessingService.extractTextFromDocument(buffer, mimeType);
        return text || `Document content from ${mimeType} file. Content analysis will extract relevant educational material for exam questions.`;
      } catch (error) {
        console.warn('Failed to extract text from document buffer:', error.message);
        return `Document content from ${mimeType} file. Content analysis will extract relevant educational material for exam questions.`;
      }
    }
  }

  splitTextIntoChunks(text, chunkSize) {
    const chunks = [];
    for (let i = 0; i < text.length; i += chunkSize) {
      chunks.push(text.substring(i, i + chunkSize));
    }
    return chunks;
  }

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
      },
      {
        question: `What methodology or approach is emphasized in this ${examType}?`,
        options: ["Method A", "Method B", "Method C", "Method D"],
        correctAnswer: "Method A",
        points: 1
      },
      {
        question: `Which theory or framework is central to this content?`,
        options: ["Theory X", "Theory Y", "Theory Z", "Theory W"],
        correctAnswer: "Theory X",
        points: 1
      },
      {
        question: `What practical application is highlighted in the material?`,
        options: ["Application 1", "Application 2", "Application 3", "Application 4"],
        correctAnswer: "Application 1",
        points: 1
      },
      {
        question: `What critical thinking skill is developed through this content?`,
        options: ["Skill Alpha", "Skill Beta", "Skill Gamma", "Skill Delta"],
        correctAnswer: "Skill Alpha",
        points: 1
      },
      {
        question: `What real-world scenario is addressed in this educational material?`,
        options: ["Scenario One", "Scenario Two", "Scenario Three", "Scenario Four"],
        correctAnswer: "Scenario One",
        points: 1
      },
      {
        question: `What problem-solving technique is taught in this section?`,
        options: ["Technique P", "Technique Q", "Technique R", "Technique S"],
        correctAnswer: "Technique P",
        points: 1
      },
      {
        question: `What analytical approach is recommended for understanding this content?`,
        options: ["Approach I", "Approach II", "Approach III", "Approach IV"],
        correctAnswer: "Approach I",
        points: 1
      },
      {
        question: `What evaluation criteria are established in this material?`,
        options: ["Criteria 1", "Criteria 2", "Criteria 3", "Criteria 4"],
        correctAnswer: "Criteria 1",
        points: 1
      },
      {
        question: `What learning outcome is expected from mastering this content?`,
        options: ["Outcome X", "Outcome Y", "Outcome Z", "Outcome W"],
        correctAnswer: "Outcome X",
        points: 1
      },
      {
        question: `What foundational knowledge is assumed for this ${examType}?`,
        options: ["Knowledge Base A", "Knowledge Base B", "Knowledge Base C", "Knowledge Base D"],
        correctAnswer: "Knowledge Base A",
        points: 1
      }
    ];
    
    // Generate more questions based on document length - minimum 5, maximum 15
    const questionCount = Math.min(Math.max(Math.floor(documentText.length / 800), 5), 15);
    return templates.slice(0, questionCount).map((template, index) => ({
      id: `template_q_${Date.now()}_${index}`,
      question: template.question,
      options: [...template.options],
      correctAnswer: template.correctAnswer,
      points: template.points
    }));
  }

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
    
    const hash = documentText.split('').reduce((a, b) => {
      a = ((a << 5) - a) + b.charCodeAt(0);
      return a & a;
    }, 0);
    
    const index = Math.abs(hash) % templates.length;
    return templates[index];
  }

  /**
   * Validate and clean up extracted questions
   */
  validateAndCleanQuestions(questions) {
    if (!Array.isArray(questions)) {
      return [];
    }
    
    return questions.map((q, index) => ({
      id: `q_${Date.now()}_${index}`,
      question: q.question || `Question ${index + 1}`,
      options: Array.isArray(q.options) ? q.options.slice(0, 4) : [`Option A`, `Option B`, `Option C`, `Option D`],
      correctAnswer: q.correctAnswer || (q.options ? q.options[0] : "Option A"),
      points: q.points || 1
    })).filter(q => q.question && q.question.length > 5); // Filter out poor quality questions
  }
  
  /**
   * Parse questions from potentially malformed JSON line by line
   */
  parseQuestionsLineByLine(text) {
    const questions = [];
    const lines = text.split('\n');
    
    let currentQuestion = null;
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      
      // Look for question patterns
      if (trimmedLine.includes('question') && trimmedLine.includes('"')) {
        const questionMatch = trimmedLine.match(/"question"\s*:\s*"([^"]+)"/);
        if (questionMatch) {
          if (currentQuestion) {
            questions.push(currentQuestion);
          }
          currentQuestion = {
            question: questionMatch[1],
            options: [],
            correctAnswer: null,
            points: 1
          };
        }
      }
      
      // Look for options
      if (currentQuestion && trimmedLine.includes('options') && trimmedLine.includes('[')) {
        const optionsMatch = trimmedLine.match(/"options"\s*:\s*\[([^\]]+)\]/);
        if (optionsMatch) {
          const optionsText = optionsMatch[1];
          const optionMatches = optionsText.match(/"([^"]+)"/g);
          if (optionMatches) {
            currentQuestion.options = optionMatches.map(opt => opt.replace(/"/g, '')).slice(0, 4);
          }
        }
      }
      
      // Look for correct answer
      if (currentQuestion && trimmedLine.includes('correctAnswer') && trimmedLine.includes('"')) {
        const answerMatch = trimmedLine.match(/"correctAnswer"\s*:\s*"([^"]+)"/);
        if (answerMatch) {
          currentQuestion.correctAnswer = answerMatch[1];
        }
      }
    }
    
    // Add the last question if it exists
    if (currentQuestion) {
      questions.push(currentQuestion);
    }
    
    return questions;
  }
  
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Organize and structure document notes using Groq AI
   * @param {string|Buffer} documentInput - Document text or buffer
   * @param {string} mimeType - MIME type of document
   * @returns {Promise<string>} - Organized notes in markdown format
   */
  async organizeNotes(documentInput, mimeType = 'text/plain') {
    if (!this.isConfigured()) {
      throw new Error("Groq is not configured. Please set GROQ_API_KEY in environment variables.");
    }

    try {
      let documentText;
      
      // Extract text content first
      if (typeof documentInput === 'string') {
        documentText = documentInput;
      } else if (documentInput.buffer) {
        documentText = await this.extractTextFromBuffer(documentInput.buffer, mimeType);
      } else {
        throw new Error("Invalid document input. Must be text string or buffer object.");
      }

      if (!documentText || documentText.trim().length < 50) {
        return "Document content too short to organize.";
      }

      console.log(`Organizing notes from document (first 200 chars): ${documentText.substring(0, 200)}...`);
      
      // Process document in chunks for better organization
      const chunks = this.splitTextIntoChunks(documentText, 6000);
      let organizedContent = [];
      
      for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        console.log(`Organizing chunk ${i + 1}/${chunks.length}...`);
        
        try {
          const chunkContent = await this.organizeChunk(chunk, i + 1, chunks.length);
          organizedContent.push(chunkContent);
          console.log(`✓ Successfully organized chunk ${i + 1}`);
        } catch (chunkError) {
          console.warn(`⚠ Warning: Failed to organize chunk ${i + 1}:`, chunkError.message);
          // Add raw content as fallback
          organizedContent.push(`## Section ${i + 1}
${chunk}
`);
        }
        
        // Small delay between chunks
        if (i < chunks.length - 1) {
          await this.delay(500);
        }
      }

      // Combine all organized content
      const finalContent = organizedContent.join('\n\n');
      
      if (finalContent.trim().length === 0) {
        // Fallback to basic organization
        return this.createBasicOrganization(documentText);
      }
      
      console.log(`Successfully organized notes with ${organizedContent.length} sections`);
      return finalContent;
      
    } catch (error) {
      console.error("Error organizing notes with Groq:", error);
      throw new Error(`Failed to organize notes with Groq: ${error.message}`);
    }
  }

  /**
   * Organize a single chunk of document content
   */
  async organizeChunk(chunk, chunkNumber, totalChunks) {
    const prompt = `Organize and structure this educational content into well-structured, AI-organized notes. Format the response in markdown with proper headings, subheadings, bullet points, and clear organization:

${chunk}

Requirements:
- Use markdown formatting with # for main headings and ## for subheadings
- Organize content into logical sections
- Use bullet points (-) for key points
- Highlight important concepts
- Make it educational and easy to study from
- Keep the original meaning and key information
- Structure it for optimal learning

Return only the organized markdown content without any extra text or explanations.`;

    try {
      const completion = await this.groq.chat.completions.create({
        model: "llama-3.1-8b-instant",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.4,
        max_tokens: 4000
      });

      const response = completion.choices[0].message.content;
      return response.trim();
      
    } catch (error) {
      console.error("Error organizing chunk with Groq:", error);
      throw error;
    }
  }

  /**
   * Create basic organization when AI fails
   */
  createBasicOrganization(documentText) {
    // Simple organization based on common patterns
    const lines = documentText.split('\n').filter(line => line.trim().length > 0);
    
    let organized = '# Course Notes\n\n';
    let currentSection = 1;
    let sectionContent = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Create new section every 10-15 lines or when we detect a topic change
      if (sectionContent.length >= 10 || 
          (line.length > 3 && line === line.toUpperCase()) ||
          (i > 0 && lines[i-1].trim().length === 0 && line.length > 20)) {
        
        if (sectionContent.length > 0) {
          organized += `## Section ${currentSection}\n`;
          organized += sectionContent.map(item => `- ${item}`).join('\n') + '\n\n';
          currentSection++;
          sectionContent = [];
        }
      }
      
      if (line.length > 3) {
        sectionContent.push(line);
      }
    }
    
    // Add remaining content
    if (sectionContent.length > 0) {
      organized += `## Section ${currentSection}\n`;
      organized += sectionContent.map(item => `- ${item}`).join('\n') + '\n';
    }
    
    return organized;
  }
}

module.exports = new GroqService();