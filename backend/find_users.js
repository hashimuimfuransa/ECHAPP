const mongoose = require('mongoose');
const User = require('./src/models/User');
require('dotenv').config();

async function findUsers() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    const users = await User.find({ role: 'student' }).limit(3);
    console.log('Student users:');
    users.forEach(u => {
      console.log(`${u.email}: ${u.name}`);
    });
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

findUsers();