const express = require('express');
const router = express.Router();
const NotificationController = require('../controllers/notification.controller');
const { protect } = require('../middleware/auth.middleware');
const User = require('../models/User');

// Create controller instance
const notificationController = new NotificationController();

// All routes require authentication
router.use(protect);

// GET /api/notifications - Get all notifications for current user
router.get('/', notificationController.getNotifications);

// GET /api/notifications/unread-count - Get unread notifications count
router.get('/unread-count', notificationController.getUnreadCount);

// GET /api/notifications/:id - Get specific notification by ID
router.get('/:id', notificationController.getNotificationById);

// PUT /api/notifications/:id/read - Mark notification as read
router.put('/:id/read', notificationController.markAsRead);

// PUT /api/notifications/read-all - Mark all notifications as read
router.put('/read-all', notificationController.markAllAsRead);

// DELETE /api/notifications/:id - Delete a notification
router.delete('/:id', notificationController.deleteNotification);

// POST /api/notifications - Create a notification (admin/internal use)
router.post('/', notificationController.createNotification);

// POST /api/notifications/send-push - Send push notification to specific user
router.post('/send-push', async (req, res) => {
  try {
    const { userId, title, message, data } = req.body;
    
    if (!userId || !title || !message) {
      return res.status(400).json({
        success: false,
        message: 'userId, title, and message are required'
      });
    }
    
    // Call the method on the controller instance
    const response = await notificationController.sendPushNotification(userId, title, message, data);
    
    res.status(200).json({
      success: true,
      message: 'Push notification sent successfully',
      data: response
    });
  } catch (error) {
    console.error('Error sending push notification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send push notification',
      error: error.message
    });
  }
});

// POST /api/notifications/send-topic - Send push notification to topic
router.post('/send-topic', async (req, res) => {
  try {
    const { topic, title, message, data } = req.body;
    
    if (!topic || !title || !message) {
      return res.status(400).json({
        success: false,
        message: 'topic, title, and message are required'
      });
    }
    
    // Call the method on the controller instance
    const response = await notificationController.sendPushToTopic(topic, title, message, data);
    
    res.status(200).json({
      success: true,
      message: 'Push notification sent to topic successfully',
      data: response
    });
  } catch (error) {
    console.error('Error sending push notification to topic:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send push notification to topic',
      error: error.message
    });
  }
});

// PUT /api/notifications/fcm-token - Update user's FCM token
router.put('/fcm-token', async (req, res) => {
  try {
    const userId = req.user.id;
    const { fcmToken } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }
    
    const user = await User.findByIdAndUpdate(
      userId,
      { fcmToken },
      { new: true, runValidators: true }
    );
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'FCM token updated successfully',
      data: {
        userId: user._id,
        fcmToken: user.fcmToken
      }
    });
  } catch (error) {
    console.error('Error updating FCM token:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update FCM token',
      error: error.message
    });
  }
});

module.exports = router;