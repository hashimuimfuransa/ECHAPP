const admin = require('firebase-admin');

// Load service account key
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin SDK with service account
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

async function updateUserRole() {
  try {
    console.log('🔍 Looking for user: tuyizeredox@gmail.com');
    
    // List all users to find the target user
    const userList = await admin.auth().listUsers();
    const targetUser = userList.users.find(user => user.email === 'tuyizeredox@gmail.com');
    
    if (!targetUser) {
      console.log('❌ User not found in Firebase Authentication');
      console.log('Available users:');
      userList.users.forEach(user => {
        console.log(`  - ${user.email || 'No email'} (${user.uid})`);
      });
      process.exit(1);
    }
    
    console.log('✅ User found!');
    console.log(`  UID: ${targetUser.uid}`);
    console.log(`  Email: ${targetUser.email}`);
    console.log(`  Display Name: ${targetUser.displayName || 'N/A'}`);
    console.log(`  Current Custom Claims:`, targetUser.customClaims || 'None');
    
    // Set custom claims to make user admin
    await admin.auth().setCustomUserClaims(targetUser.uid, {
      role: 'admin'
    });
    
    console.log('\n✅ Successfully updated user role to ADMIN!');
    console.log('New custom claims:', { role: 'admin' });
    
    // Verify the update
    const updatedUser = await admin.auth().getUser(targetUser.uid);
    console.log('\nVerification:');
    console.log(`  Role claim: ${updatedUser.customClaims?.role || 'Not set'}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    
    if (error.code === 'auth/insufficient-permission') {
      console.log('\n⚠️  Insufficient permissions to set custom claims.');
      console.log('Possible solutions:');
      console.log('1. You need a service account key file');
      console.log('2. Or run this with proper Firebase Admin credentials');
      console.log('3. Or manually update via Firebase Console with proper permissions');
    }
    
    process.exit(1);
  }
}

// Run the script
updateUserRole();
