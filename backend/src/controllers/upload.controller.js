const multer = require('multer');
const s3Service = require('../services/s3.service');
const { sendSuccess, sendError } = require('../utils/response.utils');

// Configure multer for memory storage (files stored in memory as Buffer)
const storage = multer.memoryStorage();

// File filter to accept images and videos
const fileFilter = (req, file, cb) => {
  // Accept images and common video formats
  if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image and video files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit for videos, images will be smaller
  }
});

// Upload image controller
const uploadImage = async (req, res) => {
  try {
    // Use multer middleware
    upload.single('image')(req, res, async function (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return sendError(res, 'File too large. Maximum size is 100MB.', 400);
        }
        return sendError(res, 'Upload error', 400, err.message);
      } else if (err) {
        return sendError(res, 'Upload failed', 400, err.message);
      }

      // Check if file was uploaded
      if (!req.file) {
        return sendError(res, 'No image file provided', 400);
      }

      // Check if it's actually an image
      if (!req.file.mimetype.startsWith('image/')) {
        return sendError(res, 'Only image files are allowed for this endpoint', 400);
      }

      try {
        // Upload to AWS S3
        const result = await s3Service.uploadImage(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );

        sendSuccess(res, {
          imageUrl: result.url,
          s3Key: result.key,
          bucket: result.bucket,
          originalName: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype
        }, 'Image uploaded successfully');
      } catch (s3Error) {
        sendError(res, 'Failed to upload image to storage', 500, s3Error.message);
      }
    });
  } catch (error) {
    sendError(res, 'Image upload failed', 500, error.message);
  }
};

// Upload video controller
const uploadVideo = async (req, res) => {
  try {
    // Use multer middleware
    upload.single('video')(req, res, async function (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return sendError(res, 'File too large. Maximum size is 100MB.', 400);
        }
        return sendError(res, 'Upload error', 400, err.message);
      } else if (err) {
        return sendError(res, 'Upload failed', 400, err.message);
      }

      // Check if file was uploaded
      if (!req.file) {
        return sendError(res, 'No video file provided', 400);
      }

      // Check if it's actually a video
      if (!req.file.mimetype.startsWith('video/')) {
        return sendError(res, 'Only video files are allowed for this endpoint', 400);
      }

      try {
        // Upload to AWS S3
        const result = await s3Service.uploadVideo(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );

        sendSuccess(res, {
          videoUrl: result.url,
          s3Key: result.key,
          bucket: result.bucket,
          videoId: result.key, // For compatibility with existing lesson model
          originalName: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype
        }, 'Video uploaded successfully');
      } catch (s3Error) {
        sendError(res, 'Failed to upload video to storage', 500, s3Error.message);
      }
    });
  } catch (error) {
    sendError(res, 'Video upload failed', 500, error.message);
  }
};

module.exports = {
  uploadImage,
  uploadVideo
};