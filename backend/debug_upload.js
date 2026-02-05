/**
 * Debug script to help troubleshoot upload issues
 */

console.log('🔍 UPLOAD DEBUG SCRIPT');
console.log('=====================');

// Check environment variables
const fs = require('fs');
const path = require('path');

try {
  const envContent = fs.readFileSync(path.join(__dirname, '.env'), 'utf8');
  console.log('\n✅ Environment Variables Check:');
  
  const awsKeys = {
    AWS_ACCESS_KEY_ID: envContent.includes('AWS_ACCESS_KEY_ID'),
    AWS_SECRET_ACCESS_KEY: envContent.includes('AWS_SECRET_ACCESS_KEY'),
    AWS_REGION: envContent.includes('AWS_REGION'),
    S3_BUCKET_NAME: envContent.includes('S3_BUCKET_NAME'),
    S3_BUCKET_URL: envContent.includes('S3_BUCKET_URL')
  };
  
  Object.entries(awsKeys).forEach(([key, present]) => {
    console.log(`  ${present ? '✅' : '❌'} ${key}: ${present ? 'Present' : 'Missing'}`);
  });

  // Check for carriage returns in the env file
  const lines = envContent.split('\n');
  let hasCarriageReturns = false;
  lines.forEach((line, index) => {
    if (line.includes('\r')) {
      hasCarriageReturns = true;
      console.log(`  ⚠️  Line ${index + 1} has carriage return: ${line.trim()}`);
    }
  });
  
  if (hasCarriageReturns) {
    console.log('\n⚠️  WARNING: Carriage returns detected in .env file. This can cause issues.');
    console.log('   Please ensure your .env values don\'t have trailing \\r characters.');
  }

} catch (error) {
  console.log('\n❌ Could not read .env file:', error.message);
}

// Check if required files exist
console.log('\n✅ File Structure Check:');
const requiredFiles = [
  './src/controllers/upload.controller.js',
  './src/services/s3.service.js',
  './src/services/upload-progress.service.js',
  './src/routes/upload.routes.js'
];

requiredFiles.forEach(file => {
  const exists = fs.existsSync(path.join(__dirname, file));
  console.log(`  ${exists ? '✅' : '❌'} ${file}: ${exists ? 'Exists' : 'Missing'}`);
});

// Check package dependencies
console.log('\n✅ Dependencies Check:');
try {
  const packageJson = require('./package.json');
  const hasMulter = !!packageJson.dependencies.multer;
  const hasAWSSDK = !!packageJson.dependencies['@aws-sdk/client-s3'];
  
  console.log(`  ✅ Multer: ${hasMulter ? 'Installed' : 'Missing'}`);
  console.log(`  ✅ AWS SDK: ${hasAWSSDK ? 'Installed' : 'Missing'}`);
} catch (error) {
  console.log(`  ❌ Could not read package.json: ${error.message}`);
}

// Common issues checklist
console.log('\n📋 COMMON ISSUES CHECKLIST:');
console.log('1. Verify S3 bucket policy allows uploads');
console.log('2. Check AWS credentials are correct');
console.log('3. Confirm S3 bucket exists and is accessible');
console.log('4. Ensure server accepts multipart/form-data');
console.log('5. Verify authentication tokens are valid');
console.log('6. Check if additional form fields are causing issues');
console.log('7. Confirm file size is within limits (currently 100MB)');
console.log('8. Verify content-type matches expected video/image types');

console.log('\n💡 TROUBLESHOOTING TIPS:');
console.log('- Check server logs when attempting upload');
console.log('- Verify the upload request includes proper authentication');
console.log('- Ensure the S3 bucket allows the requested operations');
console.log('- Look for specific error messages in the console');

console.log('\n🔄 To apply changes:');
console.log('- Restart the backend server: npm run dev');
console.log('- Clear any caches if using a proxy/load balancer');