const express = require('express');
const router = express.Router();
const { 
  getStudents,
  getCourseStats,
  getPaymentStats,
  getExamStats,
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
router.get('/course-stats', protect, authorize('admin'), getCourseStats);
router.get('/payment-stats', protect, authorize('admin'), getPaymentStats);
router.get('/exam-stats', protect, authorize('admin'), getExamStats);

module.exports = router;