const multer = require('multer');
const s3Service = require('../services/s3.service');
const UploadProgressService = require('../services/upload-progress.service');
const { sendSuccess, sendError } = require('../utils/response.utils');

// Configure multer for memory storage (files stored in memory as Buffer)
const storage = multer.memoryStorage();

// File filter to accept images and videos with expanded video support
const fileFilter = (req, file, cb) => {
  // Extract the file extension to determine type
  const fileExtension = file.originalname.toLowerCase().split('.').pop();
  
  // Common video extensions and their MIME types
  const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv', 'm4v', '3gp', 'mpeg', 'mpg'];
  const videoMimeTypes = [
    'video/mp4', 'video/avi', 'video/quicktime', 'video/x-ms-wmv', 
    'video/x-flv', 'video/webm', 'video/x-matroska', 'video/x-m4v',
    'video/3gpp', 'video/mpeg', 'video/msvideo'
  ];
  
  // Common image extensions and their MIME types
  const imageMimeTypes = [
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 
    'image/webp', 'image/bmp', 'image/svg+xml', 'image/tiff'
  ];
  
  // Check if it's an accepted video format
  const isVideo = file.mimetype.startsWith('video/') || videoExtensions.includes(fileExtension);
  // Check if it's an accepted image format
  const isImage = file.mimetype.startsWith('image/') || imageMimeTypes.includes(file.mimetype);
  
  if (isImage || isVideo) {
    cb(null, true);
  } else {
    console.log(`Rejected file: ${file.originalname}, MIME: ${file.mimetype}, Extension: ${fileExtension}`);
    cb(new Error('Only image and video files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit for videos, images will be smaller
    fields: 10,  // Allow up to 10 additional fields
    fieldSize: 1 * 1024 * 1024,  // 1MB max size for each field
    parts: 50  // Allow up to 50 parts (fields + files)
  }
});

// Upload image controller
const uploadImage = async (req, res) => {
  try {
    // Log initial request
    console.log('Image upload request received with headers:', req.headers);
    
    // Use multer middleware
    upload.single('image')(req, res, async function (err) {
      if (err instanceof multer.MulterError) {
        console.error('Multer error:', err);
        if (err.code === 'LIMIT_FILE_SIZE') {
          return sendError(res, 'File too large. Maximum size is 100MB.', 400);
        } else if (err.code === 'LIMIT_FIELD_KEY' || err.code === 'LIMIT_FIELD_VALUE' || err.code === 'LIMIT_FIELDS') {
          return sendError(res, `Upload field limit exceeded: ${err.message}`, 400);
        } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
          return sendError(res, `Unexpected file field: ${err.field}`, 400);
        }
        return sendError(res, `Upload error: ${err.message}`, 400);
      } else if (err) {
        console.error('General upload error:', err);
        return sendError(res, `Upload failed: ${err.message}`, 400);
      }

      // Check if file was uploaded
      if (!req.file) {
        console.error('No file received in upload request');
        return sendError(res, 'No image file provided', 400);
      }

      // Log the received fields for debugging
      console.log('Received image upload with fields:', Object.keys(req.body));
      console.log('File details:', {
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype,
        encoding: req.file.encoding,
        fieldname: req.file.fieldname,
        destination: req.file.destination, // Will be undefined for memory storage
        filename: req.file.filename // Will be undefined for memory storage
      });

      // Check if it's actually an image - allow both image MIME types and files with generic MIME but valid image extensions
      const fileExtension = req.file.originalname.toLowerCase().split('.').pop();
      const validImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'tiff'];
      
      if (!req.file.mimetype.startsWith('image/') && !validImageExtensions.includes(fileExtension)) {
        return sendError(res, `Only image files are allowed for this endpoint. Received: ${req.file.mimetype} (${req.file.originalname})`, 400);
      }

      try {
        // Upload to AWS S3
        const result = await s3Service.uploadImage(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );

        // Attempt to generate signed URL, but don't fail the entire operation if it fails
        let signedUrl = null;
        try {
          signedUrl = await s3Service.getSignedPublicUrl(result.key);
        } catch (urlError) {
          console.warn('Warning: Failed to generate signed URL:', urlError.message);
          // Fall back to using the public URL if signed URL generation fails
          signedUrl = result.url;
        }

        sendSuccess(res, {
          imageUrl: result.url,
          signedUrl: signedUrl,
          s3Key: result.key,
          bucket: result.bucket,
          originalName: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype,
          // Include any additional fields from the request body
          ...(req.body.courseId && { courseId: req.body.courseId }),
          ...(req.body.sectionId && { sectionId: req.body.sectionId }),
          ...(req.body.title && { title: req.body.title }),
          ...(req.body.description && { description: req.body.description })
        }, 'Image uploaded successfully');
      } catch (s3Error) {
        console.error('S3 upload error:', s3Error);
        sendError(res, 'Failed to upload image to storage', 500, s3Error.message);
      }
    });
  } catch (error) {
    console.error('Image upload error:', error);
    sendError(res, 'Image upload failed', 500, error.message);
  }
};

// Generate presigned URL for direct S3 upload
const generatePresignedUrl = async (req, res) => {
  try {
    const { fileName, contentType, folder = 'uploads' } = req.body;
    
    console.log('Generating presigned URL with params:', { fileName, contentType, folder });
    
    // Validate required parameters
    if (!fileName) {
      return sendError(res, 'File name is required', 400);
    }
    
    if (!contentType) {
      return sendError(res, 'Content type is required', 400);
    }
    
    // Validate content type
    if (!contentType.startsWith('image/') && !contentType.startsWith('video/')) {
      return sendError(res, `Only image and video files are allowed. Received: ${contentType}`, 400);
    }
    
    // Generate presigned URL
    const result = await s3Service.generatePresignedUploadUrl(
      fileName,
      contentType,
      folder,
      300 // 5 minutes expiration
    );
    
    sendSuccess(res, {
      uploadUrl: result.uploadUrl,
      key: result.key,
      publicUrl: result.publicUrl,
      expiresIn: 300
    }, 'Presigned URL generated successfully');
    
  } catch (error) {
    console.error('Presigned URL generation error:', error);
    sendError(res, 'Failed to generate presigned URL', 500, error.message);
  }
};

// Upload video controller
const uploadVideo = async (req, res) => {
  try {
    // Log initial request
    console.log('Video upload request received with headers:', req.headers);
    
    // Generate upload ID for progress tracking
    const uploadId = UploadProgressService.generateUploadId();
    
    // Set initial progress to 0%
    UploadProgressService.updateProgress(uploadId, 0, 'preparing', 'Preparing for upload...');
    
    // Use multer middleware
    upload.single('video')(req, res, async function (err) {
      if (err instanceof multer.MulterError) {
        console.error('Multer error:', err);
        // Update progress with error
        UploadProgressService.updateProgress(uploadId, 0, 'error', `Upload error: ${err.message}`);
        if (err.code === 'LIMIT_FILE_SIZE') {
          return sendError(res, 'File too large. Maximum size is 100MB.', 400);
        } else if (err.code === 'LIMIT_FIELD_KEY' || err.code === 'LIMIT_FIELD_VALUE' || err.code === 'LIMIT_FIELDS') {
          return sendError(res, `Upload field limit exceeded: ${err.message}`, 400);
        } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
          return sendError(res, `Unexpected file field: ${err.field}`, 400);
        }
        return sendError(res, `Upload error: ${err.message}`, 400);
      } else if (err) {
        console.error('General upload error:', err);
        // Update progress with error
        UploadProgressService.updateProgress(uploadId, 0, 'error', `Upload failed: ${err.message}`);
        return sendError(res, `Upload failed: ${err.message}`, 400);
      }

      // Check if file was uploaded
      if (!req.file) {
        console.error('No file received in upload request');
        // Update progress with error
        UploadProgressService.updateProgress(uploadId, 0, 'error', 'No video file provided');
        return sendError(res, 'No video file provided', 400);
      }

      // Log the received fields for debugging
      console.log('Received video upload with fields:', Object.keys(req.body));
      console.log('File details:', {
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype,
        encoding: req.file.encoding,
        fieldname: req.file.fieldname,
        destination: req.file.destination, // Will be undefined for memory storage
        filename: req.file.filename // Will be undefined for memory storage
      });

      // Check if it's actually a video - allow both video MIME types and files with generic MIME but valid video extensions
      const fileExtension = req.file.originalname.toLowerCase().split('.').pop();
      const validVideoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv', 'm4v', '3gp', 'mpeg', 'mpg'];
      
      if (!req.file.mimetype.startsWith('video/') && !validVideoExtensions.includes(fileExtension)) {
        // Update progress with error
        UploadProgressService.updateProgress(uploadId, 0, 'error', `Only video files are allowed. Received: ${req.file.mimetype} (${req.file.originalname})`);
        return sendError(res, `Only video files are allowed for this endpoint. Received: ${req.file.mimetype} (${req.file.originalname})`, 400);
      }

      try {
        // Update progress to indicate upload started
        UploadProgressService.updateProgress(uploadId, 10, 'uploading_to_s3', 'Uploading to S3...');
        
        // Upload to AWS S3
        const result = await s3Service.uploadVideo(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );
        
        // Update progress to indicate completion
        UploadProgressService.updateProgress(uploadId, 100, 'completed', 'Upload completed successfully!');

        sendSuccess(res, {
          videoUrl: result.url,
          s3Key: result.key,
          bucket: result.bucket,
          videoId: result.key, // For compatibility with existing lesson model
          originalName: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype,
          uploadId: uploadId, // Include upload ID for progress tracking
          // Include any additional fields from the request body
          ...(req.body.courseId && { courseId: req.body.courseId }),
          ...(req.body.sectionId && { sectionId: req.body.sectionId }),
          ...(req.body.title && { title: req.body.title }),
          ...(req.body.description && { description: req.body.description })
        }, 'Video uploaded successfully');
      } catch (s3Error) {
        // Update progress with error
        UploadProgressService.updateProgress(uploadId, 0, 'error', `S3 upload failed: ${s3Error.message}`);
        console.error('S3 upload error:', s3Error);
        sendError(res, 'Failed to upload video to storage', 500, s3Error.message);
      }
    });
  } catch (error) {
    console.error('Video upload error:', error);
    sendError(res, 'Video upload failed', 500, error.message);
  }
};

// Get upload progress
const getUploadProgress = async (req, res) => {
  try {
    const { uploadId } = req.params;
    
    if (!uploadId) {
      return sendError(res, 'Upload ID is required', 400);
    }
    
    const progress = UploadProgressService.getProgress(uploadId);
    
    if (!progress) {
      return sendError(res, 'Upload progress not found', 404);
    }
    
    sendSuccess(res, progress, 'Upload progress retrieved successfully');
  } catch (error) {
    console.error('Get upload progress error:', error);
    sendError(res, 'Failed to get upload progress', 500, error.message);
  }
};

module.exports = {
  uploadImage,
  uploadVideo,
  generatePresignedUrl,
  getUploadProgress
};