const mongoose = require('mongoose');
const User = require('./src/models/User');

// Connect to database
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/echapp');

const checkUser = async () => {
  try {
    // Check if user exists
    const user = await User.findOne({ firebaseUid: 'PBuqhAFByIdjBmRmb7c8HPWsPan1' });
    
    if (user) {
      console.log('User found:');
      console.log('ID:', user._id);
      console.log('Email:', user.email);
      console.log('Role:', user.role);
      console.log('isActive:', user.isActive);
      console.log('Full user object:', JSON.stringify(user, null, 2));
    } else {
      console.log('User not found in database');
    }
  } catch (error) {
    console.error('Error checking user:', error);
  } finally {
    mongoose.connection.close();
  }
};

checkUser();