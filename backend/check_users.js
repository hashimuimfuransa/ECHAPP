const mongoose = require('mongoose');
require('./src/config/database');

const User = require('./src/models/User');

async function checkUsers() {
  try {
    console.log('=== Checking Users in Database ===');
    
    const users = await User.find({}).select('email fullName role');
    
    console.log('Total users found:', users.length);
    
    if (users.length === 0) {
      console.log('No users found in database');
    } else {
      users.forEach((user, index) => {
        console.log(`\n--- User ${index + 1} ---`);
        console.log('Email:', user.email);
        console.log('Full Name:', user.fullName);
        console.log('Role:', user.role);
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error checking users:', error);
    process.exit(1);
  }
}

checkUsers();