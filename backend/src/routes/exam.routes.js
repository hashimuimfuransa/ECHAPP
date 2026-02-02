const express = require('express');
const router = express.Router();
const { 
  getCourseExams,
  getExamQuestions,
  submitExam,
  getExamResults,
  createExam
} = require('../controllers/exam.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const { authorize: roleAuthorize } = require('../middleware/role.middleware');

// Student routes
router.get('/:courseId', protect, getCourseExams);
router.get('/:examId/questions', protect, getExamQuestions);
router.post('/:examId/submit', protect, submitExam);
router.get('/:examId/results', protect, getExamResults);

// Admin routes
router.post('/', protect, roleAuthorize('admin'), createExam);

module.exports = router;