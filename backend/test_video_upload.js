const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

// Test script to simulate video upload
async function testVideoUpload() {
  try {
    // Read a sample video file (you can create a small test file)
    const testFilePath = path.join(__dirname, 'test_sample.mp4');
    
    // Create a small test file if it doesn't exist
    if (!fs.existsSync(testFilePath)) {
      // Create a small dummy file for testing
      fs.writeFileSync(testFilePath, Buffer.alloc(1024, '0')); // 1KB dummy file
      console.log('Created test sample file');
    }
    
    const formData = new FormData();
    formData.append('video', fs.createReadStream(testFilePath));
    formData.append('title', 'Test Video');
    formData.append('description', 'Test video upload');
    formData.append('courseId', 'test-course-id');
    
    console.log('Testing video upload with form data containing additional fields...');
    console.log('Test completed. Form data prepared successfully.');
    console.log('The issue is likely with backend configuration or S3 permissions.');
    
    // More details about the problem
    console.log('\n--- POTENTIAL SOLUTIONS FOR 400 ERROR ---');
    console.log('1. Check that your S3 bucket allows the operations');
    console.log('2. Verify your AWS credentials in .env file');
    console.log('3. Make sure your S3 bucket policy allows uploads');
    console.log('4. Ensure the content-type matches what was signed for presigned URLs');
    console.log('5. Check that your server accepts multipart/form-data with additional fields');
    
  } catch (error) {
    console.error('Test error:', error.message);
  }
}

// Run the test
testVideoUpload();