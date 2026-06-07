const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const {
  getAssignedCourses,
  getCourseContent,
  getCourseStudents,
  getStudentPerformance,
  getDashboardStats
} = require('../controllers/teacher.controller');

// All routes require instructor role
router.use(protect, authorize('instructor'));

// Dashboard stats
router.get('/dashboard-stats', getDashboardStats);

// Course management
router.get('/courses', getAssignedCourses);
router.get('/courses/:courseId/content', getCourseContent);

// Student management
router.get('/courses/:courseId/students', getCourseStudents);
router.get('/courses/:courseId/students/:studentId/performance', getStudentPerformance);

module.exports = router;
