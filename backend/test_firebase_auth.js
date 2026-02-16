const admin = require('./src/config/firebase');
const User = require('./src/models/User');

async function testFirebaseAuth() {
  try {
    console.log('=== Firebase Authentication Test ===\n');
    
    // Test 1: Check Firebase Admin SDK initialization
    console.log('1. Testing Firebase Admin SDK initialization...');
    if (admin.apps.length > 0) {
      console.log('✅ Firebase Admin SDK is initialized');
    } else {
      console.log('❌ Firebase Admin SDK is NOT initialized');
      return;
    }
    
    // Test 2: Try to verify a sample token (this will fail but shows the flow)
    console.log('\n2. Testing token verification flow...');
    const sampleToken = 'invalid-token-for-testing';
    
    try {
      const decodedToken = await admin.auth().verifyIdToken(sampleToken);
      console.log('✅ Token verification successful');
      console.log('Decoded token:', decodedToken);
    } catch (error) {
      console.log('❌ Token verification failed (expected for invalid token)');
      console.log('Error:', error.message);
    }
    
    // Test 3: Check if we can list users in Firebase Auth
    console.log('\n3. Checking Firebase Auth users...');
    try {
      const userList = await admin.auth().listUsers();
      console.log(`✅ Found ${userList.users.length} users in Firebase Auth`);
      
      if (userList.users.length > 0) {
        console.log('First 3 users:');
        userList.users.slice(0, 3).forEach((user, index) => {
          console.log(`  ${index + 1}. Email: ${user.email}, UID: ${user.uid}, Created: ${user.metadata?.creationTime}`);
        });
      }
    } catch (error) {
      console.log('❌ Failed to list Firebase Auth users');
      console.log('Error:', error.message);
    }
    
    // Test 4: Check MongoDB users with Firebase UIDs
    console.log('\n4. Checking MongoDB users with Firebase UIDs...');
    try {
      const firebaseUsers = await User.find({ firebaseUid: { $exists: true } });
      console.log(`✅ Found ${firebaseUsers.length} users with Firebase UIDs in MongoDB`);
      
      if (firebaseUsers.length > 0) {
        console.log('First 3 Firebase users in MongoDB:');
        firebaseUsers.slice(0, 3).forEach((user, index) => {
          console.log(`  ${index + 1}. Email: ${user.email}, Firebase UID: ${user.firebaseUid}, Role: ${user.role}`);
        });
      } else {
        console.log('⚠️ No Firebase users found in MongoDB');
      }
    } catch (error) {
      console.log('❌ Failed to query MongoDB users');
      console.log('Error:', error.message);
    }
    
    // Test 5: Check all users in MongoDB
    console.log('\n5. Checking all users in MongoDB...');
    try {
      const allUsers = await User.find({}, 'email fullName role provider firebaseUid');
      console.log(`✅ Found ${allUsers.length} total users in MongoDB`);
      
      console.log('User breakdown by provider:');
      const providerStats = {};
      allUsers.forEach(user => {
        const provider = user.provider || 'unknown';
        providerStats[provider] = (providerStats[provider] || 0) + 1;
      });
      
      Object.entries(providerStats).forEach(([provider, count]) => {
        console.log(`  ${provider}: ${count} users`);
      });
      
      if (allUsers.length > 0) {
        console.log('\nFirst 5 users:');
        allUsers.slice(0, 5).forEach((user, index) => {
          console.log(`  ${index + 1}. ${user.email} (${user.provider || 'no provider'}) - ${user.role}`);
        });
      }
    } catch (error) {
      console.log('❌ Failed to query all MongoDB users');
      console.log('Error:', error.message);
    }
    
    console.log('\n=== Test Complete ===');
    
  } catch (error) {
    console.error('❌ Test failed with error:', error);
    console.error('Error stack:', error.stack);
  }
}

// Run the test
testFirebaseAuth();