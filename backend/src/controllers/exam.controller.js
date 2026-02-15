const Exam = require('../models/Exam');
const Question = require('../models/Question');
const Result = require('../models/Result');
const Course = require('../models/Course');
const Section = require('../models/Section');
const Enrollment = require('../models/Enrollment');
const GrokService = require('../services/grok_service');
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
      .select('question type options points section');

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
    const existingResults = await Result.find({ userId, examId });
    
    // Get exam details to check type
    const examDetails = await Exam.findById(examId);
    
    // For quiz and pastpaper types, allow retakes
    if (examDetails && (examDetails.type === 'quiz' || examDetails.type === 'pastpaper')) {
      // Allow retake for quiz and pastpaper
      console.log(`Allowing retake for ${examDetails.type} exam for user ${userId}`);
    } else {
      // For final exams and other types, prevent multiple submissions
      if (existingResults.length > 0) {
        return sendError(res, 'You have already submitted this exam', 400);
      }
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
        
        // Handle different question types for grading
        switch (question.type) {
          case 'mcq':
          case 'true_false':
            // Compare against correct answer index (Number)
            if (question.correctAnswer === userAnswer.selectedOption) {
              score += question.points;
            }
            break;
            
          case 'fill_blank':
            // For fill-in-the-blank questions, compare text answers
            if (userAnswer.answerText && question.correctAnswer) {
              const userAnswerText = userAnswer.answerText.toString().trim().toLowerCase();
              const correctAnswerText = question.correctAnswer.toString().trim().toLowerCase();
              if (userAnswerText === correctAnswerText) {
                score += question.points;
              }
            }
            break;
            
          case 'open':
            // For open-ended questions, use AI to evaluate the answer against the correct answer
            // This simulates AI-based grading for open-ended responses
            if (userAnswer.answerText && question.correctAnswer) {
              // In a real implementation, we would use an AI model to compare the semantic similarity
              // For now, we'll use a simplified approach - in production, this would involve calling
              // an AI service to evaluate the quality and accuracy of the response
              
              const userResponse = userAnswer.answerText.toString().toLowerCase().trim();
              const correctResponse = question.correctAnswer.toString().toLowerCase().trim();
              
              // Simple similarity check - in reality, this would use embeddings or LLM evaluation
              const similarity = calculateTextSimilarity(userResponse, correctResponse);
              
              // Award points based on similarity threshold (adjust as needed)
              // For example, award full points if similarity is above 80%
              if (similarity >= 0.8) {
                score += question.points; // Full points for very similar answers
              } else if (similarity >= 0.6) {
                score += Math.round(question.points * 0.5); // Half points for moderately similar
              }
              // Below 60% similarity gets 0 points
            }
            break;
            
          default:
            console.warn(`Unknown question type: ${question.type}`);
        }
      }
    }

    const percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0;
    const passed = percentage >= exam.passingScore;

    // Save result
    const result = await Result.create({
      userId,
      examId,
      answers: answers.map(answer => {
        const question = questions.find(q => q._id.toString() === answer.questionId);
        let earnedPoints = 0;
        
        if (question) {
          // Calculate earned points based on grading logic
          switch (question.type) {
            case 'mcq':
            case 'true_false':
              if (question.correctAnswer === answer.selectedOption) {
                earnedPoints = question.points;
              }
              break;
            
            case 'fill_blank':
              if (answer.answerText && question.correctAnswer) {
                const userAnswerText = answer.answerText.toString().trim().toLowerCase();
                const correctAnswerText = question.correctAnswer.toString().trim().toLowerCase();
                if (userAnswerText === correctAnswerText) {
                  earnedPoints = question.points;
                }
              }
              break;
            
            case 'open':
              // For open-ended questions, use AI to evaluate the answer
              if (answer.answerText && question.correctAnswer) {
                const userResponse = answer.answerText.toString().toLowerCase().trim();
                const correctResponse = question.correctAnswer.toString().toLowerCase().trim();
                
                const similarity = calculateTextSimilarity(userResponse, correctResponse);
                
                if (similarity >= 0.8) {
                  earnedPoints = question.points; // Full points for very similar answers
                } else if (similarity >= 0.6) {
                  earnedPoints = Math.round(question.points * 0.5); // Half points for moderately similar
                }
                // Below 60% similarity gets 0 points
              }
              break;
          }
        }
        
        return {
          questionId: answer.questionId,
          selectedOption: answer.selectedOption,
          answerText: answer.answerText,
          earnedPoints: earnedPoints
        };
      }),
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

    // For quiz and pastpaper types, return the most recent result
    // For other types, return the first (and typically only) result
    const examDetails = await Exam.findById(examId);
    let result;
    
    if (examDetails && (examDetails.type === 'quiz' || examDetails.type === 'pastpaper')) {
      // Return the most recent result for quiz/pastpaper
      const results = await Result.find({ userId, examId })
        .sort({ submittedAt: -1 })
        .populate('examId', 'title type')
        .limit(1);
      result = results.length > 0 ? results[0] : null;
    } else {
      // For final exams, return any result (should be only one)
      result = await Result.findOne({ userId, examId })
        .populate('examId', 'title type');
    }

    if (!result) {
      return sendNotFound(res, 'No results found for this exam');
    }

    sendSuccess(res, result, 'Exam results retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exam results', 500, error.message);
  }
};

// Get user's exam history with detailed question results
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
    
    // Transform the results to include detailed question information
    const formattedResults = await Promise.all(results.map(async (result) => {
      // Only fetch questions if examId exists
      let questions = [];
      let questionResults = [];
      
      if (result.examId) {
        // Get questions for this exam
        questions = await Question.find({ examId: result.examId._id })
          .select('question options correctAnswer points');
        
        // Process each answer to determine if it was correct
        questionResults = result.answers.map(userAnswer => {
          // Use toString() for safer ObjectId comparison
          const question = questions.find(q => q._id.toString() === userAnswer.questionId.toString());
          if (!question) {
            console.log('No matching question found for questionId:', userAnswer.questionId);
            console.log('Available question IDs:', questions.map(q => q._id.toString()));
            return null;
          }
          
          // Determine if the answer was correct
          let isCorrect = false;
          if (question.type === 'mcq' || question.type === 'true_false') {
            // Mirror the same logic as in submitExam
            if (question.correctAnswer === userAnswer.selectedOption) {
              isCorrect = true;
            }
          } else if (question.type === 'fill_blank') {
            // For fill-in-the-blank questions
            if (userAnswer.answerText && question.correctAnswer) {
              const userAnswerText = userAnswer.answerText.toString().trim().toLowerCase();
              const correctAnswerText = question.correctAnswer.toString().trim().toLowerCase();
              isCorrect = userAnswerText === correctAnswerText;
            }
          } else if (question.type === 'open') {
            // For open-ended questions, use AI-based grading result
            // The earnedPoints was already calculated during submission
            isCorrect = userAnswer.earnedPoints > 0;
          } else {
            // Default case for any other question types
            isCorrect = question.correctAnswer === userAnswer.selectedOption;
          }
          
          // Calculate earned points based on the grading result
          let earnedPoints = 0;
          if (question.type === 'mcq' || question.type === 'true_false') {
            earnedPoints = isCorrect ? question.points : 0;
          } else if (question.type === 'fill_blank') {
            earnedPoints = isCorrect ? question.points : 0;
          } else if (question.type === 'open') {
            // For open questions, use the manually assigned points
            earnedPoints = userAnswer.earnedPoints || 0;
          } else {
            earnedPoints = isCorrect ? question.points : 0;
          }
          
          return {
            questionId: userAnswer.questionId,
            questionText: question.question,
            options: question.options,
            type: question.type,
            selectedOption: userAnswer.selectedOption,
            selectedOptionText: (question.type === 'fill_blank' || question.type === 'open') && userAnswer.answerText
              ? userAnswer.answerText
              : (userAnswer.selectedOption !== undefined && question.options.length > 0 && userAnswer.selectedOption < question.options.length
                  ? question.options[userAnswer.selectedOption]
                  : 'No answer provided'),
            correctAnswer: question.correctAnswer,
            correctAnswerText: typeof question.correctAnswer === 'number'
              ? (question.correctAnswer < question.options.length
                  ? question.options[question.correctAnswer]
                  : question.correctAnswer.toString())
              : question.correctAnswer.toString(),
            isCorrect: isCorrect,
            points: question.points,
            earnedPoints: earnedPoints
          };
        }).filter(q => q !== null);
      } else if (result.detailedResults && Array.isArray(result.detailedResults)) {
        // Handle legacy results that already contain detailed results
        questionResults = result.detailedResults.map(detailedResult => {
          // For legacy results, use the existing structure but adapt to new format
          let earnedPoints = detailedResult.pointsEarned;
          if (earnedPoints === undefined && detailedResult.earnedPoints !== undefined) {
            earnedPoints = detailedResult.earnedPoints;
          }
          
          return {
            questionId: detailedResult.questionId,
            questionText: detailedResult.questionText,
            options: detailedResult.options,
            type: detailedResult.type || 'mcq', // Add type for proper handling
            selectedOption: detailedResult.userAnswer !== undefined ? detailedResult.userAnswer : detailedResult.selectedOption,
            selectedOptionText: (detailedResult.type === 'fill_blank' || detailedResult.type === 'open') && detailedResult.answerText
              ? detailedResult.answerText
              : ((detailedResult.userAnswer !== undefined && detailedResult.options.length > 0 && detailedResult.userAnswer < detailedResult.options.length)
                  ? detailedResult.options[detailedResult.userAnswer]
                  : 'No answer provided'),
            correctAnswer: detailedResult.correctAnswer,
            correctAnswerText: typeof detailedResult.correctAnswer === 'number'
              ? (detailedResult.correctAnswer < detailedResult.options.length
                  ? detailedResult.options[detailedResult.correctAnswer]
                  : detailedResult.correctAnswer.toString())
              : detailedResult.correctAnswer.toString(),
            isCorrect: detailedResult.earnedPoints > 0,
            points: detailedResult.pointsPossible !== undefined ? detailedResult.pointsPossible : detailedResult.points,
            earnedPoints: earnedPoints
          };
        });
      }
      
      // Calculate statistics
      const totalQuestions = questionResults.length;
      const correctAnswers = questionResults.filter(q => q.isCorrect).length;
      const incorrectAnswers = totalQuestions - correctAnswers;
      
      return {
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
        updatedAt: result.updatedAt,
        // Detailed question results
        questions: questionResults,
        statistics: {
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          accuracy: totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0
        }
      };
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
      if (GrokService.isConfigured()) {
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
            processedQuestions = await GrokService.extractQuestionsFromDocument(documentContent, type);
            
            // If title wasn't provided, generate one from the document
            if (!generatedTitle) {
              generatedTitle = await GrokService.generateExamTitle(documentContent);
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
        // Handle both MCQ and open questions
        let correctAnswer = q.correctAnswer;
        if (q.type === 'mcq' && q.options && q.correctAnswer) {
          // For MCQ questions, convert correct answer to index if it's the actual answer text
          const correctAnswerIndex = q.options.indexOf(q.correctAnswer);
          correctAnswer = correctAnswerIndex !== -1 ? correctAnswerIndex : 0;
        }
        
        return {
          question: q.question,
          type: q.type || 'mcq',
          options: q.options || [],
          correctAnswer: correctAnswer,
          points: q.points || 1,
          section: q.section || null,
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

// Helper function to calculate text similarity (simplified approach)
function calculateTextSimilarity(str1, str2) {
  // Convert to lowercase and remove extra spaces
  str1 = str1.toLowerCase().trim();
  str2 = str2.toLowerCase().trim();
  
  // If exact match, return 1.0
  if (str1 === str2) {
    return 1.0;
  }
  
  // Split into words
  const words1 = str1.split(/\s+/).filter(w => w.length > 0);
  const words2 = str2.split(/\s+/).filter(w => w.length > 0);
  
  // Calculate intersection and union for Jaccard similarity
  const set1 = new Set(words1);
  const set2 = new Set(words2);
  
  const intersection = [...set1].filter(x => set2.has(x)).length;
  const union = new Set([...words1, ...words2]).size;
  
  return union > 0 ? intersection / union : 0;
}

// Remove the manual grading functions and implement proper automatic grading for open questions

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