const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const Payment = require('../models/Payment');
const User = require('../models/User');
const Certificate = require('../models/Certificate');
const emailService = require('../services/email.service');
const notificationController = require('./notification.controller');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Helper function to check if enrollment access has expired
const isEnrollmentExpired = (enrollment) => {
  if (!enrollment.accessExpirationDate) {
    return false; // No expiration set, access is unlimited
  }
  
  const currentDate = new Date();
  return currentDate > enrollment.accessExpirationDate;
};

// Enroll in a course
const enrollInCourse = async (req, res) => {
  try {
    const { courseId } = req.body;
    const userId = req.user.id;

    // Check if course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    // Check if already enrolled
    const existingEnrollment = await Enrollment.findOne({ userId, courseId });
    if (existingEnrollment) {
      return sendError(res, 'Already enrolled in this course', 400);
    }

    // Check if course is free or payment exists for paid courses
    if (course.price > 0) {
      const payment = await Payment.findOne({ 
        userId, 
        courseId, 
        status: 'completed' 
      });
      
      if (!payment) {
        return sendError(res, 'Payment required for this course', 400);
      }
    }

    // Calculate access expiration date based on course duration
    let accessExpirationDate = null;
    if (course.accessDuration) {
      accessExpirationDate = new Date();
      const unit = course.accessDurationUnit || 'days';
      const value = course.accessDuration;
      
      switch (unit) {
        case 'hours':
          accessExpirationDate.setHours(accessExpirationDate.getHours() + value);
          break;
        case 'days':
          accessExpirationDate.setDate(accessExpirationDate.getDate() + value);
          break;
        case 'weeks':
          accessExpirationDate.setDate(accessExpirationDate.getDate() + (value * 7));
          break;
        case 'months':
          accessExpirationDate.setMonth(accessExpirationDate.getMonth() + value);
          break;
        case 'years':
          accessExpirationDate.setFullYear(accessExpirationDate.getFullYear() + value);
          break;
        default:
          accessExpirationDate.setDate(accessExpirationDate.getDate() + value);
      }
    } else if (course.accessDurationDays) {
      accessExpirationDate = new Date();
      accessExpirationDate.setDate(accessExpirationDate.getDate() + course.accessDurationDays);
    }

    // Create enrollment
    const enrollment = await Enrollment.create({
      userId,
      courseId,
      enrollmentDate: new Date(),
      completionStatus: 'enrolled',
      accessExpirationDate
    });

    // Update course enrollment count
    await Course.findByIdAndUpdate(courseId, { $inc: { enrollmentCount: 1 } });

    // Get user and course details for email notification
    const user = await User.findById(userId).select('fullName email');
    
    // Send enrollment confirmation email
    try {
      await emailService.sendEnrollmentConfirmation(user.email, user, course);
      console.log(`Enrollment confirmation email sent to user: ${user.email}`);
    } catch (emailError) {
      console.error('Error sending enrollment confirmation email:', emailError);
      // Don't fail the enrollment if email sending fails
    }

    // Send in-app and push notification (Professional way)
    try {
      const NotificationController = require('./notification.controller').constructor;
      await NotificationController.createCourseEnrollmentNotification(userId, course.title, courseId);
    } catch (notificationError) {
      console.error('Error creating enrollment notification:', notificationError);
    }

    sendSuccess(res, enrollment, 'Successfully enrolled in course', 201);
  } catch (error) {
    sendError(res, 'Failed to enroll in course', 500, error.message);
  }
};

// Get user's enrolled courses
const getMyCourses = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const enrollments = await Enrollment.find({ userId })
      .populate({
        path: 'courseId',
        select: 'title description price duration level thumbnail isPublished',
        populate: {
          path: 'createdBy',
          select: 'fullName'
        }
      })
      .sort({ enrollmentDate: -1 });

    // Filter out expired enrollments, but keep completed courses even if access has expired
    const activeEnrollments = enrollments.filter(enrollment => {
      // If it's not expired, it's active
      if (!isEnrollmentExpired(enrollment)) return true;
      
      // If it IS expired, only keep it if it was completed
      return enrollment.completionStatus === 'completed';
    });

    sendSuccess(res, activeEnrollments, 'Enrolled courses retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve enrolled courses', 500, error.message);
  }
};

// Submit course feedback
const submitCourseFeedback = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { rating, feedback } = req.body;
    const userId = req.user.id;

    if (!rating || rating < 1 || rating > 5) {
      return sendError(res, 'Invalid rating. Must be between 1 and 5', 400);
    }

    const enrollment = await Enrollment.findOne({ userId, courseId });
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found for this course');
    }

    enrollment.rating = rating;
    enrollment.feedback = feedback;
    await enrollment.save();

    // Update course average rating
    const mongoose = require('mongoose');
    const stats = await Enrollment.aggregate([
      { $match: { courseId: new mongoose.Types.ObjectId(courseId), rating: { $ne: null } } },
      { $group: { _id: '$courseId', averageRating: { $avg: '$rating' } } }
    ]);

    if (stats.length > 0) {
      await Course.findByIdAndUpdate(courseId, { averageRating: stats[0].averageRating });
    }

    sendSuccess(res, enrollment, 'Feedback submitted successfully');
  } catch (error) {
    sendError(res, 'Failed to submit feedback', 500, error.message);
  }
};

// Get enrollment progress
const getEnrollmentProgress = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const enrollment = await Enrollment.findOne({ 
      _id: id, 
      userId 
    }).populate('courseId', 'title');

    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    if (isEnrollmentExpired(enrollment)) {
      return sendError(res, 'Access to this course has expired', 403);
    }

    sendSuccess(res, enrollment, 'Enrollment progress retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve enrollment progress', 500, error.message);
  }
};

// Update enrollment progress
const updateEnrollmentProgress = async (req, res) => {
  try {
    const { id } = req.params;
    const { lessonId, completed } = req.body;
    const userId = req.user.id;

    const enrollment = await Enrollment.findOne({ 
      _id: id, 
      userId 
    });

    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    if (isEnrollmentExpired(enrollment)) {
      return sendError(res, 'Access to this course has expired', 403);
    }

    if (completed && !enrollment.completedLessons.includes(lessonId)) {
      enrollment.completedLessons.push(lessonId);
      // Update progress percentage (this would be calculated based on total lessons)
      enrollment.progress = Math.min(100, enrollment.completedLessons.length * 10); // Simple calculation
      
      if (enrollment.progress === 100) {
        enrollment.completionStatus = 'completed';
        enrollment.certificateEligible = true;

        // Send Achievement Notification
        try {
          const NotificationController = notificationController.constructor;
          await NotificationController.createAchievementNotification(
            userId, 
            `Completed Course: ${enrollment.courseId.title}`
          );
        } catch (notificationError) {
          console.error('Error sending achievement notification:', notificationError);
        }
      } else if (enrollment.progress > 0) {
        enrollment.completionStatus = 'in-progress';
      }
    }

    await enrollment.save();

    // Update last active status for user
    await User.findByIdAndUpdate(userId, { lastActive: new Date() });
    
    sendSuccess(res, enrollment, 'Enrollment progress updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update enrollment progress', 500, error.message);
  }
};

// Get user's certificates
const getCertificates = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const certificates = await Certificate.find({ 
      userId,
      isValid: true 
    })
      .populate({
        path: 'courseId',
        select: 'title description duration level thumbnail createdBy'
      })
      .populate({
        path: 'examId',
        select: 'title type'
      })
      .sort({ issuedDate: -1 });

    sendSuccess(res, certificates, 'Certificates retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve certificates', 500, error.message);
  }
};

// Check if user is eligible for certificate for a specific course
const checkCertificateEligibility = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId 
    });
    
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    const isEligible = enrollment.certificateEligible && enrollment.completionStatus === 'completed';
    
    sendSuccess(res, { 
      eligible: isEligible,
      completionStatus: enrollment.completionStatus,
      progress: enrollment.progress,
      certificateEligible: enrollment.certificateEligible
    }, 'Certificate eligibility checked successfully');
  } catch (error) {
    sendError(res, 'Failed to check certificate eligibility', 500, error.message);
  }
};

// Download certificate for a course (placeholder)
const downloadCertificate = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId,
      certificateEligible: true
    }).populate('courseId', 'title');
    
    if (!enrollment) {
      return sendNotFound(res, 'Certificate not found or not eligible');
    }
    
    // In a real implementation, this would generate and return a PDF certificate
    // For now, we'll return a placeholder download URL
    const downloadUrl = `${req.protocol}://${req.get('host')}/api/enrollments/${courseId}/certificate/download/file`;
    
    sendSuccess(res, { 
      downloadUrl,
      courseTitle: enrollment.courseId.title,
      completionDate: enrollment.updatedAt,
      studentName: req.user.fullName || req.user.email
    }, 'Certificate download URL generated');
  } catch (error) {
    sendError(res, 'Failed to generate certificate download', 500, error.message);
  }
};

// Check if user has access to a course (handles expiration)
const checkCourseAccess = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    
    // Find enrollment
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId 
    }).populate('courseId', 'title accessDurationDays');
    
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    // Check if access has expired
    const isExpired = isEnrollmentExpired(enrollment);
    
    const responseData = {
      hasAccess: !isExpired,
      enrollmentId: enrollment._id,
      courseId: enrollment.courseId,
      enrollmentDate: enrollment.enrollmentDate,
      accessExpirationDate: enrollment.accessExpirationDate,
      courseTitle: enrollment.courseId.title,
      accessDurationDays: enrollment.courseId.accessDurationDays,
      completedLessons: enrollment.completedLessons,
      progress: enrollment.progress,
      completionStatus: enrollment.completionStatus,
      rating: enrollment.rating,
      feedback: enrollment.feedback,
    };
    
    if (isExpired) {
      responseData.expiredAt = enrollment.accessExpirationDate;
      responseData.message = 'Access to this course has expired';
    }
    
    const statusCode = isExpired ? 403 : 200;
    const message = isExpired ? 'Access expired' : 'Access granted';
    
    res.status(statusCode).send({
      success: !isExpired,
      data: responseData,
      message: message
    });
    
  } catch (error) {
    sendError(res, 'Failed to check course access', 500, error.message);
  }
}

// Download certificate file
const downloadCertificateFile = async (req, res) => {
  try {
    const { certificateId } = req.params;
    const userId = req.user.id;
    
    // Find the certificate
    const certificate = await Certificate.findOne({ 
      _id: certificateId,
      userId,
      isValid: true
    }).populate('courseId', 'title description');
    
    if (!certificate) {
      return sendNotFound(res, 'Certificate not found or not authorized');
    }
    
    // Check if the file exists
    const fs = require('fs');
    const path = require('path');
    const Result = require('../models/Result');
    const CertificatePDFService = require('../services/certificate_pdf_service');
    
    if (!fs.existsSync(certificate.certificatePdfPath)) {
      console.log(`Certificate file missing locally: ${certificate.certificatePdfPath}. Attempting to re-generate...`);
      
      try {
        // Find the result to get totalPoints
        const result = await Result.findOne({ userId, examId: certificate.examId });
        
        if (!result) {
          console.error(`Original exam result not found for certificate ${certificateId}, user ${userId}`);
          return sendNotFound(res, 'Certificate file not found and cannot be re-generated (result missing)');
        }
        
        const user = await User.findById(userId).select('fullName email');
        if (!user) {
          return sendNotFound(res, 'User not found, cannot re-generate certificate');
        }
        
        // Re-generate PDF certificate
        const newPdfPath = await CertificatePDFService.generateCertificatePDF({
          studentName: user.fullName,
          userFullName: user.fullName,
          courseTitle: certificate.courseId.title,
          courseDescription: certificate.courseId.description,
          score: certificate.score,
          totalPoints: result.totalPoints,
          percentage: certificate.percentage,
          issuedDate: certificate.issuedDate,
          serialNumber: certificate.serialNumber,
          userId,
          examId: certificate.examId
        });
        
        // Update certificate record with the new path
        certificate.certificatePdfPath = newPdfPath;
        await certificate.save();
        
        console.log(`Certificate re-generated and updated: ${newPdfPath}`);
      } catch (genError) {
        console.error('Error re-generating certificate:', genError);
        return sendError(res, 'Certificate file not found and re-generation failed', 500, genError.message);
      }
    }
    
    // Set headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="certificate_${certificate.courseId.title.replace(/[^a-zA-Z0-9]/g, '_')}.pdf"`);
    
    // Stream the file
    const fileStream = fs.createReadStream(certificate.certificatePdfPath);
    fileStream.pipe(res);
    
  } catch (error) {
    console.error('Error downloading certificate file:', error);
    sendError(res, 'Failed to download certificate', 500, error.message);
  }
};

// Verify certificate by serial number (Public endpoint)
const verifyCertificate = async (req, res) => {
  try {
    const { serialNumber } = req.params;
    
    if (!serialNumber) {
      return sendError(res, 'Serial number is required', 400);
    }
    
    // Find the certificate and populate relevant data
    const certificate = await Certificate.findOne({ 
      serialNumber,
      isValid: true
    })
    .populate({
      path: 'userId',
      select: 'fullName email profileImage'
    })
    .populate({
      path: 'courseId',
      select: 'title description thumbnail duration level'
    });
    
    if (!certificate) {
      return sendNotFound(res, 'Certificate not found or invalid');
    }
    
    // Structure the verification data
    const verificationData = {
      serialNumber: certificate.serialNumber,
      studentName: certificate.userId ? certificate.userId.fullName : 'Valued Student',
      studentProfileImage: certificate.userId ? certificate.userId.profileImage : null,
      courseTitle: certificate.courseId ? certificate.courseId.title : 'Course',
      courseDescription: certificate.courseId ? certificate.courseId.description : '',
      courseThumbnail: certificate.courseId ? certificate.courseId.thumbnail : null,
      issuedDate: certificate.issuedDate,
      percentage: certificate.percentage,
      isValid: certificate.isValid,
      verificationStatus: 'VERIFIED',
      institution: 'Excellence Coaching Hub'
    };
    
    sendSuccess(res, verificationData, 'Certificate verified successfully');
  } catch (error) {
    console.error('Error verifying certificate:', error);
    sendError(res, 'Failed to verify certificate', 500, error.message);
  }
};

module.exports = {
  enrollInCourse,
  getMyCourses,
  getEnrollmentProgress,
  updateEnrollmentProgress,
  getCertificates,
  checkCertificateEligibility,
  downloadCertificate,
  submitCourseFeedback,
  checkCourseAccess,
  downloadCertificateFile,
  verifyCertificate
};