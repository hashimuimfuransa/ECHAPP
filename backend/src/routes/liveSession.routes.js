const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const {
  createSession,
  getTeacherSessions,
  getCourseSessions,
  getSessionAttendance,
  joinSession,
  endSession,
  updateSession,
  cancelSession,
  deleteSession,
  getSessionRecordings,
  getLessonSessions,
  getAllSessions
} = require('../controllers/liveSession.controller');

// All routes require authentication
router.use(protect);

// Teacher-only routes
router.post('/sessions', authorize('instructor'), createSession);
router.get('/teacher/sessions', authorize('instructor'), getTeacherSessions);
router.put('/sessions/:sessionId', authorize('instructor'), updateSession);
router.put('/sessions/:sessionId/end', authorize('instructor'), endSession);
router.put('/sessions/:sessionId/cancel', authorize('instructor'), cancelSession);
router.delete('/sessions/:sessionId', authorize('instructor'), deleteSession);

// Admin-only routes
router.get('/admin/sessions', authorize('admin'), getAllSessions);

// Student routes (enrollment checked in controller)
router.get('/courses/:courseId/sessions', getCourseSessions);
router.get('/lessons/:lessonId/sessions', getLessonSessions);

// Shared routes (permission checked in controller)
router.get('/sessions/:sessionId/join', joinSession);
router.get('/sessions/:sessionId/recordings', getSessionRecordings);
router.get('/sessions/:sessionId/attendance', getSessionAttendance);

module.exports = router;
