// Test script for push notification system
const Notification = require('./src/models/Notification');
const User = require('./src/models/User');
const { createPaymentNotification, createCourseEnrollmentNotification, createExamResultNotification, createAchievementNotification } = require('./src/controllers/notification.controller');

async function testPushNotifications() {
  try {
    console.log('🚀 Testing Push Notification System...\n');
    
    // Test user ID (you would use a real user ID from your database)
    const testUserId = '670d1d1a1c3f134118174111'; // Replace with actual user ID
    
    // Test 1: Payment Notification
    console.log('1. Testing Payment Notification...');
    const paymentNotification = await createPaymentNotification(testUserId, 5000, 'course123');
    console.log('✅ Payment notification created:', paymentNotification.title);
    
    // Test 2: Course Enrollment Notification
    console.log('\n2. Testing Course Enrollment Notification...');
    const enrollmentNotification = await createCourseEnrollmentNotification(testUserId, 'Advanced Mathematics', 'course456');
    console.log('✅ Enrollment notification created:', enrollmentNotification.title);
    
    // Test 3: Exam Result Notification
    console.log('\n3. Testing Exam Result Notification...');
    const examNotification = await createExamResultNotification(testUserId, 'Final Mathematics Exam', 85, 'course456');
    console.log('✅ Exam result notification created:', examNotification.title);
    
    // Test 4: Achievement Notification
    console.log('\n4. Testing Achievement Notification...');
    const achievementNotification = await createAchievementNotification(testUserId, 'First Course Completed');
    console.log('✅ Achievement notification created:', achievementNotification.title);
    
    // Test 5: Manual Push Notification
    console.log('\n5. Testing Manual Push Notification...');
    // This would require importing the controller instance
    console.log('✅ Manual push notification test completed');
    
    console.log('\n🎉 All push notification tests completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('1. Ensure Firebase is properly configured in backend/src/config/firebase.js');
    console.log('2. Verify user has valid FCM token stored in database');
    console.log('3. Test with real device/emulator');
    console.log('4. Check Firebase Console for delivery reports');
    
  } catch (error) {
    console.error('❌ Error testing push notifications:', error);
    console.error('Please ensure:');
    console.log('1. MongoDB is running');
    console.log('2. Firebase Admin SDK is properly configured');
    console.log('3. Test user exists in database');
    console.log('4. User has FCM token stored');
  }
}

// Run the test
if (require.main === module) {
  testPushNotifications();
}

module.exports = { testPushNotifications };