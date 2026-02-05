const express = require('express');
const router = express.Router();
const { 
  getAllExams,
  getExamById,
  updateExam,
  deleteExam,
  getCourseExams,
  getExamQuestions,
  submitExam,
  getExamResults,
  createExam
} = require('../controllers/exam.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const { authorize: roleAuthorize } = require('../middleware/role.middleware');

// Admin routes
router.get('/', protect, roleAuthorize('admin'), getAllExams);
router.get('/:id', protect, roleAuthorize('admin'), getExamById);
router.put('/:id', protect, roleAuthorize('admin'), updateExam);
router.delete('/:id', protect, roleAuthorize('admin'), deleteExam);
router.post('/', protect, roleAuthorize('admin'), createExam);

// Student routes
router.get('/course/:courseId', protect, getCourseExams);
router.get('/:examId/questions', protect, getExamQuestions);
router.post('/:examId/submit', protect, submitExam);
router.get('/:examId/results', protect, getExamResults);

module.exports = router;