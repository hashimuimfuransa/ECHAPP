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

// Admin routes
router.post('/course/:courseId', protect, authorize('admin'), createSection);
router.put('/:sectionId', protect, authorize('admin'), updateSection);
router.delete('/:sectionId', protect, authorize('admin'), deleteSection);
router.post('/course/:courseId/reorder', protect, authorize('admin'), reorderSections);

module.exports = router;