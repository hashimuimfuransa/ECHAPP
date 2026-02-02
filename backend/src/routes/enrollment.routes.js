const express = require('express');
const router = express.Router();
const { 
  enrollInCourse,
  getMyCourses,
  getEnrollmentProgress,
  updateEnrollmentProgress
} = require('../controllers/enrollment.controller');
const { protect } = require('../middleware/auth.middleware');

// Protected routes
router.post('/', protect, enrollInCourse);
router.get('/my-courses', protect, getMyCourses);
router.get('/:id/progress', protect, getEnrollmentProgress);
router.put('/:id/progress', protect, updateEnrollmentProgress);

module.exports = router;