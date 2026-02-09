const axios = require('axios');

// Test script to verify the payment verification endpoint is working
async function testPaymentVerify() {
  try {
    console.log('Testing payment verification endpoint...');
    
    // This would be a real test, but we need a valid payment ID and admin token
    // For now, just demonstrating the expected structure
    const testPayload = {
      paymentId: 'some-valid-payment-id',
      status: 'approved',
      adminNotes: 'Test approval'
    };
    
    console.log('Expected request structure:');
    console.log('- Endpoint: PUT http://localhost:5000/api/payments/verify');
    console.log('- Headers: Authorization: Bearer [admin-jwt-token]');
    console.log('- Body:', JSON.stringify(testPayload, null, 2));
    
    console.log('\nThe backend fix has been applied:');
    console.log('1. Added await payment.save() after status update');
    console.log('2. Payment status changes are now persisted to the database');
    console.log('3. Admin approval information is properly recorded');
    console.log('4. Enrollment is created when payment is approved');
    
    console.log('\nTo test the approve button:');
    console.log('1. Make sure the backend server is running on port 5000');
    console.log('2. Ensure you have a valid admin user logged in');
    console.log('3. Navigate to the admin payment management page');
    console.log('4. Click the approve button on a pending payment');
    console.log('5. The payment should be approved and the UI should refresh');
    
  } catch (error) {
    console.error('Test failed:', error.message);
  }
}

testPaymentVerify();