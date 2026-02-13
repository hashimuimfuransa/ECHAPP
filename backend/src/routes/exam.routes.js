const express = require('express');
const router = express.Router();
const { 
  getAllExams,
  getExamById,
  updateExam,
  deleteExam,
  getCourseExams,
  getExamsBySection, // Added new function
  getSectionExamsAdmin, // Added new admin function
  getExamQuestions,
  submitExam,
  getExamResults,
  getUserExamHistory, // Added new function
  createExam
} = require('../controllers/exam.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const { authorize: roleAuthorize } = require('../middleware/role.middleware');

// Admin routes
router.get('/', protect, roleAuthorize('admin'), getAllExams);
router.get('/section/:sectionId/admin', protect, roleAuthorize('admin'), getSectionExamsAdmin);
router.get('/:id', protect, roleAuthorize('admin'), getExamById);
router.put('/:id', protect, roleAuthorize('admin'), updateExam);
router.delete('/:id', protect, roleAuthorize('admin'), deleteExam);
router.post('/', protect, roleAuthorize('admin'), createExam);

// Student routes
router.get('/student/history', protect, getUserExamHistory); // New independent route for student exam history
router.get('/history/test', protect, (req, res) => {
  res.json({
    success: true,
    message: 'History endpoint is accessible',
    user: {
      id: req.user?.id,
      email: req.user?.email,
      role: req.user?.role
    }
  });
});
router.get('/history', protect, getUserExamHistory); // Original route - keep for backward compatibility
router.get('/course/:courseId', protect, getCourseExams);
router.get('/section/:sectionId', protect, getExamsBySection); // Added new route
router.get('/:examId/questions', protect, getExamQuestions);
router.post('/:examId/submit', protect, submitExam);
router.get('/:examId/results', protect, getExamResults);

module.exports = router;