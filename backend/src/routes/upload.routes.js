const express = require('express');
const router = express.Router();
const { uploadImage, uploadVideo, uploadDocument, generatePresignedUrl, getUploadProgress } = require('../controllers/upload.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Generate presigned URL for direct S3 upload (admin only for course content)
router.post('/presigned-url', protect, authorize('admin'), generatePresignedUrl);

// Protected image upload route
router.post('/image', protect, uploadImage);

// Protected video upload route (admin only)
router.post('/video', protect, authorize('admin'), uploadVideo);

// Protected document upload route (admin only)
router.post('/document', protect, authorize('admin'), uploadDocument);

// Get upload progress (authenticated users)
router.get('/progress/:uploadId', protect, getUploadProgress);

module.exports = router;