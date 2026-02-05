const Exam = require('../models/Exam');
const Question = require('../models/Question');
const Result = require('../models/Result');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
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
      .populate('courseId', 'title');
    
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
    ).populate('courseId', 'title');
    
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
      .select('title type passingScore timeLimit');

    sendSuccess(res, exams, 'Course exams retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course exams', 500, error.message);
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

// Create exam (admin only)
const createExam = async (req, res) => {
  try {
    const { courseId, title, type, passingScore, timeLimit, questions } = req.body;

    // Create exam
    const exam = await Exam.create({
      courseId,
      title,
      type,
      passingScore,
      timeLimit,
      isPublished: false
    });

    // Create questions
    if (questions && questions.length > 0) {
      const questionsWithExamId = questions.map(q => ({
        ...q,
        examId: exam._id
      }));
      await Question.insertMany(questionsWithExamId);
    }

    sendSuccess(res, exam, 'Exam created successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to create exam', 500, error.message);
  }
};

module.exports = {
  getAllExams,
  getExamById,
  updateExam,
  deleteExam,
  getCourseExams,
  getExamQuestions,
  submitExam,
  getExamResults,
  createExam
};