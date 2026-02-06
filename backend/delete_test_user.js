require('dotenv').config();
const mongoose = require('mongoose');

async function deleteTestUser() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    const User = require('./src/models/User');
    const result = await User.deleteOne({ email: 'admin@test.com' });
    console.log(`Deleted ${result.deletedCount} test user(s)`);
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

deleteTestUser();