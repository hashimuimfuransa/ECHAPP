const admin = require('firebase-admin');
const User = require('./src/models/User');
const bcrypt = require('bcryptjs');

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

async function migrateUsersToFirebase() {
  try {
    console.log('=== Migrating Users to Firebase Authentication ===\n');
    
    // Find all users without firebaseUid
    const usersWithoutFirebase = await User.find({ 
      firebaseUid: { $exists: false },
      provider: { $ne: 'firebase' }
    });
    
    console.log(`Found ${usersWithoutFirebase.length} users without Firebase authentication`);
    
    if (usersWithoutFirebase.length === 0) {
      console.log('✅ No users need migration');
      return;
    }
    
    console.log('\nUsers to migrate:');
    usersWithoutFirebase.forEach((user, index) => {
      console.log(`  ${index + 1}. ${user.email} (${user.fullName}) - ${user.role}`);
    });
    
    console.log('\nStarting migration...\n');
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const user of usersWithoutFirebase) {
      try {
        console.log(`Migrating user: ${user.email}`);
        
        // Create user in Firebase Auth
        const firebaseUser = await admin.auth().createUser({
          email: user.email,
          emailVerified: user.isVerified || false,
          displayName: user.fullName,
          password: 'TempPassword123!', // Temporary password
          disabled: !user.isActive
        });
        
        console.log(`✅ Created Firebase user with UID: ${firebaseUser.uid}`);
        
        // Update MongoDB user with firebaseUid
        user.firebaseUid = firebaseUser.uid;
        user.provider = 'firebase';
        user.password = undefined; // Remove password since we're using Firebase Auth
        await user.save();
        
        console.log(`✅ Updated MongoDB user with Firebase UID`);
        successCount++;
        
      } catch (error) {
        console.log(`❌ Failed to migrate user ${user.email}: ${error.message}`);
        errorCount++;
      }
      
      // Add small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log(`\n=== Migration Complete ===`);
    console.log(`✅ Successfully migrated: ${successCount} users`);
    console.log(`❌ Failed to migrate: ${errorCount} users`);
    console.log(`📊 Total processed: ${usersWithoutFirebase.length} users`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error('Error stack:', error.stack);
  } finally {
    // Close MongoDB connection
    process.exit(0);
  }
}

// Run the migration
migrateUsersToFirebase();