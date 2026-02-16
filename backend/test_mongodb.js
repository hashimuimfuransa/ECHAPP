const mongoose = require('mongoose');
const User = require('./src/models/User');

async function testMongoDBConnection() {
  try {
    console.log('=== Testing MongoDB Connection ===\n');
    
    // Test direct MongoDB query
    console.log('1. Testing direct MongoDB query...');
    try {
      const users = await User.find({}).limit(5);
      console.log(`✅ Successfully queried MongoDB - found ${users.length} users`);
      
      if (users.length > 0) {
        console.log('First few users:');
        users.forEach((user, index) => {
          console.log(`  ${index + 1}. ${user.email} (${user.provider || 'no provider'}) - ${user.role}`);
        });
      }
    } catch (error) {
      console.log('❌ Failed to query MongoDB directly');
      console.log('Error:', error.message);
      return;
    }
    
    // Test Firebase users specifically
    console.log('\n2. Testing Firebase users query...');
    try {
      const firebaseUsers = await User.find({ firebaseUid: { $exists: true } });
      console.log(`✅ Found ${firebaseUsers.length} Firebase users in MongoDB`);
      
      if (firebaseUsers.length > 0) {
        console.log('Firebase users:');
        firebaseUsers.forEach((user, index) => {
          console.log(`  ${index + 1}. ${user.email} - UID: ${user.firebaseUid} - Role: ${user.role}`);
        });
      } else {
        console.log('⚠️ No Firebase users found in MongoDB');
      }
    } catch (error) {
      console.log('❌ Failed to query Firebase users');
      console.log('Error:', error.message);
    }
    
    console.log('\n=== Test Complete ===');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Error stack:', error.stack);
  } finally {
    // Close the connection
    await mongoose.connection.close();
  }
}

// Run the test
testMongoDBConnection();