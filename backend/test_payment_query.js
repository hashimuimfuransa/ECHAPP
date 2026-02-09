const mongoose = require('mongoose');
require('./src/config/database');

const Payment = require('./src/models/Payment');

// Simple test without authentication
async function testPaymentQuery() {
  try {
    console.log('=== Testing Payment Query ===');
    
    // Test the exact query used in getAdminPaymentsSimple
    const payments = await Payment.find({})
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price')
      .sort({ createdAt: -1 });
    
    console.log('Payments found:', payments.length);
    
    payments.forEach((payment, index) => {
      console.log(`\n--- Payment ${index + 1} ---`);
      console.log('ID:', payment._id);
      console.log('Status:', payment.status);
      console.log('Amount:', payment.amount);
      console.log('User ID:', payment.userId?._id);
      console.log('User Email:', payment.userId?.email);
      console.log('Course ID:', payment.courseId?._id);
      console.log('Course Title:', payment.courseId?.title);
      console.log('Created:', payment.createdAt);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testPaymentQuery();