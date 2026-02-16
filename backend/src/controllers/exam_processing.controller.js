const Exam = require('../models/Exam');
const Question = require('../models/Question');
const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const GrokService = require('../services/grok_service');
const S3Service = require('../services/s3.service');
const DocumentProcessingService = require('../services/document_processing_service');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

/**
 * Create lesson from uploaded document using AI processing for notes organization
 * @route POST /api/documents/upload-for-notes
 */
const createLessonFromDocument = async (req, res) => {
  try {
    const { courseId, sectionId, title, description, duration } = req.body;
    
    // Validate required fields
    if (!courseId || !sectionId) {
      return sendError(res, 'Course ID and Section ID are required', 400);
    }

    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }

    // Check if file was uploaded
    if (!req.file) {
      return sendError(res, 'No document file provided', 400);
    }

    console.log('Creating lesson from document:', {
      courseId,
      sectionId,
      fileName: req.file.originalname,
      fileSize: req.file.size
    });

    try {
      // Step 1: Upload document to S3 first (asynchronous processing requirement)
      console.log('Uploading document to S3...');
      const uploadResult = await S3Service.uploadDocument(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype
      );

      // Step 2: Process with Grok AI to organize notes
      let organizedNotes = '';
      if (GrokService.isConfigured()) {
        console.log('Organizing notes with Grok AI...');
        
        const fileForAI = {
          buffer: req.file.buffer,
          mimetype: req.file.mimetype,
          originalName: req.file.originalname
        };

        organizedNotes = await GrokService.organizeNotes(fileForAI, req.file.mimetype);
        console.log('Notes organized successfully with Grok AI');
      } else {
        // Fallback to extracted text content
        const documentContent = await DocumentProcessingService.extractTextFromDocument(
          req.file.buffer,
          req.file.mimetype
        );
        organizedNotes = documentContent || 'Notes content will be organized when AI is configured.';
        console.log('Using extracted text content as fallback');
      }

      // Step 3: Create lesson with organized notes
      const order = await Lesson.countDocuments({ sectionId: sectionId }) + 1;
      
      const lesson = await Lesson.create({
        sectionId: sectionId,
        courseId: courseId,
        title: title || req.file.originalname.split('.')[0],
        description: description,
        videoId: null,
        notes: organizedNotes,
        status: 'completed',
        order: order,
        duration: parseInt(duration) || 0
      });

      // Send success response
      return sendSuccess(res, {
        lesson: lesson,
        documentUrl: uploadResult.url,
        s3Key: uploadResult.key
      }, 'Lesson created successfully with organized notes from document');
    } catch (processingError) {
      console.error('Error processing document for lesson:', processingError);
      return sendError(res, 'Failed to process document for lesson: ' + processingError.message, 500);
    }
  } catch (error) {
    console.error('Error creating lesson from document:', error);
    sendError(res, 'Failed to create lesson from document', 500, error.message);
  }
};

/**
 * Create exam from uploaded document using AI processing
 * @route POST /api/documents/upload-for-exam
 * @route POST /api/exams/create-from-document
 */
const createExamFromDocument = async (req, res) => {
  try {
    const { courseId, sectionId, examType, title, passingScore, timeLimit } = req.body;
    
    // Validate required fields
    if (!courseId || !sectionId || !examType) {
      return sendError(res, 'Course ID, Section ID, and Exam Type are required', 400);
    }

    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }

    // Check if file was uploaded
    if (!req.file) {
      return sendError(res, 'No document file provided', 400);
    }

    console.log('Creating exam from document:', {
      courseId,
      sectionId,
      examType,
      fileName: req.file.originalname,
      fileSize: req.file.size
    });

    try {
      // Step 1: Upload document to S3 first (asynchronous processing requirement)
      console.log('Uploading document to S3...');
      const uploadResult = await S3Service.uploadDocument(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype
      );

      // Step 2: Extract text content from document
      console.log('Extracting text content from document...');
      const documentContent = await DocumentProcessingService.extractTextFromDocument(
        req.file.buffer,
        req.file.mimetype
      );

      // Step 3: Process with Grok AI to extract questions
      if (GrokService.isConfigured()) {
        console.log('Processing document with Grok AI...');
        
        const fileForAI = {
          buffer: req.file.buffer,
          mimetype: req.file.mimetype,
          originalName: req.file.originalname
        };

        const processedQuestions = await GrokService.extractQuestionsFromDocument(
          fileForAI,
          examType
        );

        // Generate exam title if not provided
        let examTitle = title || '';
        if (!examTitle) {
          examTitle = await GrokService.generateExamTitle(documentContent);
        }

        // Create exam with extracted questions
        console.log(`Creating exam with ${processedQuestions.length} questions...`);
        const exam = await Exam.create({
          courseId: courseId,
          sectionId: sectionId,
          title: examTitle,
          type: examType,
          passingScore: passingScore || 50,
          timeLimit: timeLimit || 0,
          isPublished: false,
          questionsCount: processedQuestions.length
        });

        // Create questions from AI-processed content
        if (processedQuestions && processedQuestions.length > 0) {
          const questionsWithExamId = processedQuestions.map(q => {
            // Handle different question types properly
            let correctAnswer = q.correctAnswer;
            let options = q.options || [];
            
            // For MCQ and True/False, convert correct answer to index
            if ((q.type === 'MULTIPLE_CHOICE' || q.type === 'TRUE_FALSE') && options.length > 0) {
              const correctAnswerIndex = options.indexOf(q.correctAnswer);
              correctAnswer = correctAnswerIndex !== -1 ? correctAnswerIndex : 0;
            }
            
            // Handle missing correctAnswer for different question types
            if (!correctAnswer) {
              if (q.type === 'MULTIPLE_CHOICE' || q.type === 'TRUE_FALSE') {
                // For MCQ/TrueFalse, use first option as default or provide sample answer
                correctAnswer = options.length > 0 ? 0 : 'Sample answer';
              } else if (q.type === 'FILL_BLANK') {
                // For fill-in-the-blank, provide a sample answer
                correctAnswer = 'Sample answer';
              } else if (q.type === 'OPEN_ENDED') {
                // For open-ended questions, provide sample answer or leave as placeholder
                correctAnswer = 'Sample answer';
              } else {
                // Default fallback
                correctAnswer = 'Sample answer';
              }
            }
            
            // Truncate question if it exceeds 1000 characters
            let questionText = q.question;
            if (questionText && questionText.length > 1000) {
              questionText = questionText.substring(0, 997) + '...';
              console.log(`Truncated long question to fit within 1000 character limit`);
            }
            
            return {
              question: questionText,
              type: mapQuestionType(q.type),
              options: options,
              correctAnswer: correctAnswer,
              points: q.points || 1,
              examId: exam._id
            };
          });
          
          await Question.insertMany(questionsWithExamId);
          console.log(`Created ${questionsWithExamId.length} questions for exam ${exam._id}`);
        }

        // Send success response
        return sendSuccess(res, {
          exam: exam,
          questionsCount: processedQuestions.length,
          documentUrl: uploadResult.url,
          s3Key: uploadResult.key
        }, 'Exam created successfully from document');
      } else {
        return sendError(res, 'Grok AI is not configured. Please set GROQ_API_KEY in environment variables.', 400);
      }
    } catch (aiError) {
      console.error('Error processing document with AI:', aiError);
      return sendError(res, 'Failed to process document with AI: ' + aiError.message, 500);
    }
  } catch (error) {
    console.error('Error creating exam from document:', error);
    sendError(res, 'Failed to create exam from document', 500, error.message);
  }
};

/**
 * Process existing document for exam creation
 * @route POST /api/exams/process-document/:documentKey
 */
const processExistingDocument = async (req, res) => {
  try {
    const { documentKey } = req.params;
    const { courseId, sectionId, examType, title, passingScore, timeLimit } = req.body;

    // Validate required fields
    if (!courseId || !sectionId || !examType || !documentKey) {
      return sendError(res, 'Course ID, Section ID, Exam Type, and Document Key are required', 400);
    }

    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }

    console.log('Processing existing document for exam:', {
      documentKey,
      courseId,
      sectionId,
      examType
    });

    try {
      // Fetch document from S3
      console.log('Fetching document from S3...');
      const documentBuffer = await S3Service.getFileBuffer(documentKey);
      
      if (!documentBuffer) {
        return sendError(res, 'Document not found in storage', 404);
      }

      // Extract text content
      console.log('Extracting text content...');
      // Determine MIME type from key
      let mimeType = 'application/pdf';
      if (documentKey.toLowerCase().includes('.docx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (documentKey.toLowerCase().includes('.txt')) {
        mimeType = 'text/plain';
      }

      const documentContent = await DocumentProcessingService.extractTextFromDocument(
        documentBuffer,
        mimeType
      );

      // Process with Grok AI
      if (GrokService.isConfigured()) {
        console.log('Processing with Grok AI...');
        
        const fileForAI = {
          buffer: documentBuffer,
          mimetype: mimeType,
          originalName: documentKey.split('/').pop()
        };

        const processedQuestions = await GrokService.extractQuestionsFromDocument(
          fileForAI,
          examType
        );

        // Generate exam title if not provided
        let examTitle = title || '';
        if (!examTitle) {
          examTitle = await GrokService.generateExamTitle(documentContent);
        }

        // Create exam
        console.log(`Creating exam with ${processedQuestions.length} questions...`);
        const exam = await Exam.create({
          courseId: courseId,
          sectionId: sectionId,
          title: examTitle,
          type: examType,
          passingScore: passingScore || 50,
          timeLimit: timeLimit || 0,
          isPublished: false,
          questionsCount: processedQuestions.length
        });

        // Create questions
        if (processedQuestions && processedQuestions.length > 0) {
          const questionsWithExamId = processedQuestions.map(q => {
            // Handle missing correctAnswer for different question types
            let correctAnswer = q.correctAnswer;
            
            if (!correctAnswer) {
              if (q.type === 'MULTIPLE_CHOICE' || q.type === 'TRUE_FALSE') {
                // For MCQ/TrueFalse, use first option as default or provide sample answer
                correctAnswer = (q.options && q.options.length > 0) ? 0 : 'Sample answer';
              } else if (q.type === 'FILL_BLANK') {
                // For fill-in-the-blank, provide a sample answer
                correctAnswer = 'Sample answer';
              } else if (q.type === 'OPEN_ENDED') {
                // For open-ended questions, provide sample answer or leave as placeholder
                correctAnswer = 'Sample answer';
              } else {
                // Default fallback
                correctAnswer = 'Sample answer';
              }
            }
            
            return {
              question: q.question,
              type: mapQuestionType(q.type),
              options: q.options || [],
              correctAnswer: correctAnswer,
              points: q.points || 1,
              examId: exam._id
            };
          });
          
          await Question.insertMany(questionsWithExamId);
        }

        return sendSuccess(res, {
          exam: exam,
          questionsCount: processedQuestions.length
        }, 'Exam processed successfully from existing document');
      } else {
        return sendError(res, 'Grok AI is not configured', 400);
      }
    } catch (processingError) {
      console.error('Error processing existing document:', processingError);
      return sendError(res, 'Failed to process document: ' + processingError.message, 500);
    }
  } catch (error) {
    console.error('Error processing existing document:', error);
    sendError(res, 'Failed to process existing document', 500, error.message);
  }
};

/**
 * Get exam processing status
 * @route GET /api/exams/processing-status/:examId
 */
const getProcessingStatus = async (req, res) => {
  try {
    const { examId } = req.params;
    
    const exam = await Exam.findById(examId);
    if (!exam) {
      return sendNotFound(res, 'Exam not found');
    }

    const questions = await Question.find({ examId: examId });
    
    return sendSuccess(res, {
      exam: exam,
      questionsCount: questions.length,
      processingComplete: exam.status === 'published' || questions.length > 0,
      createdAt: exam.createdAt,
      updatedAt: exam.updatedAt
    });
  } catch (error) {
    console.error('Error getting processing status:', error);
    sendError(res, 'Failed to get processing status', 500, error.message);
  }
};

// Helper method to map AI question types to our enum values
function mapQuestionType(aiType) {
  const typeMap = {
    'MULTIPLE_CHOICE': 'mcq'
  };
  
  return typeMap[aiType] || 'mcq'; // Only return mcq since other types are filtered out
}

module.exports = {
  createLessonFromDocument,
  createExamFromDocument,
  processExistingDocument,
  getProcessingStatus,
  mapQuestionType
};