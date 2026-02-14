const multer = require('multer');
const s3Service = require('../services/s3.service');
const UploadProgressService = require('../services/upload-progress.service');
const { sendSuccess, sendError } = require('../utils/response.utils');

// Configure multer for memory storage (files stored in memory as Buffer)
const storage = multer.memoryStorage();

// File filter to accept images, videos, and documents with expanded support
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
  
  // Common document extensions and their MIME types
  const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx', 'rtf', 'odt', 'ods', 'odp'];
  const documentMimeTypes = [
    'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/rtf', 'application/vnd.oasis.opendocument.text', 'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.presentation'
  ];
  
  // Check if it's an accepted video format
  const isVideo = file.mimetype.startsWith('video/') || videoExtensions.includes(fileExtension);
  // Check if it's an accepted image format
  const isImage = file.mimetype.startsWith('image/') || imageMimeTypes.includes(file.mimetype);
  // Check if it's an accepted document format
  const isDocument = documentMimeTypes.includes(file.mimetype) || documentExtensions.includes(fileExtension);
  
  if (isImage || isVideo || isDocument) {
    cb(null, true);
  } else {
    console.log(`Rejected file: ${file.originalname}, MIME: ${file.mimetype}, Extension: ${fileExtension}`);
    cb(new Error('Only image, video, and document files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 2 * 1024 * 1024 * 1024, // 2GB limit for videos, images will be smaller
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
          return sendError(res, 'File too large. Maximum size is 2GB.', 400);
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
          return sendError(res, 'File too large. Maximum size is 2GB.', 400);
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

        // If courseId and sectionId are provided, create a lesson with the video
        let lesson = null;
        if (req.body.courseId && req.body.sectionId) {
          const Lesson = require('../models/Lesson');
          const Section = require('../models/Section');
          
          // Get the section to get the courseId (in case it wasn't provided separately)
          const section = await Section.findById(req.body.sectionId);
          if (section) {
            const order = await Lesson.countDocuments({ sectionId: req.body.sectionId }) + 1;
            
            lesson = await Lesson.create({
              sectionId: req.body.sectionId,
              courseId: req.body.courseId || section.courseId.toString(), // Use provided courseId or section's courseId
              title: req.body.title || req.file.originalname.split('.')[0], // Use provided title or filename without extension
              description: req.body.description,
              videoId: result.key, // Store the S3 key as videoId
              notes: null, // Initially no notes
              order: order,
              duration: 0 // Initially unknown, can be updated later
            });
          }
        }

        sendSuccess(res, {
          videoUrl: result.url,
          s3Key: result.key,
          bucket: result.bucket,
          videoId: result.key, // For compatibility with existing lesson model
          originalName: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype,
          uploadId: uploadId, // Include upload ID for progress tracking
          lesson: lesson, // Return the created lesson if applicable
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

// Upload document controller
const uploadDocument = async (req, res) => {
  try {
    // Log initial request
    console.log('Document upload request received with headers:', req.headers);
    
    // Generate upload ID for progress tracking
    const uploadId = UploadProgressService.generateUploadId();
    
    // Set initial progress to 0%
    UploadProgressService.updateProgress(uploadId, 0, 'preparing', 'Preparing for upload...');
    
    // Wrap the multer callback in a Promise to handle async operations properly
    const result = await new Promise((resolve, reject) => {
      upload.single('document')(req, res, async function (err) {
        if (err instanceof multer.MulterError) {
          console.error('Multer error:', err);
          // Update progress with error
          UploadProgressService.updateProgress(uploadId, 0, 'error', `Upload error: ${err.message}`);
          if (err.code === 'LIMIT_FILE_SIZE') {
            return reject(new Error('File too large. Maximum size is 2GB.'));
          } else if (err.code === 'LIMIT_FIELD_KEY' || err.code === 'LIMIT_FIELD_VALUE' || err.code === 'LIMIT_FIELDS') {
            return reject(new Error(`Upload field limit exceeded: ${err.message}`));
          } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
            return reject(new Error(`Unexpected file field: ${err.field}`));
          }
          return reject(new Error(`Upload error: ${err.message}`));
        } else if (err) {
          console.error('General upload error:', err);
          // Update progress with error
          UploadProgressService.updateProgress(uploadId, 0, 'error', `Upload failed: ${err.message}`);
          return reject(new Error(`Upload failed: ${err.message}`));
        }

        // Check if file was uploaded
        if (!req.file) {
          console.error('No file received in upload request');
          // Update progress with error
          UploadProgressService.updateProgress(uploadId, 0, 'error', 'No document file provided');
          return reject(new Error('No document file provided'));
        }

        resolve(req.file);
      });
    });

    // Log the received fields for debugging
    console.log('Received document upload with fields:', Object.keys(req.body));
    console.log('File details:', {
      originalName: result.originalname,
      size: result.size,
      mimetype: result.mimetype,
      encoding: result.encoding,
      fieldname: result.fieldname,
      destination: result.destination, // Will be undefined for memory storage
      filename: result.filename // Will be undefined for memory storage
    });

    // Check if it's actually a document - allow both document MIME types and files with generic MIME but valid document extensions
    const fileExtension = result.originalname.toLowerCase().split('.').pop();
    const validDocumentExtensions = ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx', 'rtf', 'odt', 'ods', 'odp'];
    
    if (!result.mimetype.startsWith('application/') && 
        !result.mimetype.startsWith('text/') && 
        !validDocumentExtensions.includes(fileExtension)) {
      // Update progress with error
      UploadProgressService.updateProgress(uploadId, 0, 'error', `Only document files are allowed. Received: ${result.mimetype} (${result.originalname})`);
      return sendError(res, `Only document files are allowed for this endpoint. Received: ${result.mimetype} (${result.originalname})`, 400);
    }

    try {
      // Update progress to indicate upload started
      UploadProgressService.updateProgress(uploadId, 10, 'uploading_to_s3', 'Uploading to S3...');
      
      // Upload to AWS S3
      const uploadResult = await s3Service.uploadDocument(
        result.buffer,
        result.originalname,
        result.mimetype
      );
      
      // Update progress to indicate completion
      UploadProgressService.updateProgress(uploadId, 100, 'completed', 'Upload completed successfully!');

      // Check if this document is intended for exam creation
      if (req.body.createExamFromDocument === 'true' && req.body.examType) {
        // Process document with AI to create exam
        const GroqService = require('../services/groq_service');
        const Exam = require('../models/Exam');
        const Question = require('../models/Question');
        const DocumentProcessingService = require('../services/document_processing_service');
        
        if (GroqService.isConfigured()) {
          try {
            // Extract text content from the uploaded document
            const documentContent = await DocumentProcessingService.extractTextFromDocument(
              result.buffer,
              result.mimetype
            );
            
            // Use Groq to extract and organize questions from the document
            // Pass the file object for processing
            const fileForAI = {
              path: result.path || null,
              buffer: result.buffer,
              mimetype: result.mimetype,
              originalName: result.originalName
            };
            
            const processedQuestions = await GroqService.extractQuestionsFromDocument(
              fileForAI,
              req.body.examType
            );
            
            // Generate exam title if not provided
            let examTitle = req.body.title || '';
            if (!examTitle) {
              examTitle = await GroqService.generateExamTitle(documentContent);
            }
            
            // Create exam with extracted questions
            const exam = await Exam.create({
              courseId: req.body.courseId,
              sectionId: req.body.sectionId,
              title: examTitle,
              type: req.body.examType,
              passingScore: parseInt(req.body.passingScore) || 50,
              timeLimit: parseInt(req.body.timeLimit) || 0,
              isPublished: false,
              questionsCount: processedQuestions.length
            });

            // Create questions from AI-processed content
            if (processedQuestions && processedQuestions.length > 0) {
              const questionsWithExamId = processedQuestions.map(q => {
                // Handle different question types properly
                let correctAnswer = q.correctAnswer;
                let options = q.options || [];
                
                // For MCQ and True/False, convert correct answer to index
                if ((q.type === 'mcq' || q.type === 'true_false') && options.length > 0) {
                  const correctAnswerIndex = options.indexOf(q.correctAnswer);
                  correctAnswer = correctAnswerIndex !== -1 ? correctAnswerIndex : 0;
                }
                
                return {
                  question: q.question,
                  type: q.type || 'mcq', // Ensure type is always set
                  options: options,
                  correctAnswer: correctAnswer,
                  points: q.points || 1,
                  examId: exam._id
                };
              });
              await Question.insertMany(questionsWithExamId);
            }

            // Send success response with exam information
            return sendSuccess(res, {
              documentUrl: uploadResult.url,
              s3Key: uploadResult.key,
              bucket: uploadResult.bucket,
              documentId: uploadResult.key,
              originalName: result.originalname,
              size: result.size,
              mimetype: result.mimetype,
              uploadId: uploadId,
              examCreated: true,
              exam: exam,
            }, 'Document uploaded and exam created successfully from document content');
          } catch (aiError) {
            console.error('Error processing document with AI for exam creation:', aiError);
            // Continue with normal document upload if AI processing fails
            // Don't return here, let it fall through to normal document upload
          }
        } else {
          // Groq AI not configured, return error if trying to create exam from document
          return sendError(res, 'Groq AI is not configured. Please set GROQ_API_KEY in environment variables.', 400);
        }
        
        // If we reach here, AI processing failed, continue with normal document upload
        console.log('AI exam creation failed, continuing with normal document upload');
      }

      // Note: Lessons are no longer automatically created with document uploads.
      // The organized notes functionality is available but lessons must be created separately
      // through the lesson creation endpoint to maintain proper workflow.

      return sendSuccess(res, {
        documentUrl: uploadResult.url,
        s3Key: uploadResult.key,
        bucket: uploadResult.bucket,
        documentId: uploadResult.key, // For compatibility with existing lesson model
        originalName: result.originalname,
        size: result.size,
        mimetype: result.mimetype,
        uploadId: uploadId, // Include upload ID for progress tracking
        // Include any additional fields from the request body
        ...(req.body.courseId && { courseId: req.body.courseId }),
        ...(req.body.sectionId && { sectionId: req.body.sectionId }),
        ...(req.body.title && { title: req.body.title }),
        ...(req.body.description && { description: req.body.description }),
        ...(req.body.duration && { duration: req.body.duration })
      }, 'Document uploaded successfully');
    } catch (s3Error) {
      // Update progress with error
      UploadProgressService.updateProgress(uploadId, 0, 'error', `S3 upload failed: ${s3Error.message}`);
      console.error('S3 upload error:', s3Error);
      return sendError(res, 'Failed to upload document to storage', 500, s3Error.message);
    }
  } catch (error) {
    console.error('Document upload error:', error);
    return sendError(res, 'Document upload failed', 500, error.message);
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
  uploadDocument,
  generatePresignedUrl,
  getUploadProgress
};