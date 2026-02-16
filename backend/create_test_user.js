const mongoose = require('mongoose');
const User = require('./src/models/User');
require('dotenv').config();

async function createTestUser() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    // Check if test user already exists
    const existingUser = await User.findOne({ email: 'teststudent@example.com' });
    if (existingUser) {
      console.log('Test user already exists:', existingUser.email);
      await mongoose.connection.close();
      return;
    }
    
    // Create test user
    const testUser = await User.create({
      fullName: 'Test Student',
      email: 'teststudent@example.com',
      password: 'password123',
      role: 'student'
    });
    
    console.log('Created test user:', testUser.email);
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

createTestUser();