const connectDB = require('./src/config/database');
const User = require('./src/models/User');

async function checkUsers() {
  try {
    console.log('=== Checking Users ===\n');
    
    // Connect to database
    await connectDB();
    console.log('✅ Database connected');
    
    // Find users without Firebase UID
    const usersWithoutFirebase = await User.find({ 
      firebaseUid: { $exists: false }
    });
    
    console.log(`Users without Firebase UID: ${usersWithoutFirebase.length}`);
    if (usersWithoutFirebase.length > 0) {
      usersWithoutFirebase.forEach(user => {
        console.log(`- ${user.email} (${user.provider || 'no provider'}) - ${user.role}`);
      });
    }
    
    // Find users with Firebase UID
    const usersWithFirebase = await User.find({ 
      firebaseUid: { $exists: true }
    });
    
    console.log(`\nUsers with Firebase UID: ${usersWithFirebase.length}`);
    if (usersWithFirebase.length > 0) {
      usersWithFirebase.forEach(user => {
        console.log(`- ${user.email} (${user.firebaseUid}) - ${user.role}`);
      });
    }
    
    console.log('\n=== Check Complete ===');
    
  } catch (error) {
    console.error('❌ Check failed:', error.message);
    console.error('Error stack:', error.stack);
  } finally {
    // Close the connection
    process.exit(0);
  }
}

// Run the check
checkUsers();