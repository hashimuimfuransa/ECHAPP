const https = require('https');

// Test the exam history test endpoint with a real token
const testToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImY1MzMwMzNhMTMzYWQyM2UzOWY4YjQ4ZjMxYjQ3Y2I2YzYzYzA4YzUiLCJ0eXAiOiJKV1QifQ.eyJwcm92aWRlcl9pZCI6ImFub255bW91cyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9leGNlbGxlbmNlY29hY2hpbmdodWItNTU5N2MiLCJhdWQiOiJleGNlbGxlbmNlY29hY2hpbmdodWItNTU5N2MiLCJhdXRoX3RpbWUiOjE3NzA3MzQ4MzQsInVzZXJfaWQiOiJQQnVxaEFGQnlJZGpCbVJtYjdjOEhQV3NQYW4xIiwic3ViIjoiUEJ1cWhBRkJ5SWRqQm1SbWI3YzhQUFdzUGFuMSIsImlhdCI6MTc3MDczNDgzNCwiZXhwIjoxNzcwNzM4NDM0LCJlbWFpbCI6ImRpZXVkb25uZXR1eTI1MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwMDQ1MzUxMTAwMTIyMzQ1Njc4OSJdLCJlbWFpbCI6WyJkaWV1ZG9ubmV0dXkyNTBAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.TOKEN_SIGNATURE_HERE';

const options = {
  hostname: 'echappbackend.onrender.com',
  port: 443,
  path: '/api/exams/history/test',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${testToken}`,
    'Content-Type': 'application/json'
  }
};

console.log('Testing exam history test endpoint...');
console.log('URL: https://echappbackend.onrender.com/api/exams/history/test');

const req = https.request(options, (res) => {
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