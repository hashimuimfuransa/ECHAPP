const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const User = require('../models/User');
const { sendSuccess, sendError } = require('../utils/response.utils');

// Service to handle course expiration
class CourseExpirationService {
  // Check for expired enrollments and process them
  static async checkExpiredEnrollments() {
    try {
      console.log('Checking for expired course enrollments...');
      
      const now = new Date();
      
      // Find all enrollments where access has expired
      const expiredEnrollments = await Enrollment.find({
        accessExpirationDate: { $ne: null, $lt: now }
      });
      
      console.log(`Found ${expiredEnrollments.length} expired enrollments`);
      
      for (const enrollment of expiredEnrollments) {
        // Only un-enroll (delete) if the course is not completed
        // If it's completed, they should keep the enrollment record for their certificates/history
        // but they will still be blocked from accessing content by the isEnrollmentExpired checks
        if (enrollment.completionStatus !== 'completed') {
          await this.processExpiredEnrollment(enrollment);
        } else {
          console.log(`Skipping deletion of completed enrollment for user ${enrollment.userId} in course ${enrollment.courseId}`);
        }
      }
      
      return {
        success: true,
        processedCount: expiredEnrollments.length,
        message: `Processed ${expiredEnrollments.length} expired enrollments`
      };
    } catch (error) {
      console.error('Error checking expired enrollments:', error);
      throw error;
    }
  }
  
  // Process a single expired enrollment
  static async processExpiredEnrollment(enrollment) {
    try {
      console.log(`Processing expired enrollment for user ${enrollment.userId} in course ${enrollment.courseId}`);
      
      // Get user and course details for notifications
      const user = await User.findById(enrollment.userId);
      const course = await Course.findById(enrollment.courseId);
      
      // Remove the enrollment
      await Enrollment.findByIdAndDelete(enrollment._id);
      
      console.log(`Removed expired enrollment for user ${user?.email} from course ${course?.title}`);
      
      // Notify the user that their access has expired
      if (user && course) {
        try {
          // Import the controller class from the exported instance's constructor
          const NotificationController = require('../controllers/notification.controller').constructor;
          
          if (typeof NotificationController.createCourseExpirationNotification === 'function') {
            await NotificationController.createCourseExpirationNotification(
              enrollment.userId, 
              course.title, 
              enrollment.courseId
            );
            console.log(`Sent expiration notification to user ${user.email} for course ${course.title}`);
          }
        } catch (notificationError) {
          console.error('Error sending expiration notification:', notificationError);
        }
      }
      
    } catch (error) {
      console.error(`Error processing expired enrollment ${enrollment._id}:`, error);
      throw error;
    }
  }
  
  // Schedule periodic checks for expired enrollments
  static scheduleExpirationChecks(intervalMinutes = 60) {
    console.log(`Scheduling course expiration checks every ${intervalMinutes} minutes`);
    
    // Run initial check
    this.checkExpiredEnrollments().catch(console.error);
    
    // Set up interval to run checks periodically
    setInterval(async () => {
      try {
        await this.checkExpiredEnrollments();
      } catch (error) {
        console.error('Scheduled expiration check failed:', error);
      }
    }, intervalMinutes * 60 * 1000); // Convert minutes to milliseconds
  }
}

module.exports = CourseExpirationService;