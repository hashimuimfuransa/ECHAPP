const mongoose = require('mongoose');
require('dotenv').config({ path: '../.env' });

// Import User model
const User = require('../src/models/User');

async function updateUserRole() {
  try {
    // Connect to MongoDB
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB successfully!');

    const userEmail = 'tuyizeredox@gmail.com';
    
    // Find the user by email
    const user = await User.findOne({ email: userEmail });
    
    if (!user) {
      console.log(`❌ User with email ${userEmail} not found`);
      process.exit(1);
    }

    console.log('Current user details:');
    console.log(`  ID: ${user._id}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  Current Role: ${user.role}`);
    console.log(`  Full Name: ${user.fullName}`);
    console.log(`  Created At: ${user.createdAt}`);

    // Check if user is already admin
    if (user.role === 'admin') {
      console.log('✅ User is already an admin');
      process.exit(0);
    }

    // Update user role to admin
    user.role = 'admin';
    await user.save();

    console.log('✅ User role updated successfully!');
    console.log('Updated user details:');
    console.log(`  ID: ${user._id}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  New Role: ${user.role}`);
    console.log(`  Full Name: ${user.fullName}`);

  } catch (error) {
    console.error('❌ Error updating user role:', error.message);
    process.exit(1);
  } finally {
    // Close database connection
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

// Run the script
updateUserRole();
