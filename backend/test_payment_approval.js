const Payment = require('./src/models/Payment');
const mongoose = require('mongoose');
require('dotenv').config();

async function testPaymentApproval() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/echapp');
    console.log('Connected to database');

    // Create a test payment
    const testPayment = await Payment.create({
      userId: '67a0b1c2d3e4f5g6h7i8j9k0', // Test user ID
      courseId: '67a0b1c2d3e4f5g6h7i8j9k1', // Test course ID
      amount: 1000,
      currency: 'RWF',
      paymentMethod: 'mtn_momo',
      transactionId: `TEST_TXN_${Date.now()}`,
      status: 'pending',
      contactInfo: '0788888888'
    });

    console.log('Created test payment:', testPayment._id);

    // Test the verifyPayment function
    const { verifyPayment } = require('./src/controllers/payment_workflow.controller');
    
    // Mock request and response objects
    const req = {
      body: {
        paymentId: testPayment._id.toString(),
        status: 'approved',
        adminNotes: 'Test approval'
      },
      user: {
        id: '67a0b1c2d3e4f5g6h7i8j9k2', // Test admin ID
        role: 'admin'
      }
    };

    const res = {
      status: function(code) {
        this.statusCode = code;
        return this;
      },
      json: function(data) {
        this.data = data;
        console.log('Response:', JSON.stringify(data, null, 2));
        return this;
      }
    };

    // Call the verifyPayment function
    await verifyPayment(req, res);

    // Check if payment was updated
    const updatedPayment = await Payment.findById(testPayment._id);
    console.log('Updated payment status:', updatedPayment.status);
    console.log('Admin approval:', updatedPayment.adminApproval);

    // Clean up
    await Payment.findByIdAndDelete(testPayment._id);
    console.log('Test payment cleaned up');

  } catch (error) {
    console.error('Test failed:', error);
  } finally {
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

testPaymentApproval();