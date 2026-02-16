const dotenv = require('dotenv');
const mongoose = require('mongoose');
const User = require('./src/models/User');
const { generateToken, generateRefreshToken } = require('./src/utils/jwt.utils');

dotenv.config();

async function getAdminToken() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    // Find admin user
    const adminUser = await User.findOne({ email: 'tuyizeredieudonne250@gmail.com', role: 'admin' });
    
    if (!adminUser) {
      console.log('Admin user not found');
      process.exit(1);
    }
    
    // Generate token
    const token = generateToken({ id: adminUser._id });
    const refreshToken = generateRefreshToken({ id: adminUser._id });
    
    console.log('Admin token generated:');
    console.log('User ID:', adminUser._id);
    console.log('Email:', adminUser.email);
    console.log('Token:', token);
    console.log('Refresh Token:', refreshToken);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

getAdminToken();