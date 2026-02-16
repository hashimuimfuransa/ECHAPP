const admin = require('firebase-admin');
const connectDB = require('./src/config/database');
const User = require('./src/models/User');

// Initialize Firebase Admin
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

async function debugFirebaseRegistration() {
  try {
    console.log('=== Firebase Registration Debug ===\n');
    
    // Connect to database
    await connectDB();
    console.log('✅ Database connected');
    
    // Check the problematic user
    const user = await User.findOne({ email: 'dieudonnetuy250@gmail.com' });
    if (user) {
      console.log('Found user in database:');
      console.log('- Email:', user.email);
      console.log('- Full Name:', user.fullName);
      console.log('- Firebase UID:', user.firebaseUid);
      console.log('- Provider:', user.provider);
    } else {
      console.log('User not found in database');
      return;
    }
    
    // Check Firebase Auth user
    if (user.firebaseUid) {
      try {
        const firebaseUser = await admin.auth().getUser(user.firebaseUid);
        console.log('\nFirebase Auth user details:');
        console.log('- UID:', firebaseUser.uid);
        console.log('- Email:', firebaseUser.email);
        console.log('- Display Name:', firebaseUser.displayName);
        console.log('- Email Verified:', firebaseUser.emailVerified);
        console.log('- Creation Time:', firebaseUser.metadata?.creationTime);
        
        // Try to update the display name
        console.log('\nAttempting to update display name...');
        await admin.auth().updateUser(user.firebaseUid, {
          displayName: 'Dieudonne Tuyizere'
        });
        console.log('✅ Display name updated in Firebase Auth');
        
        // Reload and check again
        const updatedFirebaseUser = await admin.auth().getUser(user.firebaseUid);
        console.log('\nAfter update:');
        console.log('- Display Name:', updatedFirebaseUser.displayName);
        
        // Update MongoDB user
        user.fullName = updatedFirebaseUser.displayName || 'Dieudonne Tuyizere';
        await user.save();
        console.log('✅ User name updated in MongoDB:', user.fullName);
        
      } catch (firebaseError) {
        console.log('❌ Firebase Auth error:', firebaseError.message);
      }
    }
    
    console.log('\n=== Debug Complete ===');
    
  } catch (error) {
    console.error('❌ Debug failed:', error.message);
    console.error('Error stack:', error.stack);
  } finally {
    process.exit(0);
  }
}

// Run the debug
debugFirebaseRegistration();