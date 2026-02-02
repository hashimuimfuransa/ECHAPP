const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

async function testFirebaseConnection() {
  try {
    console.log('🔍 Testing Firebase Admin SDK connection...');
    
    // Test listing users
    const userList = await admin.auth().listUsers(5); // Limit to 5 users for testing
    console.log(`✅ Successfully connected to Firebase!`);
    console.log(`📋 Found ${userList.users.length} users:`);
    
    userList.users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email || 'No email'} (${user.uid})`);
      console.log(`   Display Name: ${user.displayName || 'N/A'}`);
      console.log(`   Email Verified: ${user.emailVerified}`);
      console.log(`   Created: ${user.metadata.creationTime}`);
      console.log(`   Last Sign In: ${user.metadata.lastSignInTime || 'Never'}`);
      console.log(`   Custom Claims: ${JSON.stringify(user.customClaims || {})}`);
      console.log('---');
    });
    
    console.log('🎉 Firebase connection test completed successfully!');
    
  } catch (error) {
    console.error('❌ Firebase connection test failed:', error.message);
    process.exit(1);
  }
}

testFirebaseConnection();