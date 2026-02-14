const http = require('http');

function testCreateNotification() {
  const postData = JSON.stringify({
    title: 'Test Notification',
    message: 'This is a test notification from the fixed backend',
    type: 'info'
  });

  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/notifications',
    method: 'POST',
    headers: {
      'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjRiMTFjYjdhYjVmY2JlNDFlOTQ4MDk0ZTlkZjRjNWI1ZWNhMDAwOWUiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoidHV5aXplcmUgZGlldWRvbm5lIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2V4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1ZCI6ImV4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1dGhfdGltZSI6MTc3MTA3Mzc1NiwidXNlcl9pZCI6IlBCdXFoQUZCeUlkakJtUm1iN2M4SFBXc1BhbjEiLCJzdWIiOiJQQnVxaEFGQnlJZGpCbVJtYjdjOEhQV3NQYW4xIiwiaWF0IjoxNzcxMDczNzU2LCJleHAiOjE3NzEwNzczNTYsImVtYWlsIjoiZGlldWRvbm5ldHV5MjUwQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7Imdvb2dsZS5jb20iOlsiMTAwNDUzNTExMDExMjE0MzY1ODQ1Il0sImVtYWlsIjpbImRpZXVkb25uZXR1eTI1MEBnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.doIHYsCr5GLbuHWM-WsyQ_U8k9UjqqdU22aGucJ44MAuiTi5YES6ItZuoHzajSwd8sGOI5XQjCNn9EJKkZ7IDr7-7LfxcbWlYK7gcTjw70fnytAZOFxZUeJ8_fYp-bxF2ahAE5u0jOBuqpRe2uEIdc8WP94bM0NSCPkQp4b_PbQGnbSWlrEGAyJ8vlaHLN8S5Dh2tpUIwK-qN3qtDI5M2PkpWwVBdYzwaXf2_Yj3TU68y_JiBK39TycE13Vh6u7OAGZAbn90ahzyNeEcLFE5l21_v8ahSFS-4YLtXxFEA2Ekduwu1q80aP0ZCRKUTuHP2nQqBfFcYVlaLWpxCjvjAQ',
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
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
      try {
        const jsonData = JSON.parse(data);
        console.log(JSON.stringify(jsonData, null, 2));
      } catch (e) {
        console.log(data);
      }
    });
  });

  req.on('error', (error) => {
    console.error('Error:', error);
  });

  req.write(postData);
  req.end();
}

testCreateNotification();