const User = require('../models/User');
const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const notificationController = require('../controllers/notification.controller');

class NotificationSchedulerService {
  static async checkInactivityAndProgress() {
    try {
      console.log('Running scheduled notification checks...');
      
      const now = new Date();
      const threeDaysAgo = new Date(now - 3 * 24 * 60 * 60 * 1000);
      const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);

      // 1. Inactivity Reminders (Users inactive for 3-5 days)
      const inactiveUsers = await User.find({
        lastActive: { $lt: threeDaysAgo, $gte: new Date(now - 6 * 24 * 60 * 60 * 1000) },
        role: 'student'
      });

      for (const user of inactiveUsers) {
        // Find their most recently enrolled course with progress < 100%
        const enrollment = await Enrollment.findOne({
          userId: user._id,
          progress: { $lt: 100 }
        }).populate('courseId').sort({ updatedAt: -1 });

        if (enrollment && enrollment.courseId) {
          const NotificationController = notificationController.constructor;
          await NotificationController.createInactivityReminder(
            user._id,
            enrollment.courseId.title,
            enrollment.courseId._id
          );
        }
      }

      // 2. Weekly Progress Summary (Run once a week - e.g. on Sundays)
      if (now.getDay() === 0) { // 0 is Sunday
        const students = await User.find({ role: 'student' });
        
        for (const user of students) {
          // Count lessons completed in the last 7 days
          // Note: This assumes completedLessons tracking includes timestamps, 
          // but based on the model it's just an array of IDs.
          // Let's check enrollment updatedAt as a proxy or just send a general "Keep it up"
          
          const recentEnrollments = await Enrollment.find({
            userId: user._id,
            updatedAt: { $gte: sevenDaysAgo }
          });

          let weeklyLessonsCount = 0;
          recentEnrollments.forEach(e => {
            // This is an estimation since we don't have per-lesson timestamps
            // In a real app, you'd track when each lesson was completed.
            if (e.progress > 0) weeklyLessonsCount += Math.floor(e.progress / 10); 
          });

          if (weeklyLessonsCount > 0) {
            const NotificationController = notificationController.constructor;
            await NotificationController.createWeeklyProgressSummary(user._id, weeklyLessonsCount);
          }
        }
      }

      console.log(`Scheduled notification checks completed. Processed ${inactiveUsers.length} inactive users.`);
    } catch (error) {
      console.error('Error in scheduled notifications:', error);
    }
  }

  static schedule(intervalHours = 24) {
    console.log(`Scheduling notification checks every ${intervalHours} hours`);
    
    // Run initial check after a short delay to not block startup
    setTimeout(() => {
      this.checkInactivityAndProgress().catch(console.error);
    }, 10000);
    
    // Set up interval
    setInterval(async () => {
      try {
        await this.checkInactivityAndProgress();
      } catch (error) {
        console.error('Scheduled notification check failed:', error);
      }
    }, intervalHours * 60 * 60 * 1000);
  }
}

module.exports = NotificationSchedulerService;
