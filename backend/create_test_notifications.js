const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Notification = require('./src/models/Notification');
const User = require('./src/models/User');

// MongoDB connection
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/echub');
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    process.exit(1);
  }
};

// Sample notifications data
const sampleNotifications = [
  {
    title: 'Payment Received',
    message: 'RWF 25,000 has been successfully processed for "Advanced Mathematics" course',
    type: 'payment',
    data: { amount: 25000, courseId: 'math101' }
  },
  {
    title: 'Course Enrollment',
    message: 'You have been successfully enrolled in "Introduction to Physics"',
    type: 'course',
    data: { courseId: 'phy101' }
  },
  {
    title: 'Exam Result Available',
    message: 'Congratulations! You scored 85% on "Final Mathematics Exam"',
    type: 'exam',
    data: { courseId: 'math101', examTitle: 'Final Mathematics Exam', score: 85 }
  },
  {
    title: 'New Achievement Unlocked!',
    message: 'Congratulations on completing your first course!',
    type: 'achievement',
    data: { achievementTitle: 'First Course Completed' }
  },
  {
    title: 'System Update',
    message: 'New features have been added to the platform. Check them out!',
    type: 'info',
    data: {}
  },
  {
    title: 'Payment Reminder',
    message: 'Your subscription will expire in 3 days. Please renew to continue learning.',
    type: 'warning',
    data: {}
  }
];

async function createTestNotifications() {
  try {
    await connectDB();
    
    // Find a test user (you can modify this to use a specific user)
    const user = await User.findOne({ email: 'student@echub.com' }) || 
                 await User.findOne({ role: 'student' });
    
    if (!user) {
      console.log('No student user found. Creating a test user first...');
      const testUser = await User.create({
        fullName: 'Test Student',
        email: 'student@echub.com',
        role: 'student'
      });
      console.log('Created test user:', testUser.email);
    }
    
    const finalUser = await User.findOne({ email: 'student@echub.com' }) || 
                      await User.findOne({ role: 'student' });
    
    if (!finalUser) {
      throw new Error('Could not find or create a user for notifications');
    }
    
    console.log(`Creating notifications for user: ${finalUser.email} (${finalUser._id})`);
    
    // Clear existing notifications for this user
    await Notification.deleteMany({ userId: finalUser._id });
    console.log('Cleared existing notifications');
    
    // Create new notifications with different timestamps
    const now = new Date();
    const notificationsToCreate = sampleNotifications.map((notification, index) => ({
      ...notification,
      userId: finalUser._id,
      createdAt: new Date(now.getTime() - (index * 3600000)), // 1 hour apart
      isRead: index % 3 === 0 // Mark every 3rd notification as read
    }));
    
    const createdNotifications = await Notification.insertMany(notificationsToCreate);
    console.log(`\n✅ Successfully created ${createdNotifications.length} test notifications:`);
    
    createdNotifications.forEach((notification, index) => {
      console.log(`${index + 1}. ${notification.title} (${notification.type}) - ${notification.isRead ? 'Read' : 'Unread'}`);
    });
    
    console.log(`\n📊 Summary:`);
    console.log(`Total notifications: ${createdNotifications.length}`);
    console.log(`Unread notifications: ${createdNotifications.filter(n => !n.isRead).length}`);
    console.log(`Read notifications: ${createdNotifications.filter(n => n.isRead).length}`);
    
    // Test the getUserNotifications method
    const userNotifications = await Notification.getUserNotifications(finalUser._id);
    console.log(`\n🔍 Verified user notifications count: ${userNotifications.length}`);
    
    // Test the getUnreadCount method
    const unreadCount = await Notification.getUnreadCount(finalUser._id);
    console.log(`📧 Unread count: ${unreadCount}`);
    
    mongoose.connection.close();
    console.log('\n✨ Test notifications creation completed successfully!');
    
  } catch (error) {
    console.error('Error creating test notifications:', error);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  createTestNotifications();
}

module.exports = { createTestNotifications };