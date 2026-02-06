const express = require('express');
const router = express.Router();
const { 
  getStudents,
  getStudentDetail,
  deleteStudent,
  getCourseStats,
  getPaymentStats,
  getExamStats,
  getStudentAnalytics,
  createAdmin,
  syncFirebaseUser,
  deleteUserSync,
  manualSyncAllUsers
} = require('../controllers/admin.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Admin authentication routes
router.post('/create-admin', createAdmin);

// User synchronization routes (can be called by Firebase functions)
router.post('/sync-firebase-user', syncFirebaseUser);
router.delete('/sync-firebase-user/:firebaseUid', deleteUserSync);
router.post('/manual-sync-users', protect, authorize('admin'), manualSyncAllUsers);

// Protected admin routes
router.get('/students', protect, authorize('admin'), getStudents);
router.get('/students/:id/detail', protect, authorize('admin'), getStudentDetail);
router.delete('/students/:id', protect, authorize('admin'), deleteStudent);
router.get('/course-stats', protect, authorize('admin'), getCourseStats);
router.get('/payment-stats', protect, authorize('admin'), getPaymentStats);
router.get('/exam-stats', protect, authorize('admin'), getExamStats);
router.get('/analytics/students', protect, authorize('admin'), getStudentAnalytics);

module.exports = router;