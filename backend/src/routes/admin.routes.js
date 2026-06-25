const express = require('express');
const router = express.Router();
const { 
  getStudents,
  getAdmins,
  getTeachers,
  createTeacher,
  updateTeacher,
  deleteTeacher,
  assignTeacherToCourse,
  unassignTeacherFromCourse,
  getTeacherAssignments,
  getCourseTeachers,
  getTeacherActivity,
  updateUserRole,
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
  toggleStudentStatus,
  unenrollStudent,
  resetStudentPassword,
  updateStudent,
  updateEnrollmentPermissions
} = require('../controllers/admin.controller');
const { manualExpirationCheck } = require('../controllers/admin-expiration.controller');
const notificationController = require('../controllers/notification.controller');
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
router.get('/admins', protect, authorize('admin'), getAdmins);
router.put('/users/:id/role', protect, authorize('admin'), updateUserRole);
router.get('/students/:id/detail', protect, authorize('admin'), getStudentDetail);
router.delete('/students/:id', protect, authorize('admin'), deleteStudent);
router.get('/course-stats', protect, authorize('admin'), getCourseStats);
router.get('/payment-stats', protect, authorize('admin'), getPaymentStats);
router.get('/exam-stats', protect, authorize('admin'), getExamStats);
router.get('/analytics/students', protect, authorize('admin'), getStudentAnalytics);
router.get('/analytics/course/:courseId', protect, authorize('admin'), getCourseAnalytics);

// Notifications
router.get('/notifications', protect, authorize('admin'), (req, res) => notificationController.getAdminNotifications(req, res));

// Device management routes
router.get('/students/:id/device-info', protect, authorize('admin'), getUserDeviceInfo);
router.put('/students/:id/device-reset', protect, authorize('admin'), resetUserDevice);
router.put('/students/:id/toggle-status', protect, authorize('admin'), toggleStudentStatus);
router.put('/students/:id/reset-password', protect, authorize('admin'), resetStudentPassword);
router.put('/students/:id', protect, authorize('admin'), updateStudent);
router.delete('/courses/:courseId/enrollments/:studentId', protect, authorize('admin'), unenrollStudent);
router.put('/enrollments/:id/permissions', protect, authorize('admin'), updateEnrollmentPermissions);

// Manual expiration check
router.post('/trigger-expiration-check', protect, authorize('admin'), manualExpirationCheck);

// Teacher management routes
router.get('/teachers', protect, authorize('admin'), getTeachers);
router.post('/teachers', protect, authorize('admin'), createTeacher);
router.put('/teachers/:id', protect, authorize('admin'), updateTeacher);
router.delete('/teachers/:id', protect, authorize('admin'), deleteTeacher);
router.post('/teachers/assign', protect, authorize('admin'), assignTeacherToCourse);
router.post('/teachers/unassign', protect, authorize('admin'), unassignTeacherFromCourse);
router.get('/teachers/:teacherId/assignments', protect, authorize('admin'), getTeacherAssignments);
router.get('/teachers/:teacherId/activity', protect, authorize('admin'), getTeacherActivity);
router.get('/courses/:courseId/teachers', protect, authorize('admin'), getCourseTeachers);

module.exports = router;