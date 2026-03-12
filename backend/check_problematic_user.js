const mongoose = require('mongoose');
const User = require('./src/models/User');
require('dotenv').config();

async function checkUser() {
  try {
    if (!process.env.MONGODB_URI) {
      console.error('MONGODB_URI not found in environment variables');
      process.exit(1);
    }
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    const user = await User.findOne({ email: 'mucyo@gmail.com' });
    if (user) {
      console.log('--- USER DATA ---');
      console.log('Email:', user.email);
      console.log('Firebase UID:', user.firebaseUid);
      console.log('Device ID:', user.deviceId);
      console.log('Role:', user.role);
      console.log('Provider:', user.provider);
      console.log('Is Active:', user.isActive);
    } else {
      console.log('User not found');
    }
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

checkUser();
