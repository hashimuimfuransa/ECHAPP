const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const examProcessingController = require('../controllers/exam_processing.controller');
const uploadController = require('../controllers/upload.controller');

// Document upload routes now use the exam processing controller for separated workflows

/**
 * Upload document for lesson notes (will be processed for note organization)
 * POST /api/documents/upload-for-notes
 */
router.post(
  '/upload-for-notes',
  protect,
  authorize('admin', 'instructor'),
  uploadController.upload.single('document'),
  examProcessingController.createLessonFromDocument
);

/**
 * Upload document for exam creation (will be processed to extract questions)
 * POST /api/documents/upload-for-exam
 */
router.post(
  '/upload-for-exam',
  protect,
  authorize('admin', 'instructor'),
  uploadController.upload.single('document'),
  examProcessingController.createExamFromDocument
);

/**
 * Upload general document (no automatic processing)
 * POST /api/documents/upload
 */
router.post(
  '/upload',
  protect,
  authorize('admin', 'instructor', 'student'),
  uploadController.upload.single('document'),
  uploadController.uploadDocument
);

// Exam processing routes

/**
 * Create exam directly from document upload
 * POST /api/exam-processing/create-from-document
 */
router.post(
  '/create-from-document',
  protect,
  authorize('admin', 'instructor'),
  examProcessingController.createExamFromDocument
);

/**
 * Process existing document to create exam
 * POST /api/exam-processing/process-document/:documentKey
 */
router.post(
  '/process-document/:documentKey',
  protect,
  authorize('admin', 'instructor'),
  examProcessingController.processExistingDocument
);

/**
 * Get exam processing status
 * GET /api/exam-processing/status/:examId
 */
router.get(
  '/status/:examId',
  protect,
  authorize('admin', 'instructor', 'student'),
  examProcessingController.getProcessingStatus
);

module.exports = router;