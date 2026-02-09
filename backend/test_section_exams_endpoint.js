const http = require('http');

// Test the new admin section exams endpoint
const options = {
  hostname: '192.168.1.5',
  port: 5000,
  path: '/api/exams/section/698597d8d96a24ae4e945d04/admin',
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_ADMIN_TOKEN_HERE' // You'll need to replace this with a valid admin token
  }
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers: ${JSON.stringify(res.headers)}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Response body:');
    console.log(data);
    try {
      const jsonData = JSON.parse(data);
      console.log('Parsed JSON:');
      console.log(JSON.stringify(jsonData, null, 2));
    } catch (e) {
      console.log('Could not parse as JSON');
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.end();