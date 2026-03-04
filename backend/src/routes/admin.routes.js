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
  getCourseAnalytics,
  createAdmin,
  syncFirebaseUser,
  deleteUserSync,
  manualSyncAllUsers,
  getUserDeviceInfo,
  resetUserDevice,
  toggleStudentStatus
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
router.get('/analytics/course/:courseId', protect, authorize('admin'), getCourseAnalytics);

// Device management routes
router.get('/students/:id/device-info', protect, authorize('admin'), getUserDeviceInfo);
router.put('/students/:id/device-reset', protect, authorize('admin'), resetUserDevice);
router.put('/students/:id/toggle-status', protect, authorize('admin'), toggleStudentStatus);

module.exports = router;