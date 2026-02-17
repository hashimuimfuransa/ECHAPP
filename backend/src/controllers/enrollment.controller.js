const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const Payment = require('../models/Payment');
const User = require('../models/User');
const emailService = require('../services/email.service');
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
    if (course.accessDurationDays) {
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

    // Filter out expired enrollments
    const activeEnrollments = enrollments.filter(enrollment => !isEnrollmentExpired(enrollment));

    sendSuccess(res, activeEnrollments, 'Enrolled courses retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve enrolled courses', 500, error.message);
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
      } else if (enrollment.progress > 0) {
        enrollment.completionStatus = 'in-progress';
      }
    }

    await enrollment.save();
    
    sendSuccess(res, enrollment, 'Enrollment progress updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update enrollment progress', 500, error.message);
  }
};

// Get user's certificates
const getCertificates = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const enrollments = await Enrollment.find({ 
      userId, 
      certificateEligible: true 
    })
      .populate({
        path: 'courseId',
        select: 'title description duration level thumbnail isPublished createdBy',
        populate: {
          path: 'createdBy',
          select: 'fullName'
        }
      })
      .sort({ updatedAt: -1 });

    sendSuccess(res, enrollments, 'Certificates retrieved successfully');
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
};

module.exports = {
  enrollInCourse,
  getMyCourses,
  getEnrollmentProgress,
  updateEnrollmentProgress,
  getCertificates,
  checkCertificateEligibility,
  downloadCertificate,
  checkCourseAccess
};