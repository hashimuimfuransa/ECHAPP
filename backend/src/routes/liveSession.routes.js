const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const {
  createSession,
  getTeacherSessions,
  getCourseSessions,
  joinSession,
  endSession,
  cancelSession,
  getSessionRecordings,
  getLessonSessions
} = require('../controllers/liveSession.controller');

// All routes require authentication
router.use(protect);

// Teacher-only routes
router.post('/sessions', authorize('instructor'), createSession);
router.get('/teacher/sessions', authorize('instructor'), getTeacherSessions);
router.put('/sessions/:sessionId/end', authorize('instructor'), endSession);
router.put('/sessions/:sessionId/cancel', authorize('instructor'), cancelSession);

// Student routes (enrollment checked in controller)
router.get('/courses/:courseId/sessions', getCourseSessions);
router.get('/lessons/:lessonId/sessions', getLessonSessions);

// Shared routes (permission checked in controller)
router.get('/sessions/:sessionId/join', joinSession);
router.get('/sessions/:sessionId/recordings', getSessionRecordings);

module.exports = router;
