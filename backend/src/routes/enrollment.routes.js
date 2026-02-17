const express = require('express');
const router = express.Router();
const { 
  enrollInCourse,
  getMyCourses,
  getEnrollmentProgress,
  updateEnrollmentProgress,
  getCertificates,
  checkCertificateEligibility,
  downloadCertificate,
  checkCourseAccess
} = require('../controllers/enrollment.controller');
const { protect } = require('../middleware/auth.middleware');

// Protected routes
router.post('/', protect, enrollInCourse);
router.get('/my-courses', protect, getMyCourses);
router.get('/:id/progress', protect, getEnrollmentProgress);
router.put('/:id/progress', protect, updateEnrollmentProgress);

// Certificate routes
router.get('/certificates', protect, getCertificates);
router.get('/:courseId/certificate-eligibility', protect, checkCertificateEligibility);
router.get('/:courseId/certificate/download', protect, downloadCertificate);

// Course access check route
router.get('/:courseId/access-check', protect, checkCourseAccess);

module.exports = router;