// Test Firebase authentication flow
const admin = require('firebase-admin');
const axios = require('axios');

// Initialize Firebase Admin (same as in the app)
let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
  const serviceAccountJson = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf-8');
  serviceAccount = JSON.parse(serviceAccountJson);
} else {
  serviceAccount = require('./serviceAccountKey.json');
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

async function testFirebaseAuthFlow() {
  try {
    console.log('=== Testing Firebase Authentication Flow ===\n');
    
    // First, let's see what users exist in Firebase Auth
    console.log('1. Checking Firebase Auth users...');
    const userList = await admin.auth().listUsers();
    console.log(`Found ${userList.users.length} users in Firebase Auth`);
    
    if (userList.users.length > 0) {
      console.log('Users in Firebase Auth:');
      userList.users.forEach((user, index) => {
        console.log(`  ${index + 1}. Email: ${user.email}, UID: ${user.uid}`);
      });
      
      // Try to create a custom token for testing (this requires admin privileges)
      console.log('\n2. Creating custom token for testing...');
      const testUser = userList.users[0]; // Use first user
      try {
        const customToken = await admin.auth().createCustomToken(testUser.uid);
        console.log('✅ Created custom token for user:', testUser.email);
        console.log('Custom token (first 50 chars):', customToken.substring(0, 50) + '...');
        
        // Now try to verify this custom token
        console.log('\n3. Testing custom token verification...');
        try {
          const decodedToken = await admin.auth().verifyIdToken(customToken);
          console.log('✅ Custom token verification successful');
          console.log('Decoded UID:', decodedToken.uid);
          console.log('Decoded email:', decodedToken.email);
        } catch (error) {
          console.log('❌ Custom token verification failed:', error.message);
        }
      } catch (error) {
        console.log('❌ Failed to create custom token:', error.message);
      }
    } else {
      console.log('No users found in Firebase Auth');
    }
    
    console.log('\n=== Test Complete ===');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Error stack:', error.stack);
  }
}

// Run the test
testFirebaseAuthFlow();