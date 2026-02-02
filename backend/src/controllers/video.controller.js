const cloudflareService = require('../services/cloudflare.service');
const Lesson = require('../models/Lesson');
const Enrollment = require('../models/Enrollment');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

// Get signed URL for video playback
const getVideoStreamUrl = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const userId = req.user.id;

    // Find the lesson
    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }

    // Check if lesson has a video
    if (!lesson.videoId) {
      return sendNotFound(res, 'No video available for this lesson');
    }

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId: lesson.courseId 
    });
    
    if (!enrollment) {
      return sendForbidden(res, 'You must be enrolled in this course to access the video');
    }

    // Generate signed URL
    const signedUrl = cloudflareService.generateSignedUrl(lesson.videoId, 10); // 10 minutes expiration

    sendSuccess(res, {
      signedUrl,
      lessonId: lesson._id,
      courseId: lesson.courseId,
      expiration: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes from now
    }, 'Video stream URL generated successfully');
  } catch (error) {
    sendError(res, 'Failed to generate video stream URL', 500, error.message);
  }
};

// Upload video (admin only)
const uploadVideo = async (req, res) => {
  try {
    // In a real implementation, you would handle file upload
    // For now, we'll simulate the upload process
    
    const { filename } = req.body;
    
    if (!filename) {
      return sendError(res, 'Filename is required', 400);
    }

    const result = await cloudflareService.uploadVideo(null, filename);
    
    sendSuccess(res, result, 'Video upload initiated', 201);
  } catch (error) {
    sendError(res, 'Failed to upload video', 500, error.message);
  }
};

// Get video details
const getVideoDetails = async (req, res) => {
  try {
    const { videoId } = req.params;
    
    const details = await cloudflareService.getVideoDetails(videoId);
    
    sendSuccess(res, details, 'Video details retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve video details', 500, error.message);
  }
};

module.exports = {
  getVideoStreamUrl,
  uploadVideo,
  getVideoDetails
};