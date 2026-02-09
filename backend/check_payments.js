const mongoose = require('mongoose');
const Payment = require('./src/models/Payment');

// Connect to database
const connectDB = require('./src/config/database');

async function checkPayments() {
  try {
    await connectDB();
    console.log('Connected to database');
    
    // Check total payments
    const totalPayments = await Payment.countDocuments();
    console.log('Total payments in database:', totalPayments);
    
    // Get all payments
    const payments = await Payment.find({})
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price')
      .limit(10);
    
    console.log('Sample payments:');
    payments.forEach((payment, index) => {
      console.log(`Payment ${index + 1}:`, {
        id: payment._id,
        userId: payment.userId?._id || payment.userId,
        courseId: payment.courseId?._id || payment.courseId,
        amount: payment.amount,
        status: payment.status,
        transactionId: payment.transactionId
      });
    });
    
    // Test the getAllPayments logic
    const page = 1;
    const limit = 10;
    const filter = {};
    
    const paymentsResult = await Payment.find(filter)
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price')
      .populate('adminApproval.approvedBy', 'fullName')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });
    
    const total = await Payment.countDocuments(filter);
    
    console.log('\ngetAllPayments simulation result:');
    console.log('payments length:', paymentsResult.length);
    console.log('payments type:', typeof paymentsResult);
    console.log('isArray:', Array.isArray(paymentsResult));
    console.log('total:', total);
    console.log('totalPages:', Math.ceil(total / limit));
    console.log('currentPage:', Number(page));
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkPayments();