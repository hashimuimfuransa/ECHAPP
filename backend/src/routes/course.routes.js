const express = require('express');
const router = express.Router();
const { 
  getCourses, 
  getCourseById, 
  createCourse, 
  updateCourse, 
  deleteCourse 
} = require('../controllers/course.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public routes
router.get('/', getCourses);
router.get('/:id', getCourseById); // Make basic course info public

// Admin routes
router.post('/', protect, authorize('admin'), createCourse);
router.put('/:id', protect, authorize('admin'), updateCourse);
router.delete('/:id', protect, authorize('admin'), deleteCourse);

module.exports = router;