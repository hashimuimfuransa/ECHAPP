const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
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
  uploadController.upload.single('document')
);


/**
 * Upload general document (no automatic processing)
 * POST /api/documents/upload
 */
router.post(
  '/upload',
  protect,
  authorize('admin', 'instructor', 'student'),
  uploadController.uploadDocument
);


module.exports = router;