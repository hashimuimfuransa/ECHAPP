const mongoose = require('mongoose');
require('./src/config/database');

const Payment = require('./src/models/Payment');
const User = require('./src/models/User');
const Course = require('./src/models/Course');

async function createTestPayment() {
  try {
    console.log('=== Creating Test Payment ===');
    
    // Find a user and course to create a test payment
    const user = await User.findOne({ role: 'admin' });
    const course = await Course.findOne({});
    
    if (!user || !course) {
      console.log('No user or course found to create test payment');
      console.log('Users:', await User.countDocuments());
      console.log('Courses:', await Course.countDocuments());
      process.exit(1);
    }
    
    console.log('User found:', user.email);
    console.log('Course found:', course.title);
    
    // Create a test payment
    const payment = await Payment.create({
      userId: user._id,
      courseId: course._id,
      amount: course.price || 1000,
      currency: 'RWF',
      paymentMethod: 'mtn',
      transactionId: `TEST_${Date.now()}`,
      status: 'pending',
      contactInfo: '0788888888'
    });
    
    console.log('Test payment created:', payment._id);
    console.log('Status:', payment.status);
    
    // Verify it was created
    const foundPayment = await Payment.findById(payment._id)
      .populate('userId', 'email fullName')
      .populate('courseId', 'title price');
    
    console.log('Found payment:', foundPayment._id);
    console.log('User email:', foundPayment.userId?.email);
    console.log('Course title:', foundPayment.courseId?.title);
    
    process.exit(0);
  } catch (error) {
    console.error('Error creating test payment:', error);
    process.exit(1);
  }
}

createTestPayment();