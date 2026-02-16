const connectDB = require('./src/config/database');
const User = require('./src/models/User');
const admin = require('./src/config/firebase');

async function fixUserNames() {
  try {
    console.log('=== Fixing User Names ===\n');
    
    // Connect to database
    await connectDB();
    console.log('✅ Database connected');
    
    // Find users with "Firebase User" name
    const firebaseUsers = await User.find({ 
      fullName: 'Firebase User',
      firebaseUid: { $exists: true }
    });
    
    console.log(`Found ${firebaseUsers.length} users with 'Firebase User' name`);
    
    if (firebaseUsers.length === 0) {
      console.log('✅ No users need name fixing');
      return;
    }
    
    console.log('\nUsers to fix:');
    firebaseUsers.forEach(user => {
      console.log(`- ${user.email} (${user.firebaseUid})`);
    });
    
    console.log('\nFixing names...\n');
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const user of firebaseUsers) {
      try {
        console.log(`Fixing user: ${user.email}`);
        
        // Get user's display name from Firebase Auth
        const firebaseUser = await admin.auth().getUser(user.firebaseUid);
        const displayName = firebaseUser.displayName || firebaseUser.email.split('@')[0] || 'User';
        
        console.log(`  Firebase display name: ${firebaseUser.displayName || 'null'}`);
        console.log(`  Derived name: ${displayName}`);
        
        // Update user in MongoDB
        user.fullName = displayName;
        await user.save();
        
        console.log(`  ✅ Updated to: ${displayName}`);
        successCount++;
        
      } catch (error) {
        console.log(`  ❌ Failed to fix user ${user.email}: ${error.message}`);
        errorCount++;
      }
    }
    
    console.log(`\n=== Fix Complete ===`);
    console.log(`✅ Successfully fixed: ${successCount} users`);
    console.log(`❌ Failed to fix: ${errorCount} users`);
    
  } catch (error) {
    console.error('❌ Fix failed:', error.message);
    console.error('Error stack:', error.stack);
  } finally {
    // Close the connection
    process.exit(0);
  }
}

// Run the fix
fixUserNames();