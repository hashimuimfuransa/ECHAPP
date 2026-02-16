const axios = require('axios');

async function testFirebaseLoginEndpoint() {
  try {
    console.log('=== Testing Firebase Login Endpoint ===\n');
    
    // Test with an invalid token first to see the error response
    console.log('1. Testing with invalid token...');
    try {
      const response = await axios.post('http://localhost:5000/api/auth/firebase-login', {
        idToken: 'invalid-test-token'
      });
      console.log('❌ Unexpected success with invalid token');
      console.log('Response:', response.data);
    } catch (error) {
      if (error.response) {
        console.log('✅ Got expected error for invalid token');
        console.log('Status:', error.response.status);
        console.log('Error message:', error.response.data.message);
      } else {
        console.log('❌ Network error:', error.message);
      }
    }
    
    console.log('\n2. Testing endpoint availability...');
    try {
      // Test if endpoint exists by sending empty request
      const response = await axios.post('http://localhost:5000/api/auth/firebase-login', {});
      console.log('❌ Unexpected success with empty body');
    } catch (error) {
      if (error.response) {
        console.log('✅ Endpoint exists and returns proper validation error');
        console.log('Status:', error.response.status);
        console.log('Error message:', error.response.data.message);
      } else {
        console.log('❌ Network error or endpoint not available:', error.message);
      }
    }
    
    console.log('\n=== Test Complete ===');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testFirebaseLoginEndpoint();