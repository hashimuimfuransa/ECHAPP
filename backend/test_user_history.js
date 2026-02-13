const http = require('http');
const mongoose = require('mongoose');
const User = require('./src/models/User');
const Result = require('./src/models/Result');

// Test with a real user token
const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/exams/history',
  method: 'GET',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImY1MzMwMzNhMTMzYWQyM2...'
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