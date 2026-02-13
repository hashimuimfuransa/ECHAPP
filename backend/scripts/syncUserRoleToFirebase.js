const admin = require('firebase-admin');
const mongoose = require('mongoose');
const User = require('../src/models/User');
require('dotenv').config();

// Load service account key
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

async function syncUserRoleToFirebase() {
  try {
    console.log('🔄 Starting user role synchronization from MongoDB to Firebase...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // User email to sync
    const userEmail = 'tuyizeredieudonne250@gmail.com';
    
    // Find user in MongoDB
    const user = await User.findOne({ email: userEmail });
    
    if (!user) {
      console.log(`❌ User with email ${userEmail} not found in MongoDB`);
      process.exit(1);
    }
    
    console.log('✅ User found in MongoDB:');
    console.log(`  ID: ${user._id}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  MongoDB Role: ${user.role}`);
    console.log(`  Firebase UID: ${user.firebaseUid || 'Not set'}`);
    console.log(`  Full Name: ${user.fullName}`);
    
    // Check if user has Firebase UID
    if (!user.firebaseUid) {
      console.log('❌ User does not have a Firebase UID. Cannot sync to Firebase.');
      console.log('Please ensure the user has signed in with Firebase at least once.');
      process.exit(1);
    }
    
    // Get user from Firebase Auth
    let firebaseUser;
    try {
      firebaseUser = await admin.auth().getUser(user.firebaseUid);
      console.log('✅ User found in Firebase Authentication');
    } catch (error) {
      console.log(`❌ User with UID ${user.firebaseUid} not found in Firebase Authentication`);
      console.log('Error:', error.message);
      process.exit(1);
    }
    
    console.log('Current Firebase user details:');
    console.log(`  UID: ${firebaseUser.uid}`);
    console.log(`  Email: ${firebaseUser.email}`);
    console.log(`  Display Name: ${firebaseUser.displayName || 'N/A'}`);
    console.log(`  Current Custom Claims:`, firebaseUser.customClaims || 'None');
    
    // Check if role is already synced
    const currentFirebaseRole = firebaseUser.customClaims?.role || 'student';
    if (currentFirebaseRole === user.role) {
      console.log(`✅ Role is already synchronized (${user.role}). No update needed.`);
      process.exit(0);
    }
    
    console.log(`\n🔄 Syncing role from MongoDB (${user.role}) to Firebase (${currentFirebaseRole})...`);
    
    // Update Firebase custom claims
    await admin.auth().setCustomUserClaims(user.firebaseUid, {
      role: user.role
    });
    
    console.log('✅ Successfully updated Firebase custom claims!');
    console.log(`New role in Firebase: ${user.role}`);
    
    // Verify the update
    const updatedFirebaseUser = await admin.auth().getUser(user.firebaseUid);
    console.log('\n🔍 Verification:');
    console.log(`  MongoDB Role: ${user.role}`);
    console.log(`  Firebase Role Claim: ${updatedFirebaseUser.customClaims?.role || 'Not set'}`);
    console.log(`  Sync Status: ${user.role === updatedFirebaseUser.customClaims?.role ? '✅ SYNCED' : '❌ NOT SYNCED'}`);
    
    console.log('\n🎉 Role synchronization completed successfully!');
    
  } catch (error) {
    console.error('❌ Error during synchronization:', error.message);
    
    if (error.code === 'auth/insufficient-permission') {
      console.log('\n⚠️  Insufficient permissions to set custom claims.');
      console.log('Possible solutions:');
      console.log('1. Ensure serviceAccountKey.json has proper permissions');
      console.log('2. The service account needs "Firebase Authentication Admin" role');
      console.log('3. Or manually update via Firebase Console');
    }
    
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run the sync
syncUserRoleToFirebase();
