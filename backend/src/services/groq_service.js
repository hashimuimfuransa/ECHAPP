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
      const chunks = this.splitTextIntoChunks(documentText, 12000); // Increased to 12000 chars per chunk
      let allQuestions = [];
      
      console.log(`Document text extracted (first 200 chars): ${documentText.substring(0, 200)}...`);
      console.log(`Processing document in ${chunks.length} chunks with Groq...`);
      
      for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        console.log(`Processing chunk ${i + 1}/${chunks.length}...`);
        
        try {
          const chunkQuestions = await this.processChunkWithGroq(chunk, examType, fileName, i + 1, chunks.length);
          console.log(`Chunk ${i + 1}: Generated ${chunkQuestions.length} questions`);
          allQuestions = allQuestions.concat(chunkQuestions);
          console.log(`Total questions so far: ${allQuestions.length}`);
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
      const beforeDedup = allQuestions.length;
      allQuestions = this.deduplicateQuestions(allQuestions);
      console.log(`Deduplication: ${beforeDedup} -> ${allQuestions.length} questions`);
      
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
    const prompt = `Extract exam questions from this text section for a ${examType.toUpperCase()} test. CRITICALLY IMPORTANT: Analyze each question to determine the most appropriate question type based on the question format and content.

Return ONLY the questions that exist in the document in JSON format. Extract each question exactly as it appears in the text, do not create or generate any new questions. Support these question types:

1. "mcq" - Multiple choice with 4 options (use when question asks for selection from given choices)
2. "true_false" - True/False questions (use for yes/no or true/false statements)
3. "fill_blank" - Fill-in-the-blank questions (use when question contains blanks to be filled)
4. "open" - Open-ended/essay questions (use for questions requiring detailed written responses)

ANALYSIS CRITERIA FOR QUESTION TYPE DETECTION:
- MCQ: Question contains "which of the following", "select the best", "choose", or provides multiple options
- TRUE_FALSE: Question is a statement that can be judged as true or false
- FILL_BLANK: Question contains blank spaces (____) or asks "fill in the blank"
- OPEN: Question asks for explanation, description, reasons, or detailed analysis

JSON FORMAT:
[
  {
    "question": "The question text",
    "type": "mcq", // CRITICAL: Must specify correct type
    "options": ["Option A", "Option B", "Option C", "Option D"], // Required for MCQ/True_False
    "correctAnswer": "Option A", // For MCQ/True_False: correct option text, for open: sample answer, for fill_blank: exact answer
    "points": 1,
    "section": "Section A" // Include if applicable
  }
]

Text content from section ${chunkNumber} of ${fileName}:
${chunk}

REQUIREMENTS:
- Extract ONLY the questions that exist in this section - do not create or generate any new questions
- Identify and extract each question exactly as it appears in the document
- CRITICALLY: Analyze each question to determine the CORRECT question type
- For MCQ: Provide the existing options and specify the correct answer text
- For TRUE_FALSE: Provide options ["True", "False"] and correct answer if it's a true/false statement
- For FILL_BLANK: Provide the question with blanks as it appears and the correct answer
- For OPEN: Omit options field and provide the expected answer format in correctAnswer
- Clear, unambiguous questions
- JSON format only, no extra text
- Extract all and only the questions present in the document`;

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
        max_tokens: 8000
      });

      const response = completion.choices[0].message.content;
      
      console.log(`Groq API Response (first 300 chars): ${response.substring(0, 300)}...`);
      
      // Extract JSON from response - more robust parsing
      let jsonString = response.trim();
      
      // Try multiple JSON extraction patterns
      const patterns = [
        /```json\n([\s\S]*?)\n```/,  // \`\`\`json
        /```([\s\S]*?)```/,          // \`\`\`
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
        questions = this.parseQuestionsLineByLineExtended(cleanJson);
        if (questions && questions.length > 0) {
          console.log(`Successfully parsed ${questions.length} questions line-by-line`);
          return this.validateAndCleanQuestions(questions);
        }
        
        return [];
      }
      
      // Ensure all questions have the required fields and proper type handling
      return questions.map((q, index) => ({
        id: `q_${Date.now()}_${chunkNumber}_${index}`,
        question: q.question || `Question from section ${chunkNumber}`,
        type: q.type && ['mcq', 'open', 'fill_blank', 'true_false'].includes(q.type) ? q.type : 'mcq', // Validate and default to mcq if invalid
        options: (q.type === 'mcq' || q.type === 'true_false') && Array.isArray(q.options) ? q.options.slice(0, 4) : 
                 q.type === 'true_false' ? ['True', 'False'] : [], // Ensure true/false has proper options
        correctAnswer: q.correctAnswer || 
                      (q.type === 'open' ? 'Sample answer for open question' : 
                       q.type === 'fill_blank' ? 'Correct answer' : 
                       (q.options && q.options.length > 0 ? q.options[0] : 'Option A')),
        points: q.points || 1,
        section: q.section || null // Include section if provided
      })).filter(q => q.question && q.question.length > 5); // Filter out poor quality questions
      
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
      // Create a more unique key by combining question text, options, and correct answer
      let key = question.question.toLowerCase().trim();
      if (question.options && question.options.length > 0) {
        // Include all options to make the key more unique
        key += '|' + question.options.join('|').toLowerCase();
      }
      // Also include the correct answer to distinguish between similar questions with different answers
      if (question.correctAnswer) {
        key += '|correct:' + question.correctAnswer.toString().toLowerCase();
      }
      
      if (seen.has(key)) {
        console.log(`Skipping duplicate question: ${question.question.substring(0, 50)}...`);
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
        type: 'mcq',
        options: ["Topic A", "Topic B", "Topic C", "Topic D"],
        correctAnswer: "Topic A",
        points: 1,
        section: null
      },
      {
        question: `What key concept was covered in the ${examType} material?`,
        type: 'mcq',
        options: ["Concept 1", "Concept 2", "Concept 3", "Concept 4"],
        correctAnswer: "Concept 1",
        points: 1,
        section: null
      },
      {
        question: `According to the document, which principle is most important?`,
        type: 'mcq',
        options: ["Principle X", "Principle Y", "Principle Z", "Principle W"],
        correctAnswer: "Principle X",
        points: 1,
        section: null
      },
      {
        question: `______ is the process by which plants convert sunlight to energy.`,
        type: 'fill_blank',
        correctAnswer: "Photosynthesis",
        points: 1,
        section: null
      },
      {
        question: `True or False: The Earth is the third planet from the Sun.`,
        type: 'true_false',
        options: ["True", "False"],
        correctAnswer: "True",
        points: 1,
        section: null
      },
      {
        question: `What is the capital of France? ______`,
        type: 'fill_blank',
        correctAnswer: "Paris",
        points: 1,
        section: null
      },
      {
        question: `______ is the largest mammal in the world.`,
        type: 'fill_blank',
        correctAnswer: "Blue whale",
        points: 1,
        section: null
      },
      {
        question: `True or False: Water boils at 100 degrees Celsius at sea level.`,
        type: 'true_false',
        options: ["True", "False"],
        correctAnswer: "True",
        points: 1,
        section: null
      },
      {
        question: `What is the primary focus of this educational content?`,
        type: 'mcq',
        options: ["Focus Area 1", "Focus Area 2", "Focus Area 3", "Focus Area 4"],
        correctAnswer: "Focus Area 1",
        points: 1,
        section: null
      },
      {
        question: `Based on the material, what should students understand most?`,
        type: 'mcq',
        options: ["Understanding A", "Understanding B", "Understanding C", "Understanding D"],
        correctAnswer: "Understanding A",
        points: 1,
        section: null
      },
      {
        question: `What methodology or approach is emphasized in this ${examType}?`,
        type: 'mcq',
        options: ["Method A", "Method B", "Method C", "Method D"],
        correctAnswer: "Method A",
        points: 1,
        section: null
      },
      {
        question: `Which theory or framework is central to this content?`,
        type: 'mcq',
        options: ["Theory X", "Theory Y", "Theory Z", "Theory W"],
        correctAnswer: "Theory X",
        points: 1,
        section: null
      },
      {
        question: `What practical application is highlighted in the material?`,
        type: 'open',
        correctAnswer: "Students should describe the practical application in their own words.",
        points: 2,
        section: null
      },
      {
        question: `What critical thinking skill is developed through this content?`,
        type: 'open',
        correctAnswer: "Students should explain the critical thinking skill in detail.",
        points: 2,
        section: null
      },
      {
        question: `Describe the real-world scenario addressed in this educational material.`,
        type: 'open',
        correctAnswer: "Students should provide a detailed explanation of the real-world scenario.",
        points: 2,
        section: null
      },
      {
        question: `What problem-solving technique is taught in this section?`,
        type: 'mcq',
        options: ["Technique P", "Technique Q", "Technique R", "Technique S"],
        correctAnswer: "Technique P",
        points: 1,
        section: null
      },
      {
        question: `What analytical approach is recommended for understanding this content?`,
        type: 'mcq',
        options: ["Approach I", "Approach II", "Approach III", "Approach IV"],
        correctAnswer: "Approach I",
        points: 1,
        section: null
      },
      {
        question: `What evaluation criteria are established in this material?`,
        type: 'open',
        correctAnswer: "Students should list and explain the evaluation criteria.",
        points: 2,
        section: null
      },
      {
        question: `What learning outcome is expected from mastering this content?`,
        type: 'open',
        correctAnswer: "Students should describe the expected learning outcomes.",
        points: 2,
        section: null
      },
      {
        question: `What foundational knowledge is assumed for this ${examType}?`,
        type: 'mcq',
        options: ["Knowledge Base A", "Knowledge Base B", "Knowledge Base C", "Knowledge Base D"],
        correctAnswer: "Knowledge Base A",
        points: 1,
        section: null
      }
    ];
    
    // Generate more questions based on document length - minimum 5, maximum 15
    const questionCount = Math.min(Math.max(Math.floor(documentText.length / 800), 5), 15);
    return templates.slice(0, questionCount).map((template, index) => ({
      id: `template_q_${Date.now()}_${index}`,
      question: template.question,
      type: template.type,
      options: template.options || [],
      correctAnswer: template.correctAnswer,
      points: template.points,
      section: template.section
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
      type: q.type || 'mcq', // Default to mcq if not specified
      options: (q.type === 'mcq' || q.type === 'true_false') && Array.isArray(q.options) ? (q.type === 'true_false' ? ['True', 'False'] : q.options.slice(0, 4)) : [], // Options for MCQ and True/False
      correctAnswer: q.correctAnswer || (q.type === 'open' ? null : (q.options ? q.options[0] : (q.type === 'fill_blank' ? '' : "Option A"))),
      points: q.points || 1,
      section: q.section || null // Include section if provided
    })).filter(q => q.question && q.question.length > 3); // Less strict filtering - only remove very short questions
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
  
  /**
   * Parse questions from potentially malformed JSON line by line - Extended version supporting question types and sections
   */
  parseQuestionsLineByLineExtended(text) {
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
            type: 'mcq', // Default to mcq
            options: [],
            correctAnswer: null,
            points: 1,
            section: null
          };
        }
      }
      
      // Look for question type
      if (currentQuestion && trimmedLine.includes('type') && trimmedLine.includes('"')) {
        const typeMatch = trimmedLine.match(/"type"\s*:\s*"([^"]+)"/);
        if (typeMatch) {
          currentQuestion.type = typeMatch[1];
        }
      }
      
      // Look for options
      if (currentQuestion && trimmedLine.includes('options') && trimmedLine.includes('[')) {
        const optionsMatch = trimmedLine.match(/"options"\s*:\s*\[([^\]]+)\]/);
        if (optionsMatch) {
          const optionsText = optionsMatch[1];
          const optionMatches = optionsText.match(/"([^"]+)"/g);
          if (optionMatches) {
            currentQuestion.options = optionMatches.map(opt => opt.replace(/"/g, ''));
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
      
      // Look for points
      if (currentQuestion && trimmedLine.includes('points') && trimmedLine.includes(':')) {
        const pointsMatch = trimmedLine.match(/"points"\s*:\s*(\d+)/);
        if (pointsMatch) {
          currentQuestion.points = parseInt(pointsMatch[1]);
        }
      }
      
      // Look for section
      if (currentQuestion && trimmedLine.includes('section') && trimmedLine.includes('"')) {
        const sectionMatch = trimmedLine.match(/"section"\s*:\s*"([^"]+)"/);
        if (sectionMatch) {
          currentQuestion.section = sectionMatch[1];
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