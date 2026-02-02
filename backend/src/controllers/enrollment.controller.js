const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const Payment = require('../models/Payment');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

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

    // Create enrollment
    const enrollment = await Enrollment.create({
      userId,
      courseId,
      enrollmentDate: new Date(),
      completionStatus: 'enrolled'
    });

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

    sendSuccess(res, enrollments, 'Enrolled courses retrieved successfully');
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

module.exports = {
  enrollInCourse,
  getMyCourses,
  getEnrollmentProgress,
  updateEnrollmentProgress
};