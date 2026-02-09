const axios = require('axios');

async function debugPaymentResponse() {
  try {
    console.log('=== Debugging Payment API Response ===');
    
    // First, login to get auth token
    const loginResponse = await axios.post('http://localhost:5000/api/auth/login', {
      email: 'admin@echub.com',
      password: 'admin123'
    });
    
    console.log('Login successful');
    const token = loginResponse.data.data.token;
    
    // Now call the payments endpoint
    const paymentsResponse = await axios.get('http://localhost:5000/api/payments', {
      headers: {
        'Authorization': `Bearer ${token}`
      },
      params: {
        page: 1,
        limit: 10
      }
    });
    
    console.log('\n=== PAYMENT RESPONSE ANALYSIS ===');
    console.log('Status:', paymentsResponse.status);
    console.log('Headers:', Object.keys(paymentsResponse.headers));
    console.log('Content-Type:', paymentsResponse.headers['content-type']);
    
    console.log('\nRaw Response Body:');
    console.log(JSON.stringify(paymentsResponse.data, null, 2));
    
    console.log('\nResponse Structure Analysis:');
    console.log('Type of response.data:', typeof paymentsResponse.data);
    console.log('Is response.data an object?', typeof paymentsResponse.data === 'object');
    console.log('Keys in response.data:', Object.keys(paymentsResponse.data || {}));
    
    if (paymentsResponse.data && paymentsResponse.data.data) {
      console.log('\nData field analysis:');
      console.log('Type of data field:', typeof paymentsResponse.data.data);
      console.log('Keys in data field:', Object.keys(paymentsResponse.data.data || {}));
      
      if (paymentsResponse.data.data.payments !== undefined) {
        console.log('Type of payments field:', typeof paymentsResponse.data.data.payments);
        console.log('Is payments an array?', Array.isArray(paymentsResponse.data.data.payments));
        console.log('Payments value:', paymentsResponse.data.data.payments);
      }
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
    if (error.response) {
      console.log('\nError Response:');
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
      console.log('Data:', JSON.stringify(error.response.data, null, 2));
    }
    process.exit(1);
  }
}

debugPaymentResponse();