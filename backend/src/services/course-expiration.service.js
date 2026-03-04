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
        // ALWAYS un-enroll (delete) regardless of completion status as per user request
        await this.processExpiredEnrollment(enrollment);
      }
      
      // Also check for upcoming expirations to send warnings
      await this.sendExpirationWarnings();
      
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

  // Send warnings for enrollments expiring in 1 or 5 days
  static async sendExpirationWarnings() {
    try {
      console.log('Checking for upcoming course expirations...');
      const now = new Date();
      const todayStart = new Date(now);
      todayStart.setHours(0, 0, 0, 0);
      
      const warningDays = [1, 5];
      const Notification = require('../models/Notification');
      const NotificationController = require('../controllers/notification.controller').constructor;
      
      for (const days of warningDays) {
        const warningDateStart = new Date(todayStart);
        warningDateStart.setDate(todayStart.getDate() + days);
        
        const warningDateEnd = new Date(warningDateStart);
        warningDateEnd.setHours(23, 59, 59, 999);
        
        const upcomingExpirations = await Enrollment.find({
          accessExpirationDate: { $gte: warningDateStart, $lte: warningDateEnd }
        }).populate('courseId');
        
        console.log(`Found ${upcomingExpirations.length} enrollments expiring in ${days} days`);
        
        for (const enrollment of upcomingExpirations) {
          if (!enrollment.courseId) continue;
          
          // Check if warning already sent today for this enrollment and day count
          const alreadySent = await Notification.findOne({
            userId: enrollment.userId,
            'data.courseId': enrollment.courseId._id,
            'data.type': 'course_expiration_warning',
            'data.daysLeft': days,
            createdAt: { $gte: todayStart }
          });
          
          if (!alreadySent) {
            if (typeof NotificationController.createCourseExpirationWarning === 'function') {
              await NotificationController.createCourseExpirationWarning(
                enrollment.userId,
                enrollment.courseId.title,
                days,
                enrollment.courseId._id
              );
              console.log(`Sent ${days}-day expiration warning to user ${enrollment.userId} for course ${enrollment.courseId.title}`);
            }
          }
        }
      }
    } catch (error) {
      console.error('Error sending expiration warnings:', error);
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