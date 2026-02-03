const express = require('express');
const router = express.Router();
const { 
  getVideoStreamUrl,
  getVideoDetails,
  deleteVideo
} = require('../controllers/video.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Student routes
router.get('/:lessonId/stream-url', protect, getVideoStreamUrl);

// Admin routes
router.get('/details/:videoId', protect, authorize('admin'), getVideoDetails);
router.delete('/delete/:videoId', protect, authorize('admin'), deleteVideo);

module.exports = router;