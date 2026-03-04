const Notification = require('../models/Notification');
const User = require('../models/User');
const admin = require('firebase-admin');

class NotificationController {
  // Get all notifications for current user
  async getNotifications(req, res) {
    try {
      const userId = req.user.id; // Assuming auth middleware sets req.user
      
      const notifications = await Notification.getUserNotifications(userId);
      
      res.status(200).json({
        success: true,
        message: 'Notifications fetched successfully',
        data: {
          notifications: notifications.map(notification => ({
            id: notification._id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            isRead: notification.isRead,
            data: notification.data,
            timestamp: notification.createdAt,
            readAt: notification.readAt
          })),
          unreadCount: notifications.filter(n => !n.isRead).length
        }
      });
    } catch (error) {
      console.error('Error fetching notifications:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch notifications',
        error: error.message
      });
    }
  }

  // Get unread notifications count
  async getUnreadCount(req, res) {
    try {
      const userId = req.user.id;
      
      const unreadCount = await Notification.getUnreadCount(userId);
      
      res.status(200).json({
        success: true,
        message: 'Unread count fetched successfully',
        data: { unreadCount }
      });
    } catch (error) {
      console.error('Error fetching unread count:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch unread count',
        error: error.message
      });
    }
  }

  // Mark a notification as read
  async markAsRead(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      
      const notification = await Notification.markAsRead(id, userId);
      
      res.status(200).json({
        success: true,
        message: 'Notification marked as read',
        data: {
          id: notification._id,
          isRead: notification.isRead,
          readAt: notification.readAt
        }
      });
    } catch (error) {
      console.error('Error marking notification as read:', error);
      res.status(400).json({
        success: false,
        message: 'Failed to mark notification as read',
        error: error.message
      });
    }
  }

  // Mark all notifications as read
  async markAllAsRead(req, res) {
    try {
      const userId = req.user.id;
      
      const modifiedCount = await Notification.markAllAsRead(userId);
      
      res.status(200).json({
        success: true,
        message: `Marked ${modifiedCount} notifications as read`,
        data: { modifiedCount }
      });
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to mark all notifications as read',
        error: error.message
      });
    }
  }

  // Create a notification (admin/internal use)
  async createNotification(req, res) {
    try {
      const { title, message, type, data, sendPush = false } = req.body;
      
      // Validate required fields
      if (!title || !message) {
        return res.status(400).json({
          success: false,
          message: 'title and message are required'
        });
      }
      
      // Use the authenticated user's ID
      const userId = req.user.id;
      
      const notification = await Notification.createNotification({
        userId,
        title,
        message,
        type: type || 'info',
        data: data || {}
      });
      
      // Send push notification if requested
      if (sendPush) {
        await this.sendPushNotification(userId, title, message, data);
      }
      
      res.status(201).json({
        success: true,
        message: 'Notification created successfully',
        data: {
          id: notification._id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          isRead: notification.isRead,
          timestamp: notification.createdAt
        }
      });
    } catch (error) {
      console.error('Error creating notification:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create notification',
        error: error.message
      });
    }
  }

  // Delete a notification
  async deleteNotification(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      
      const notification = await Notification.findOneAndDelete({
        _id: id,
        userId: userId
      });
      
      if (!notification) {
        return res.status(404).json({
          success: false,
          message: 'Notification not found'
        });
      }
      
      res.status(200).json({
        success: true,
        message: 'Notification deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting notification:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete notification',
        error: error.message
      });
    }
  }

  // Get notification by ID
  async getNotificationById(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      
      const notification = await Notification.findOne({
        _id: id,
        userId: userId
      });
      
      if (!notification) {
        return res.status(404).json({
          success: false,
          message: 'Notification not found'
        });
      }
      
      res.status(200).json({
        success: true,
        message: 'Notification fetched successfully',
        data: {
          id: notification._id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          isRead: notification.isRead,
          data: notification.data,
          timestamp: notification.createdAt,
          readAt: notification.readAt
        }
      });
    } catch (error) {
      console.error('Error fetching notification:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch notification',
        error: error.message
      });
    }
  }

  // Get all system notifications for admin
  async getAdminNotifications(req, res) {
    try {
      const recentCutoff = new Date(Date.now() - 48 * 60 * 60 * 1000); // Last 48 hours for virtual notifications
      
      // 1. Fetch real notifications for the admin user
      const adminNotifications = await Notification.getUserNotifications(req.user.id);
      
      // 2. Fetch pending payments as virtual notifications (no time limit on pending)
      const Payment = require('../models/Payment');
      const pendingPayments = await Payment.find({ status: 'pending' })
        .populate('userId', 'fullName email')
        .populate('courseId', 'title')
        .sort({ createdAt: -1 });
      
      const paymentNotifications = pendingPayments.map(payment => ({
        id: `payment_${payment._id}`,
        title: 'Pending Payment Approval',
        message: `${payment.userId?.fullName || 'A student'} is waiting for approval for "${payment.courseId?.title || 'a course'}" (RWF ${payment.amount.toLocaleString()})`,
        type: 'payment',
        isRead: false,
        severity: 'high',
        data: { 
          paymentId: payment._id, 
          userId: payment.userId?._id,
          courseId: payment.courseId?._id 
        },
        timestamp: payment.createdAt,
        isVirtual: true
      }));

      // 3. Fetch new user registrations
      const newUsers = await User.find({ 
        createdAt: { $gte: recentCutoff },
        role: 'student'
      }).sort({ createdAt: -1 });

      const newUserNotifications = newUsers.map(user => ({
        id: `user_${user._id}`,
        title: 'New Student Registered',
        message: `${user.fullName} (${user.email}) just joined the platform.`,
        type: 'user',
        isRead: false,
        severity: 'info',
        data: { userId: user._id },
        timestamp: user.createdAt,
        isVirtual: true
      }));

      // 4. Fetch recent exam submissions
      const Result = require('../models/Result');
      const recentResults = await Result.find({ createdAt: { $gte: recentCutoff } })
        .populate('userId', 'fullName')
        .populate('examId', 'title')
        .sort({ createdAt: -1 });

      const examNotifications = recentResults.map(result => ({
        id: `exam_${result._id}`,
        title: 'Exam Submitted',
        message: `${result.userId?.fullName || 'A student'} submitted the exam "${result.examId?.title || 'Unknown Exam'}" with score ${result.score}/${result.totalPoints}`,
        type: 'exam',
        isRead: false,
        severity: 'medium',
        data: { resultId: result._id, userId: result.userId?._id },
        timestamp: result.createdAt,
        isVirtual: true
      }));

      // 5. Fetch new enrollments (paid ones that are recent)
      const Enrollment = require('../models/Enrollment');
      const recentEnrollments = await Enrollment.find({ 
        createdAt: { $gte: recentCutoff },
        paymentStatus: 'paid'
      })
        .populate('userId', 'fullName')
        .populate('courseId', 'title')
        .sort({ createdAt: -1 });

      const enrollmentNotifications = recentEnrollments.map(enrollment => ({
        id: `enrollment_${enrollment._id}`,
        title: 'New Enrollment',
        message: `${enrollment.userId?.fullName || 'A student'} enrolled in "${enrollment.courseId?.title || 'a course'}"`,
        type: 'enrollment',
        isRead: false,
        severity: 'info',
        data: { enrollmentId: enrollment._id, userId: enrollment.userId?._id },
        timestamp: enrollment.createdAt,
        isVirtual: true
      }));

      // 6. Combine and sort
      const allNotifications = [
        ...adminNotifications.map(n => ({
          id: n._id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: n.isRead,
          severity: n.data?.severity || 'info',
          data: n.data,
          timestamp: n.createdAt,
          isVirtual: false
        })),
        ...paymentNotifications,
        ...newUserNotifications,
        ...examNotifications,
        ...enrollmentNotifications
      ].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

      res.status(200).json({
        success: true,
        message: 'Admin notifications fetched successfully',
        data: {
          notifications: allNotifications,
          unreadCount: allNotifications.filter(n => !n.isRead).length
        }
      });
    } catch (error) {
      console.error('Error fetching admin notifications:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch admin notifications',
        error: error.message
      });
    }
  }

  // Check if user has exceeded daily notification limit (e.g. 2 per day)
  async checkDailyLimit(userId) {
    try {
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const count = await Notification.countDocuments({
        userId,
        createdAt: { $gte: oneDayAgo }
      });
      return count < 2; // Limit to 2 per 24 hours
    } catch (error) {
      console.error('Error checking daily limit:', error);
      return true; // Default to true on error to allow notification
    }
  }

  // Send push notification via FCM
  async sendPushNotification(userId, title, message, data = {}, bypassLimit = false) {
    try {
      // Check daily limit unless bypassed (important system notifications like payments bypass the limit)
      if (!bypassLimit) {
        const canSend = await this.checkDailyLimit(userId);
        if (!canSend) {
          console.log(`Daily notification limit reached for user ${userId}. Skipping.`);
          return;
        }
      }

      // Professional way: Get user's FCM token from Firestore
      const db = admin.firestore();
      
      let firebaseUid = userId;
      
      // If userId looks like a MongoDB ObjectId, find the user to get their firebaseUid
      if (userId.toString().length === 24 && /^[0-9a-fA-F]+$/.test(userId)) {
        const user = await User.findById(userId);
        if (user && user.firebaseUid) {
          firebaseUid = user.firebaseUid;
        } else if (!user) {
          console.log(`User ${userId} not found in MongoDB`);
          return;
        }
      }
      
      const userDoc = await db.collection('users').doc(firebaseUid).get();
      
      if (!userDoc.exists) {
        console.log(`User document ${firebaseUid} not found in Firestore`);
        // Fallback to MongoDB if Firestore doc doesn't exist yet
        const user = await User.findOne({ $or: [{ _id: userId }, { firebaseUid: userId }] });
        if (!user || !user.fcmToken) {
          console.log('User FCM token not found in MongoDB fallback either');
          return;
        }
        var fcmToken = user.fcmToken;
      } else {
        var fcmToken = userDoc.data().fcmToken;
      }
      
      if (!fcmToken) {
        console.log('User FCM token is empty');
        return;
      }

      const payload = {
        notification: {
          title: title,
          body: message,
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          sound: 'default'
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(payload);
      console.log('Push notification sent successfully:', response);
      return response;
    } catch (error) {
      console.error('Error sending push notification:', error);
      // Don't throw to prevent breaking the caller flow (e.g. payment processing)
    }
  }

  // Send push notification to topic
  async sendPushToTopic(topic, title, message, data = {}) {
    try {
      const payload = {
        notification: {
          title: title,
          body: message,
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          sound: 'default'
        },
        topic: topic,
      };

      const response = await admin.messaging().send(payload);
      console.log('Push notification sent to topic successfully:', response);
      return response;
    } catch (error) {
      console.error('Error sending push notification to topic:', error);
      throw error;
    }
  }
}

// Helper functions for creating specific types of notifications
const notificationController = new NotificationController();

NotificationController.createPaymentNotification = async (userId, amount, courseId = null) => {
  try {
    const data = { amount };
    if (courseId) data.courseId = courseId;
    
    const notification = await Notification.createNotification({
      userId,
      title: 'Payment Received',
      message: `RWF ${amount.toLocaleString()} has been successfully processed`,
      type: 'payment',
      data
    });
    
    // Send push notification
    await notificationController.sendPushNotification(userId, 'Payment Received', `RWF ${amount.toLocaleString()} has been successfully processed`, data, true);
    
    return notification;
  } catch (error) {
    console.error('Error creating payment notification:', error);
    throw error;
  }
};

NotificationController.createCourseEnrollmentNotification = async (userId, courseTitle, courseId) => {
  try {
    const data = { courseId };
    const notification = await Notification.createNotification({
      userId,
      title: 'Course Enrollment',
      message: `You have been successfully enrolled in "${courseTitle}"`,
      type: 'course',
      data
    });
    
    // Send push notification
    await notificationController.sendPushNotification(userId, 'Course Enrollment', `You have been successfully enrolled in "${courseTitle}"`, data, true);
    
    return notification;
  } catch (error) {
    console.error('Error creating enrollment notification:', error);
    throw error;
  }
};

NotificationController.createExamResultNotification = async (userId, examTitle, score, courseId) => {
  try {
    const type = score >= 70 ? 'success' : 'info';
    const message = score >= 70 
      ? `Congratulations! You scored ${score}% on "${examTitle}"`
      : `You scored ${score}% on "${examTitle}". Keep practicing!`;
    
    const data = { courseId, examTitle, score };
    const notification = await Notification.createNotification({
      userId,
      title: 'Exam Result Available',
      message,
      type,
      data
    });
    
    // Send push notification
    await notificationController.sendPushNotification(userId, 'Exam Result Available', message, data, true);
    
    return notification;
  } catch (error) {
    console.error('Error creating exam result notification:', error);
    throw error;
  }
};

NotificationController.createAchievementNotification = async (userId, achievementTitle) => {
  try {
    const data = { achievementTitle };
    const notification = await Notification.createNotification({
      userId,
      title: 'New Achievement Unlocked!',
      message: `Congratulations on achieving: ${achievementTitle}`,
      type: 'achievement',
      data
    });
    
    // Send push notification
    await notificationController.sendPushNotification(userId, 'New Achievement Unlocked!', `Congratulations on achieving: ${achievementTitle}`, data, true);
    
    return notification;
  } catch (error) {
    console.error('Error creating achievement notification:', error);
    throw error;
  }
};

// Reminder & Progress Notifications
NotificationController.createInactivityReminder = async (userId, courseTitle, courseId) => {
  try {
    const data = { courseId, route: `/learning/${courseId}` };
    const title = 'Continue Learning! 🧠';
    const message = `We haven't seen you in a while. Pick up where you left off in "${courseTitle}"!`;
    
    const notification = await Notification.createNotification({
      userId,
      title,
      message,
      type: 'reminder',
      data
    });
    
    await notificationController.sendPushNotification(userId, title, message, data, false);
    return notification;
  } catch (error) {
    console.error('Error creating inactivity reminder:', error);
  }
};

NotificationController.createWeeklyProgressSummary = async (userId, lessonsCount) => {
  try {
    const title = 'Weekly Progress Summary 📈';
    const message = `You completed ${lessonsCount} lessons this week. Great job! Keep it up!`;
    
    const notification = await Notification.createNotification({
      userId,
      title,
      message,
      type: 'info',
      data: { lessonsCount }
    });
    
    await notificationController.sendPushNotification(userId, title, message, {}, false);
    return notification;
  } catch (error) {
    console.error('Error creating weekly summary:', error);
  }
};

NotificationController.createPromotionNotification = async (userId, promoTitle, promoMessage, promoData = {}) => {
  try {
    const notification = await Notification.createNotification({
      userId,
      title: promoTitle,
      message: promoMessage,
      type: 'promotion',
      data: promoData
    });
    
    await notificationController.sendPushNotification(userId, promoTitle, promoMessage, promoData, false);
    return notification;
  } catch (error) {
    console.error('Error creating promotion notification:', error);
  }
};

module.exports = notificationController;