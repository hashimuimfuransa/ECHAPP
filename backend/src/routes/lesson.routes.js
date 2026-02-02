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

// Public routes
router.get('/section/:sectionId', getLessonsBySection);
router.get('/:lessonId', getLessonById);
router.get('/course/:courseId/content', getCourseContent);

// Admin routes
router.post('/section/:sectionId', protect, authorize('admin'), createLesson);
router.put('/:lessonId', protect, authorize('admin'), updateLesson);
router.delete('/:lessonId', protect, authorize('admin'), deleteLesson);
router.post('/section/:sectionId/reorder', protect, authorize('admin'), reorderLessons);

module.exports = router;