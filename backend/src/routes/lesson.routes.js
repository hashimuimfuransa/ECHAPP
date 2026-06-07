const express = require('express');
const router = express.Router();
const { 
  getLessonsBySection,
  getLessonById,
  createLesson,
  updateLesson,
  deleteLesson,
  reorderLessons,
  getCourseContent
} = require('../controllers/lesson.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Protected routes (require authentication)
router.get('/section/:sectionId', protect, getLessonsBySection);
router.get('/:lessonId', protect, getLessonById);
router.get('/course/:courseId/content', protect, getCourseContent);

// Admin and Instructor routes
router.post('/section/:sectionId', protect, authorize('admin', 'instructor'), createLesson);
router.put('/:lessonId', protect, authorize('admin', 'instructor'), updateLesson);
router.delete('/:lessonId', protect, authorize('admin'), deleteLesson);
router.post('/section/:sectionId/reorder', protect, authorize('admin', 'instructor'), reorderLessons);

module.exports = router;