const express = require('express');
const router = express.Router();
const { uploadImage } = require('../controllers/upload.controller');
const { protect } = require('../middleware/auth.middleware');

// Protected image upload route
router.post('/image', protect, uploadImage);

module.exports = router;