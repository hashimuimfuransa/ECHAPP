const express = require('express');
const router = express.Router();
const { 
  getVideoStreamUrl,
  uploadVideo,
  getVideoDetails
} = require('../controllers/video.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Student routes
router.get('/:lessonId/stream-url', protect, getVideoStreamUrl);

// Admin routes
router.post('/upload', protect, authorize('admin'), uploadVideo);
router.get('/details/:videoId', protect, authorize('admin'), getVideoDetails);

module.exports = router;