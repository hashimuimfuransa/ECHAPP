const admin = require('firebase-admin');
const mongoose = require('mongoose');
const User = require('./src/models/User');
require('dotenv').config();

// Load service account key
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch(err => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

async function syncExistingUsers() {
  try {
    console.log('🔄 Starting manual user synchronization...');
    
    // Get all users from Firebase
    const userList = await admin.auth().listUsers();
    console.log(`📋 Found ${userList.users.length} users in Firebase`);
    
    let createdCount = 0;
    let updatedCount = 0;
    let errorCount = 0;
    
    // Process each user
    for (const firebaseUser of userList.users) {
      try {
        // Skip admin users
        if (firebaseUser.customClaims?.role === 'admin') {
          console.log(`⏭️ Skipping admin user: ${firebaseUser.email}`);
          continue;
        }
        
        // Check if user already exists in MongoDB
        let existingUser = await User.findOne({ firebaseUid: firebaseUser.uid });
        
        const userData = {
          firebaseUid: firebaseUser.uid,
          fullName: firebaseUser.displayName || 'Unknown User',
          email: firebaseUser.email || 'no-email@example.com',
          phone: firebaseUser.phoneNumber,
          avatar: firebaseUser.photoURL,
          isVerified: firebaseUser.emailVerified,
          provider: firebaseUser.providerData[0]?.providerId || 'email',
          role: firebaseUser.customClaims?.role || 'student',
          isActive: !firebaseUser.disabled
        };
        
        if (existingUser) {
          // Update existing user
          Object.assign(existingUser, userData);
          await existingUser.save();
          updatedCount++;
          console.log(`✅ Updated user: ${userData.email}`);
        } else {
          // Create new user
          await User.create(userData);
          createdCount++;
          console.log(`➕ Created user: ${userData.email}`);
        }
      } catch (error) {
        errorCount++;
        console.error(`❌ Error processing user ${firebaseUser.email || firebaseUser.uid}:`, error.message);
      }
    }
    
    console.log('\n📊 Sync Summary:');
    console.log(`✅ Created: ${createdCount} users`);
    console.log(`🔄 Updated: ${updatedCount} users`);
    console.log(`❌ Errors: ${errorCount} users`);
    console.log(`📊 Total processed: ${userList.users.length} users`);
    
  } catch (error) {
    console.error('❌ Sync failed:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
    process.exit(0);
  }
}

// Run the sync
syncExistingUsers();