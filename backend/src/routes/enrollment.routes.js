const express = require('express');
const router = express.Router();
const { 
  enrollInCourse,
  getMyCourses,
  submitCourseFeedback,
  getEnrollmentProgress,
  updateEnrollmentProgress,
  getCertificates,
  checkCertificateEligibility,
  downloadCertificate,
  checkCourseAccess,
  downloadCertificateFile,
  verifyCertificate
} = require('../controllers/enrollment.controller');
const { protect } = require('../middleware/auth.middleware');

// Public routes
router.get('/verify/:serialNumber', verifyCertificate);

// Protected routes
router.post('/', protect, enrollInCourse);
router.get('/my-courses', protect, getMyCourses);
router.post('/course/:courseId/feedback', protect, submitCourseFeedback);
router.get('/:id/progress', protect, getEnrollmentProgress);
router.put('/:id/progress', protect, updateEnrollmentProgress);

// Certificate routes
router.get('/certificates', protect, getCertificates);
router.get('/:courseId/certificate-eligibility', protect, checkCertificateEligibility);
router.get('/:courseId/certificate/download', protect, downloadCertificate);

// New route for downloading certificate files
router.get('/certificates/:certificateId/download-file', protect, downloadCertificateFile);

// Course access check route
router.get('/:courseId/access-check', protect, checkCourseAccess);

module.exports = router;