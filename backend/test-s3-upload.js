const fs = require('fs');
const path = require('path');
require('dotenv').config();
const s3Service = require('./src/services/s3.service');

async function testS3Upload() {
  try {
    console.log('🚀 Testing AWS S3 Upload...');
    
    // Create a test image buffer (simple PNG header)
    const testBuffer = Buffer.from([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
      0xB0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82
    ]);
    
    console.log('📤 Uploading test image to S3...');
    
    // Test image upload
    const result = await s3Service.uploadImage(
      testBuffer,
      'test-image.png',
      'image/png'
    );
    
    console.log('✅ Upload successful!');
    console.log('File URL:', result.url);
    console.log('S3 Key:', result.key);
    console.log('Bucket:', result.bucket);
    
    // Test generating signed URL
    console.log('\n🔗 Generating signed URL for streaming...');
    const signedUrl = await s3Service.generateStreamingUrl(result.key, 3600);
    console.log('Signed URL:', signedUrl);
    
    // Test getting file metadata
    console.log('\n📊 Getting file metadata...');
    const metadata = await s3Service.getFileMetadata(result.key);
    console.log('Metadata:', metadata);
    
    console.log('\n🎉 All S3 tests passed successfully!');
    
  } catch (error) {
    console.error('❌ S3 Test failed:', error.message);
    console.error('Stack:', error.stack);
  }
}

testS3Upload();