const Exam = require('../models/Exam');
const Question = require('../models/Question');
const Result = require('../models/Result');
const Course = require('../models/Course');
const Section = require('../models/Section');
const Enrollment = require('../models/Enrollment');
const GroqService = require('../services/groq_service');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Get all exams for admin
const getAllExams = async (req, res) => {
  try {
    const { courseId, page = 1, limit = 10 } = req.query;
    
    const filter = {};
    if (courseId) filter.courseId = courseId;
    
    const exams = await Exam.find(filter)
      .populate('courseId', 'title')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });
    
    const total = await Exam.countDocuments(filter);
    
    sendSuccess(res, {
      exams,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Exams retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exams', 500, error.message);
  }
};

// Get exam by ID
const getExamById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const exam = await Exam.findById(id)
      .populate('courseId', 'title')
      .populate('sectionId', 'title');
    
    if (!exam) {
      return sendNotFound(res, 'Exam not found');
    }
    
    sendSuccess(res, exam, 'Exam retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exam', 500, error.message);
  }
};

// Update exam
const updateExam = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const exam = await Exam.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).populate('courseId', 'title')
      .populate('sectionId', 'title');
    
    if (!exam) {
      return sendNotFound(res, 'Exam not found');
    }
    
    sendSuccess(res, exam, 'Exam updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update exam', 500, error.message);
  }
};

// Delete exam
const deleteExam = async (req, res) => {
  try {
    const { id } = req.params;
    
    const exam = await Exam.findByIdAndDelete(id);
    
    if (!exam) {
      return sendNotFound(res, 'Exam not found');
    }
    
    // Delete associated questions
    await Question.deleteMany({ examId: id });
    
    sendSuccess(res, null, 'Exam deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete exam', 500, error.message);
  }
};
const getCourseExams = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ userId, courseId });
    if (!enrollment) {
      return sendError(res, 'You must be enrolled in this course to access exams', 403);
    }

    const exams = await Exam.find({ courseId, isPublished: true })
      .select('title type passingScore timeLimit sectionId');

    sendSuccess(res, exams, 'Course exams retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course exams', 500, error.message);
  }
};

// Get exams by section
const getExamsBySection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const userId = req.user.id;

    // Get the section to verify user enrollment
    const section = await Section.findById(sectionId).populate('courseId');
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId: section.courseId._id 
    });
    if (!enrollment) {
      return sendError(res, 'You must be enrolled in this course to access exams', 403);
    }

    const exams = await Exam.find({ 
      sectionId: sectionId, 
      isPublished: true 
    }).select('title type passingScore timeLimit questionsCount attempts');

    sendSuccess(res, exams, 'Section exams retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve section exams', 500, error.message);
  }
};

// Get all exams for a section (admin only - includes unpublished exams)
const getSectionExamsAdmin = async (req, res) => {
  try {
    const { sectionId } = req.params;
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    const exams = await Exam.find({ sectionId: sectionId })
      .populate('courseId', 'title')
      .populate('sectionId', 'title')
      .sort({ createdAt: -1 });
    
    sendSuccess(res, exams, 'Section exams retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve section exams', 500, error.message);
  }
};

// Get exam questions
const getExamQuestions = async (req, res) => {
  try {
    const { examId } = req.params;
    const userId = req.user.id;

    const exam = await Exam.findById(examId);
    if (!exam || !exam.isPublished) {
      return sendNotFound(res, 'Exam not found');
    }

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ userId, courseId: exam.courseId });
    if (!enrollment) {
      return sendError(res, 'You must be enrolled in this course to access exams', 403);
    }

    const questions = await Question.find({ examId })
      .select('question options points');

    sendSuccess(res, { exam, questions }, 'Exam questions retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exam questions', 500, error.message);
  }
};

// Submit exam answers
const submitExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const { answers } = req.body; // Array of { questionId, selectedOption }
    const userId = req.user.id;

    const exam = await Exam.findById(examId);
    if (!exam) {
      return sendNotFound(res, 'Exam not found');
    }

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ userId, courseId: exam.courseId });
    if (!enrollment) {
      return sendError(res, 'You must be enrolled in this course to take this exam', 403);
    }

    // Check if user already submitted this exam
    const existingResult = await Result.findOne({ userId, examId });
    if (existingResult) {
      return sendError(res, 'You have already submitted this exam', 400);
    }

    // Get all questions for this exam
    const questions = await Question.find({ examId });
    
    let score = 0;
    let totalPoints = 0;

    // Calculate score
    for (const userAnswer of answers) {
      const question = questions.find(q => q._id.toString() === userAnswer.questionId);
      if (question) {
        totalPoints += question.points;
        if (question.correctAnswer === userAnswer.selectedOption) {
          score += question.points;
        }
      }
    }

    const percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0;
    const passed = percentage >= exam.passingScore;

    // Save result
    const result = await Result.create({
      userId,
      examId,
      answers,
      score,
      totalPoints,
      percentage,
      passed
    });

    sendSuccess(res, {
      resultId: result._id,
      score,
      totalPoints,
      percentage,
      passed,
      message: passed ? 'Congratulations! You passed the exam.' : 'You did not pass. Please try again.'
    }, 'Exam submitted successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to submit exam', 500, error.message);
  }
};

// Get exam results
const getExamResults = async (req, res) => {
  try {
    const { examId } = req.params;
    const userId = req.user.id;

    const exam = await Exam.findById(examId);
    if (!exam) {
      return sendNotFound(res, 'Exam not found');
    }

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ userId, courseId: exam.courseId });
    if (!enrollment) {
      return sendError(res, 'You must be enrolled in this course to view results', 403);
    }

    const result = await Result.findOne({ userId, examId })
      .populate('examId', 'title type');

    if (!result) {
      return sendNotFound(res, 'No results found for this exam');
    }

    sendSuccess(res, result, 'Exam results retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exam results', 500, error.message);
  }
};

// Get user's exam history
const getUserExamHistory = async (req, res) => {
  try {
    console.log('=== EXAM HISTORY REQUEST ===');
    console.log('User ID from request:', req.user?.id);
    console.log('User role:', req.user?.role);
    console.log('User email:', req.user?.email);
    console.log('Full user object:', JSON.stringify(req.user, null, 2));
    
    const userId = req.user.id;
    
    console.log('Searching for results with userId:', userId);
    const results = await Result.find({ userId })
      .populate({
        path: 'examId',
        select: 'title type courseId sectionId',
        populate: [
          { path: 'courseId', select: 'title' },
          { path: 'sectionId', select: 'title' }
        ]
      })
      .sort({ submittedAt: -1 });
    
    console.log('Found', results.length, 'results for user');
    console.log('Results:', JSON.stringify(results, null, 2));
    
    // Transform the results to match the expected frontend structure
    const formattedResults = results.map(result => ({
      _id: result._id,
      resultId: result._id,
      examId: result.examId,
      score: result.score,
      totalPoints: result.totalPoints,
      percentage: result.percentage,
      passed: result.passed,
      message: result.passed ? 'Passed' : 'Failed',
      submittedAt: result.submittedAt,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt
    }));
    
    sendSuccess(res, formattedResults, 'Exam history retrieved successfully');
  } catch (error) {
    console.error('Error in getUserExamHistory:', error);
    sendError(res, 'Failed to retrieve exam history', 500, error.message);
  }
};

// Create exam (admin only)
const createExam = async (req, res) => {
  try {
    const { courseId, sectionId, title, type, passingScore, timeLimit, questions, documentPath } = req.body;

    // If documentPath is provided, process it with Groq AI to extract questions
    let processedQuestions = questions || [];
    let generatedTitle = title;
    
    if (documentPath) {
      if (GroqService.isConfigured()) {
        try {
          // Read the document content (assuming it's stored in S3 or locally)
          // In a real implementation, you'd fetch the document from storage
          // For now, I'll simulate getting the document content
          
          // For demonstration purposes, I'll create a mock document processing
          // In a real implementation, you would fetch the actual document content
          const documentContent = `Sample document content for ${type} exam. 
            What is the capital of France? A) London B) Paris C) Berlin D) Madrid. 
            What is 2+2? A) 3 B) 4 C) 5 D) 6.`;
          
          // If you have the actual document content from storage, use it
          // Otherwise, generate questions based on the document
          if (documentContent) {
            // Use Groq AI to extract and organize questions from the document
            processedQuestions = await GroqService.extractQuestionsFromDocument(documentContent, type);
            
            // If title wasn't provided, generate one from the document
            if (!generatedTitle) {
              generatedTitle = await GroqService.generateExamTitle(documentContent);
            }
          }
        } catch (aiError) {
          console.error('Error processing document with Groq AI:', aiError);
          // Continue with original questions if AI processing fails
          processedQuestions = questions || [];
        }
      } else {
        // If Groq AI is not configured, return an error if document processing is required
        if (documentPath) {
          return sendError(res, 'Groq AI is not configured. Please set GROQ_API_KEY in environment variables.', 400);
        }
      }
    }

    // Create exam
    const exam = await Exam.create({
      courseId,
      sectionId,
      title: generatedTitle,
      type,
      passingScore,
      timeLimit,
      isPublished: false // Default to unpublished until reviewed
    });

    // Create questions if any exist
    if (processedQuestions && processedQuestions.length > 0) {
      const questionsWithExamId = processedQuestions.map(q => {
        // Find the index of the correct answer in the options
        const correctAnswerIndex = q.options.indexOf(q.correctAnswer);
        
        return {
          question: q.question,
          options: q.options,
          correctAnswer: correctAnswerIndex !== -1 ? correctAnswerIndex : 0, // Store index of correct answer
          points: q.points || 1,
          examId: exam._id
        };
      });
      await Question.insertMany(questionsWithExamId);
    }

    // Update the exam with the question count
    const questionCount = processedQuestions ? processedQuestions.length : 0;
    await Exam.findByIdAndUpdate(exam._id, { 
      questionsCount: questionCount 
    });

    // Fetch the updated exam with question count
    const updatedExam = await Exam.findById(exam._id)
      .populate('courseId', 'title')
      .populate('sectionId', 'title');

    sendSuccess(res, updatedExam, 'Exam created successfully', 201);
  } catch (error) {
    console.error('Error creating exam:', error);
    sendError(res, 'Failed to create exam', 500, error.message);
  }
};

module.exports = {
  getAllExams,
  getExamById,
  updateExam,
  deleteExam,
  getCourseExams,
  getExamsBySection,
  getSectionExamsAdmin,
  getExamQuestions,
  submitExam,
  getExamResults,
  getUserExamHistory,
  createExam
};