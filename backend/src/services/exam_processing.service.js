const GrokService = require('./grok_service');
const S3Service = require('./s3.service');
const DocumentProcessingService = require('./document_processing_service');

class ExamProcessingService {
  /**
   * Process document and create exam with questions
   * @param {Buffer} documentBuffer - The document file buffer
   * @param {string} mimeType - MIME type of the document
   * @param {string} originalName - Original filename
   * @param {Object} examData - Exam creation data
   * @returns {Promise<Object>} - Processing result
   */
  async processDocumentForExam(documentBuffer, mimeType, originalName, examData) {
    try {
      console.log('Starting document processing for exam creation:', {
        fileName: originalName,
        mimeType: mimeType,
        examType: examData.examType
      });

      // Step 1: Upload to S3 (non-blocking as per specification)
      console.log('Uploading document to S3...');
      const s3Result = await S3Service.uploadDocument(documentBuffer, originalName, mimeType);
      
      // Step 2: Extract text content
      console.log('Extracting text content from document...');
      const documentContent = await DocumentProcessingService.extractTextFromDocument(
        documentBuffer,
        mimeType
      );

      // Step 3: Process with AI (asynchronous background processing)
      let processedQuestions = [];
      let generatedTitle = examData.title;
      
      if (GrokService.isConfigured()) {
        console.log('Processing document with Grok AI...');
        
        const fileForAI = {
          buffer: documentBuffer,
          mimetype: mimeType,
          originalName: originalName
        };

        processedQuestions = await GrokService.extractQuestionsFromDocument(
          fileForAI,
          examData.examType
        );

        // Generate title if not provided
        if (!generatedTitle) {
          generatedTitle = await GrokService.generateExamTitle(documentContent);
        }
      } else {
        console.warn('Grok AI not configured, using template questions');
        processedQuestions = this.generateTemplateQuestions(documentContent, examData.examType, originalName);
        if (!generatedTitle) {
          generatedTitle = this.generateTemplateTitle(originalName);
        }
      }
      
      // Additional filtering to ensure only MCQ and True/False questions
      processedQuestions = this.filterExamQuestions(processedQuestions);
      console.log(`Questions after final filtering: ${processedQuestions.length} questions (MCQ + True/False only)`);

      console.log(`Document processing complete. Generated ${processedQuestions.length} questions.`);

      return {
        success: true,
        s3Key: s3Result.key,
        documentUrl: s3Result.url,
        questions: processedQuestions,
        title: generatedTitle,
        processingTime: Date.now()
      };
    } catch (error) {
      console.error('Error processing document for exam:', error);
      throw new Error(`Failed to process document: ${error.message}`);
    }
  }

  /**
   * Process existing S3 document for exam creation
   * @param {string} s3Key - S3 key of the document
   * @param {Object} examData - Exam creation data
   * @returns {Promise<Object>} - Processing result
   */
  async processExistingDocument(s3Key, examData) {
    try {
      console.log('Processing existing document from S3:', s3Key);

      // Fetch document from S3
      const documentBuffer = await S3Service.getFileBuffer(s3Key);
      if (!documentBuffer) {
        throw new Error('Document not found in storage');
      }

      // Determine MIME type
      let mimeType = 'application/pdf';
      if (s3Key.toLowerCase().includes('.docx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (s3Key.toLowerCase().includes('.txt')) {
        mimeType = 'text/plain';
      }

      const fileName = s3Key.split('/').pop();
      
      return await this.processDocumentForExam(documentBuffer, mimeType, fileName, examData);
    } catch (error) {
      console.error('Error processing existing document:', error);
      throw new Error(`Failed to process existing document: ${error.message}`);
    }
  }

  /**
   * Organize lesson notes using AI
   * @param {Buffer} documentBuffer - The document file buffer
   * @param {string} mimeType - MIME type of the document
   * @param {string} originalName - Original filename
   * @returns {Promise<string>} - Organized notes content
   */
  async organizeLessonNotes(documentBuffer, mimeType, originalName) {
    try {
      console.log('Organizing lesson notes with AI:', originalName);

      if (GrokService.isConfigured()) {
        const fileForAI = {
          buffer: documentBuffer,
          mimetype: mimeType,
          originalName: originalName
        };

        const organizedNotes = await GrokService.organizeNotes(fileForAI, mimeType);
        console.log('Notes organized successfully');
        return organizedNotes;
      } else {
        console.warn('Grok AI not configured, returning original content');
        const textContent = await DocumentProcessingService.extractTextFromDocument(documentBuffer, mimeType);
        return textContent || 'Notes content will be organized when AI is configured.';
      }
    } catch (error) {
      console.error('Error organizing lesson notes:', error);
      throw new Error(`Failed to organize notes: ${error.message}`);
    }
  }

  /**
   * Generate template questions when AI is not available
   */
  generateTemplateQuestions(documentContent, examType, fileName) {
    const subject = this.extractSubjectFromFile(fileName) || 'General';
    
    return [
      {
        question: `What is the main topic covered in this ${subject} ${examType}?`,
        type: 'mcq',
        options: [`Main ${subject} concepts`, `Advanced ${subject} topics`, `Basic ${subject} principles`, `Intermediate ${subject} skills`],
        correctAnswer: `Main ${subject} concepts`,
        points: 1
      },
      {
        question: `The content covers essential ${subject} knowledge.`,
        type: 'true_false',
        options: ['True', 'False'],
        correctAnswer: 'True',
        points: 1
      },
      {
        question: `Which of the following is a key principle in ${subject}?`,
        type: 'mcq',
        options: [`Fundamental concept`, `Advanced theory`, `Basic principle`, `Intermediate skill`],
        correctAnswer: `Fundamental concept`,
        points: 1
      }
    ];
  }

  /**
   * Generate template title
   */
  generateTemplateTitle(fileName) {
    const subject = this.extractSubjectFromFile(fileName) || 'Subject';
    return `${subject} Assessment`;
  }

  /**
   * Extract subject from filename
   */
  extractSubjectFromFile(fileName) {
    const subjects = ['Math', 'Science', 'History', 'Literature', 'Programming', 'Business', 'Physics', 'Chemistry'];
    const lowerName = fileName.toLowerCase();
    
    for (const subject of subjects) {
      if (lowerName.includes(subject.toLowerCase())) {
        return subject;
      }
    }
    
    return null;
  }

  /**
   * Validate exam processing result
   */
  filterExamQuestions(questions) {
    // Only allow MCQ questions - filter out all other question types
    
    const validTypes = ['MULTIPLE_CHOICE', 'mcq'];
    
    const filtered = questions.filter(question => {
      // Validate basic question structure
      if (!question.question || typeof question.question !== 'string') {
        console.log(`Filtering out question with invalid question text`);
        return false;
      }
      
      const questionType = (question.type || '').toUpperCase();
      const isValidType = validTypes.some(allowed => 
        questionType === allowed.toUpperCase()
      );
      
      if (!isValidType) {
        console.log(`Filtering out non-MCQ question type: ${question.type}`);
        return false;
      }
      
      // MCQ questions need options
      if (questionType === 'MULTIPLE_CHOICE' || questionType === 'MCQ') {
        // MCQ questions need options
        if (!Array.isArray(question.options) || question.options.length < 2) {
          console.log(`Filtering MCQ with insufficient options:`, question);
          return false;
        }
      }
      
      return true;
    });
    
    console.log(`Filtered exam questions: ${filtered.length} MCQ questions from ${questions.length} total (non-MCQ removed)`);
    return filtered;
  }

  validateProcessingResult(result) {
    if (!result.success) {
      throw new Error('Processing failed');
    }
    
    if (!result.s3Key) {
      throw new Error('S3 key missing from processing result');
    }
    
    if (!Array.isArray(result.questions)) {
      throw new Error('Questions must be an array');
    }
    
    return true;
  }
}

module.exports = new ExamProcessingService();