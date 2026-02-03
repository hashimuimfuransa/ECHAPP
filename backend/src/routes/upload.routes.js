const express = require('express');
const router = express.Router();
const { uploadImage, uploadVideo } = require('../controllers/upload.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Protected image upload route
router.post('/image', protect, uploadImage);

// Protected video upload route (admin only)
router.post('/video', protect, authorize('admin'), uploadVideo);

module.exports = router;