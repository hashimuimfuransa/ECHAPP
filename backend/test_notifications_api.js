const http = require('http');

function testNotificationsAPI() {
  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/notifications',
    method: 'GET',
    headers: {
      'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjRiMTFjYjdhYjVmY2JlNDFlOTQ4MDk0ZTlkZjRjNWI1ZWNhMDAwOWUiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoidHV5aXplcmUgZGlldWRvbm5lIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2V4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1ZCI6ImV4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1dGhfdGltZSI6MTc3MDQ2NjU3MSwidXNlcl9pZCI6IlBCdXFoQUZCeUlkakJtUm1iN2M4SFBXc1BhbjEiLCJzdWIiOiJQQnVxaEFGQnlJZGpCbVJtYjdjOEhQV3NQYW4xIiwiaWF0IjoxNzcwNDY2NTcxLCJleHAiOjE3NzA0NzAxNzEsImVtYWlsIjoiZGlldWRvbm5ldHV5MjUwQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7Imdvb2dsZS5jb20iOlsiMTAwNDUzNTExMDExMjE0MzY1ODQ1Il0sImVtYWlsIjpbImRpZXVkb25uZXR1eTI1MEBnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.Fs5O6FUKYzEbjUfBGSnI4fvSuJTeoLfNmvdUa61Q4C4mi0k_mAnT17gAXChCBz_sD3ApopNZSoQFHFi-UQeROtrc52BnAy85lK5-D3-f5TnyQ62QpsbrF2uIeh52E_gGBPlApwpyRiz85VVFpqWnWSgb04xoMnv4P94SXhRKvFsH4foJ4Wmgl0jyzROyyk3aElgmmSj96_1SMJMLZ1nv9_t9e9v_v02X-1sbyXklwJts9kL-trk7BtmgKMab4c-SBjjNPn8kz93AL5T1uyPxp-ZrslszsrTey0_tH2MCbr4CD5raQ2A5SdMQRgNpWnpvEhZhGQXdaAO2NKBJglPSZw',
      'Content-Type': 'application/json'
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

  req.end();
}

testNotificationsAPI();