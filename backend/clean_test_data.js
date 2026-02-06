require('dotenv').config();
const mongoose = require('mongoose');

async function cleanTestData() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    const User = require('./src/models/User');
    
    // Find the test user
    const testUser = await User.findOne({ email: 'admin@test.com' });
    
    if (testUser) {
      console.log('Found test user:');
      console.log(`- Name: ${testUser.fullName}`);
      console.log(`- Email: ${testUser.email}`);
      console.log(`- Role: ${testUser.role}`);
      console.log(`- Created: ${testUser.createdAt}`);
      
      // Ask if user wants to delete this test user
      console.log('\nThis appears to be test data. Would you like to delete it? (y/N)');
      process.stdin.setEncoding('utf8');
      
      process.stdin.on('readable', () => {
        const chunk = process.stdin.read();
        if (chunk !== null) {
          const answer = chunk.trim().toLowerCase();
          if (answer === 'y' || answer === 'yes') {
            User.deleteOne({ email: 'admin@test.com' })
              .then(() => {
                console.log('Test user deleted successfully');
                return mongoose.connection.close();
              })
              .catch(err => {
                console.error('Error deleting user:', err.message);
                return mongoose.connection.close();
              });
          } else {
            console.log('Keeping the test user');
            mongoose.connection.close();
          }
        }
      });
    } else {
      console.log('No test user found with email admin@test.com');
      await mongoose.connection.close();
    }
    
  } catch (error) {
    console.error('Error:', error.message);
    await mongoose.connection.close();
  }
}

cleanTestData();