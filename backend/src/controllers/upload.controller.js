const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { sendSuccess, sendError } = require('../utils/response.utils');

// Configure multer for image uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../../uploads/images');
    // Create directory if it doesn't exist
    fs.mkdir(uploadDir, { recursive: true }).then(() => {
      cb(null, uploadDir);
    }).catch(err => {
      cb(err, uploadDir);
    });
  },
  filename: function (req, file, cb) {
    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter to accept only images
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Upload image controller
const uploadImage = async (req, res) => {
  try {
    // Use multer middleware
    upload.single('image')(req, res, async function (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return sendError(res, 'File too large. Maximum size is 5MB.', 400);
        }
        return sendError(res, 'Upload error', 400, err.message);
      } else if (err) {
        return sendError(res, 'Upload failed', 400, err.message);
      }

      // Check if file was uploaded
      if (!req.file) {
        return sendError(res, 'No image file provided', 400);
      }

      // Generate public URL for the uploaded image
      const imageUrl = `${req.protocol}://${req.get('host')}/uploads/images/${req.file.filename}`;
      
      sendSuccess(res, {
        imageUrl: imageUrl,
        filename: req.file.filename,
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype
      }, 'Image uploaded successfully');
    });
  } catch (error) {
    sendError(res, 'Image upload failed', 500, error.message);
  }
};

module.exports = {
  uploadImage
};