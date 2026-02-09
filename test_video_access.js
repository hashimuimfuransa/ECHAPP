const https = require('https');
const http = require('http');

async function testVideoAccess() {
  const baseUrl = 'http://192.168.1.2:5000/api';
  const token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjRiMTFjYjdhYjVmY2JlNDFlOTQ4MDk0ZTlkZjRjNWI1ZWNhMDAwOWUiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoidHV5aXplcmUgZGlldWRvbm5lIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2V4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1ZCI6ImV4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1dGhfdGltZSI6MTc3MDQ2NjU3MSwidXNlcl9pZCI6IlBCdXFoQUZCeUlkakJtUm1iN2M4SFBXc1BhbjEiLCJzdWIiOiJQQnVxaEFGQnlJZGpCbVJtYjdjOEhQV3NQYW4xIiwiaWF0IjoxNzcwNDY2NTcxLCJleHAiOjE3NzA0NzAxNzEsImVtYWlsIjoiZGlldWRvbm5ldHV5MjUwQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7Imdvb2dsZS5jb20iOlsiMTAwNDUzNTExMDExMjE0MzY1ODQ1Il0sImVtYWlsIjpbImRpZXVkb25uZXR1eTI1MEBnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.Fs5O6FUKYzEbjUfBGSnI4fvSuJTeoLfNmvdUa61Q4C4mi0k_mAnT17gAXChCBz_sD3ApopNZSoQFHFi-UQeROtrc52BnAy85lK5-D3-f5TnyQ62QpsbrF2uIeh52E_gGBPlApwpyRiz85VVFpqWnWSgb04xoMnv4P94SXhRKvFsH4foJ4Wmgl0jyzROyyk3aElgmmSj96_1SMJMLZ1nv9_t9e9v_v02X-1sbyXklwJts9kL-trk7BtmgKMab4c-SBjjNPn8kz93AL5T1uyPxp-ZrslszsrTey0_tH2MCbr4CD5raQ2A5SdMQRgNpWnpvEhZhGQXdaAO2NKBJglPSZw';
  
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  console.log('Testing Video Access...\n');

  // Test 1: Get lesson details
  console.log('1. Getting lesson details:');
  try {
    const lessonResponse = await makeRequest(`${baseUrl}/lessons/69859816d96a24ae4e945d15`, headers);
    console.log(`Status: ${lessonResponse.statusCode}`);
    
    if (lessonResponse.statusCode === 200) {
      const lessonData = JSON.parse(lessonResponse.body);
      const videoId = lessonData.data.videoId;
      console.log(`Video ID: ${videoId}\n`);
      
      // Test 2: Get streaming URL
      console.log('2. Getting streaming URL:');
      const streamResponse = await makeRequest(`${baseUrl}/videos/69859816d96a24ae4e945d15/stream-url`, headers);
      console.log(`Status: ${streamResponse.statusCode}`);
      
      if (streamResponse.statusCode === 200) {
        const streamData = JSON.parse(streamResponse.body);
        const streamingUrl = streamData.data.streamingUrl;
        console.log(`Streaming URL: ${streamingUrl}\n`);
        
        // Test 3: Try to access the streaming URL directly
        console.log('3. Testing direct access to streaming URL:');
        try {
          const directResponse = await makeHeadRequest(streamingUrl);
          console.log(`Direct access status: ${directResponse.statusCode}`);
          
          if (directResponse.statusCode === 200) {
            console.log('✅ Video is accessible!');
          } else if (directResponse.statusCode === 403) {
            console.log('❌ Video access forbidden (403)');
            console.log('This usually means:');
            console.log('- The file doesn\'t exist in S3');
            console.log('- S3 bucket permissions are incorrect');
            console.log('- The signed URL has expired');
          } else {
            console.log(`❓ Unexpected status code: ${directResponse.statusCode}`);
          }
        } catch (e) {
          console.log(`❌ Error accessing streaming URL: ${e.message}`);
        }
      } else {
        console.log(`Error getting streaming URL: ${streamResponse.body}`);
      }
    } else {
      console.log(`Error getting lesson: ${lessonResponse.body}`);
    }
  } catch (e) {
    console.log(`Network error: ${e.message}`);
  }
}

function makeRequest(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: 'GET',
      headers: headers
    };

    const protocol = url.startsWith('https') ? https : http;
    
    const req = protocol.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: data
        });
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.end();
  });
}

function makeHeadRequest(url) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: 'HEAD'
    };

    const protocol = url.startsWith('https') ? https : http;
    
    const req = protocol.request(options, (res) => {
      resolve({
        statusCode: res.statusCode,
        headers: res.headers
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.end();
  });
}

testVideoAccess();