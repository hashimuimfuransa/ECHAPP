const express = require('express');
const router = express.Router();
const { 
  getVideoStreamUrl,
  getVideoDetails,
  deleteVideo,
  getAllVideos,
  getVideosByCourse
} = require('../controllers/video.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Student routes
router.get('/:lessonId/stream-url', protect, getVideoStreamUrl);

// Admin routes
router.get('/details/:videoId', protect, authorize('admin'), getVideoDetails);
router.delete('/delete/:videoId', protect, authorize('admin'), deleteVideo);
router.get('/all', protect, authorize('admin'), getAllVideos);
router.get('/course/:courseId', protect, authorize('admin'), getVideosByCourse);

module.exports = router;