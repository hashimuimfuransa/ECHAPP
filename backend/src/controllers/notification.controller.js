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

  // Send push notification via FCM
  async sendPushNotification(userId, title, message, data = {}) {
    try {
      // Get user's FCM token from database (you'll need to store this when users login)
      const user = await User.findById(userId);
      if (!user || !user.fcmToken) {
        console.log('User FCM token not found');
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
        token: user.fcmToken,
      };

      const response = await admin.messaging().send(payload);
      console.log('Push notification sent successfully:', response);
      return response;
    } catch (error) {
      console.error('Error sending push notification:', error);
      throw error;
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
    await this.sendPushNotification(userId, 'Payment Received', `RWF ${amount.toLocaleString()} has been successfully processed`, data);
    
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
    await this.sendPushNotification(userId, 'Course Enrollment', `You have been successfully enrolled in "${courseTitle}"`, data);
    
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
    await this.sendPushNotification(userId, 'Exam Result Available', message, data);
    
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
    await this.sendPushNotification(userId, 'New Achievement Unlocked!', `Congratulations on achieving: ${achievementTitle}`, data);
    
    return notification;
  } catch (error) {
    console.error('Error creating achievement notification:', error);
    throw error;
  }
};

module.exports = NotificationController;