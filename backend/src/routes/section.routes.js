const express = require('express');
const router = express.Router();
const { 
  getSectionsByCourse,
  createSection,
  updateSection,
  deleteSection,
  reorderSections
} = require('../controllers/section.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Get sections for a course (public)
router.get('/course/:courseId', getSectionsByCourse);

// Admin and Instructor routes
router.post('/course/:courseId', protect, authorize('admin', 'instructor'), createSection);
router.put('/:sectionId', protect, authorize('admin', 'instructor'), updateSection);
router.delete('/:sectionId', protect, authorize('admin'), deleteSection);
router.post('/course/:courseId/reorder', protect, authorize('admin', 'instructor'), reorderSections);

module.exports = router;